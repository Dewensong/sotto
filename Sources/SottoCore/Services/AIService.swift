import Foundation

public enum AiAnalysisMode: String, CaseIterable, Sendable {
    case timeOnly
    case optimizeContent
}

public enum ScriptSpeedTier: String, CaseIterable, Sendable {
    case slow
    case medium
    case fast

    public var charsPerSecond: Double {
        switch self {
        case .slow: return 3.8
        case .medium: return 4.5
        case .fast: return 5.2
        }
    }

    public var label: String {
        switch self {
        case .slow: return "慢速 (3.8字/秒)"
        case .medium: return "中速 (4.5字/秒)"
        case .fast: return "快速 (5.2字/秒)"
        }
    }

    public var shortLabel: String {
        switch self {
        case .slow: return "慢速"
        case .medium: return "中速"
        case .fast: return "快速"
        }
    }
}

public protocol AIService: Sendable {
    func analyzeScript(_ text: String, mode: AiAnalysisMode) async throws -> AiScriptAnalysis
    func extractCleanScript(_ rawText: String) async throws -> String
    func estimateTiming(cleanScript: String, speed: ScriptSpeedTier) async throws -> AiScriptAnalysis
}

public final class DeepSeekService: AIService, @unchecked Sendable {
    private let config: ApiKeyProvider.Config
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private struct ChatRequest: Codable {
        let model: String
        let messages: [Message]
        let temperature: Double
        let stream: Bool

        struct Message: Codable {
            let role: String
            let content: String
        }
    }

    private struct ChatResponse: Codable {
        let choices: [Choice]

        struct Choice: Codable {
            let message: Message

            struct Message: Codable {
                let role: String
                let content: String
            }
        }
    }

    private struct AnalysisOutput: Codable {
        let segments: [SegmentOutput]
        let total_duration: Double?
        let summary: String?

        struct SegmentOutput: Codable {
            let start_seconds: Double?
            let end_seconds: Double?
            let content: String?
            let ai_notes: String?
        }
    }

    private struct CleanScriptOutput: Codable {
        let clean_script: String
    }

    public init(config: ApiKeyProvider.Config) {
        self.config = config
        self.session = URLSession(configuration: .ephemeral)
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    public func analyzeScript(_ text: String, mode: AiAnalysisMode) async throws -> AiScriptAnalysis {
        let systemPrompt = buildSystemPrompt(for: mode)
        let rawJSON = try await performChatRequest(
            systemPrompt: systemPrompt,
            userMessage: text,
            temperature: mode == .timeOnly ? 0.2 : 0.6
        )
        return try parseAnalysisOutput(rawJSON)
    }

    public func extractCleanScript(_ rawText: String) async throws -> String {
        let systemPrompt = buildCleanScriptPrompt()
        let rawJSON = try await performChatRequest(
            systemPrompt: systemPrompt,
            userMessage: rawText,
            temperature: 0.1
        )
        let cleaned = extractJSON(from: rawJSON)
        guard let data = cleaned.data(using: .utf8) else {
            throw NSError(
                domain: "DeepSeekService",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "无法解析模型返回的 JSON"]
            )
        }
        let output = try decoder.decode(CleanScriptOutput.self, from: data)
        return output.clean_script
    }

    public func estimateTiming(cleanScript: String, speed: ScriptSpeedTier) async throws -> AiScriptAnalysis {
        let systemPrompt = buildTimingEstimationPrompt(speed: speed)
        let rawJSON = try await performChatRequest(
            systemPrompt: systemPrompt,
            userMessage: cleanScript,
            temperature: 0.2
        )
        return try parseAnalysisOutput(rawJSON)
    }

    private func performChatRequest(
        systemPrompt: String,
        userMessage: String,
        temperature: Double,
        timeout: TimeInterval = 60
    ) async throws -> String {
        let requestBody = ChatRequest(
            model: config.model,
            messages: [
                .init(role: "system", content: systemPrompt),
                .init(role: "user", content: userMessage)
            ],
            temperature: temperature,
            stream: false
        )

        var urlRequest = URLRequest(url: URL(string: "\(config.baseURL)/chat/completions")!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.timeoutInterval = timeout
        urlRequest.httpBody = try encoder.encode(requestBody)

        let (data, response) = try await session.data(for: urlRequest)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NSError(
                domain: "DeepSeekService",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "API 返回状态码 \(httpResponse.statusCode): \(body.prefix(200))"]
            )
        }

        let chatResponse = try decoder.decode(ChatResponse.self, from: data)
        guard let content = chatResponse.choices.first?.message.content else {
            throw NSError(
                domain: "DeepSeekService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "模型未返回内容"]
            )
        }

        return content
    }

    private func parseAnalysisOutput(_ raw: String) throws -> AiScriptAnalysis {
        let cleaned = extractJSON(from: raw)

        guard let jsonData = cleaned.data(using: .utf8) else {
            throw NSError(
                domain: "DeepSeekService",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "无法解析模型返回的 JSON"]
            )
        }

        let output = try decoder.decode(AnalysisOutput.self, from: jsonData)

        let segments: [AiScriptAnalysis.TimeSegment] = output.segments.enumerated().map { index, seg in
            AiScriptAnalysis.TimeSegment(
                startSeconds: seg.start_seconds ?? Double(index) * 20,
                endSeconds: seg.end_seconds ?? Double(index + 1) * 20,
                content: seg.content ?? "",
                aiNotes: seg.ai_notes
            )
        }

        let totalDuration = output.total_duration ?? (segments.last?.endSeconds ?? 0)

        return AiScriptAnalysis(
            segments: segments,
            totalDuration: totalDuration,
            summary: output.summary
        )
    }

    private func extractJSON(from text: String) -> String {
        if let leading = text.firstIndex(of: "{"),
           let trailing = text.lastIndex(of: "}"),
           leading < trailing {
            return String(text[leading...trailing])
        }
        return text
    }

    private func buildSystemPrompt(for mode: AiAnalysisMode) -> String {
        let base = """
        你是一个专业的视频口播稿分析助手。用户会给你一段口播稿件，稿件可能包含时间标记（如 "0-20秒"、"20-40秒"、"0:00-0:20" 等格式），也可能没有时间标记。

        请分析后返回严格的 JSON 格式（不要包含 markdown 代码块标记）：
        {
          "segments": [
            {"start_seconds": 0, "end_seconds": 20, "content": "段落口播内容", "ai_notes": null}
          ],
          "total_duration": 120,
          "summary": "整体摘要"
        }

        规则：
        - 如果稿件有时间标记，按标记切分时间段
        - 如果没有时间标记，根据内容逻辑自动分段，每段建议 15-30 秒
        - start_seconds 和 end_seconds 必须是数字
        - content 字段保留该时间段的完整口播文字
        """

        if mode == .timeOnly {
            return base + "\n只做时间结构解析，严格保留原始口播文字内容，不要改写、润色或调整任何文字。"
        } else {
            return base + """
            你可以在以下方面优化口播内容：
            - 调整措辞使表达更自然流畅
            - 如果某段内容过长可能导致超时，适当精简
            - 保持原有的语气和风格
            - 保持核心信息和关键表述不变
            """
        }
    }

    // MARK: - Pipeline prompts

    private func buildCleanScriptPrompt() -> String {
        """
        你是一个专业的提词器稿件清洗助手。

        用户会给你一段"原始稿件材料"，其中可能包含以下非口播内容：
        - Markdown 标记（如 # ## ** ` > 等）
        - HTML 标签（如 <br>、<p>）
        - 时间码标记（如 "0:00-0:20"、"00:00"、"0-20秒"）
        - 章节标题、分镜编号（如 "第一章"、"P1"、"Scene 1"、"### 产品介绍"）
        - 导演备注、舞台指示、提示语（如 "(此处停顿)"、"[音效]"、"注意语气"）
        - TODO、注释、括号内的非口播说明
        - 多余的空白和格式字符

        你的任务：
        1. 删除所有非口播内容（章节标题、时间码、Markdown/HTML 标记、导演备注）
        2. 只保留演讲者真正需要说出口的文字，一字不改
        3. 不要改写、润色、缩写或总结任何口语内容
        4. 保留原有的口语化表达、语气词、设问句
        5. 段落之间用一个空行分隔，段内句子用换行分隔
        6. 标点使用中文标点（，。！？——……""）
        7. 不要输出任何解释、前言、后记

        请返回严格的 JSON 格式（不要包含 markdown 代码块标记）：
        {
          "clean_script": "第一句口播稿。\\n第二句口播稿。\\n\\n新段落开始。\\n新段落第二句。"
        }

        规则：
        - clean_script 字段包含完整的清洗后口播稿纯文本
        - 必须保留所有口播文字，一字不改
        - 段落之间用两个 \\n 表示空行
        - 不要输出任何 JSON 以外的内容
        """
    }

    private func buildTimingEstimationPrompt(speed: ScriptSpeedTier) -> String {
        """
        你是一个专业的口播节奏分析师。用户会给你一段已清洗的中文口播稿（纯文本，段落用空行分隔）。

        你需要为每一句话精确估算朗读的起止时间。

        朗读参数：
        - 语速：\(speed.label)
        - 句末停顿（。！？）：额外 +0.3 秒
        - 句中停顿（，；、：）：额外 +0.15 秒
        - 破折号/省略号停顿：额外 +0.2 秒
        - 段落切换（空行）：额外 +0.6 秒
        - 起始时间：0.0 秒

        计算方式：
        1. 以"句"为最小单位切分（以 。！？.!? 为主切分点）
        2. 每句的字符数 N（中文每个字计 1，英文单词按 2 字符近似，阿拉伯数字每个字符计 1，标点不计）
        3. 朗读时长 = N / \(speed.charsPerSecond) + 该句末尾标点对应的停顿 + 句中标点停顿
        4. start_seconds = 上一句的 end_seconds（段首额外 +0.6 秒）
        5. end_seconds = start_seconds + 朗读时长
        6. 累加生成时间，内部保留小数精度避免漂移
        7. 如果某句字数超过 60，在合适逗号处再切一次，使单句不超过约 12 秒

        请返回严格的 JSON 格式（不要包含 markdown 代码块标记）：
        {
          "segments": [
            {"start_seconds": 0.0, "end_seconds": 7.2, "content": "你有没有这种感觉，同样是 AI 工具。", "ai_notes": null},
            {"start_seconds": 7.2, "end_seconds": 15.8, "content": "但到了真正要用的场景里，却总是差那么一点。", "ai_notes": null}
          ],
          "total_duration": 15.8,
          "summary": null
        }

        规则：
        - segments 数组中每个元素对应一句完整的口播句子
        - content 字段保留该句子的完整文字，不要改写、不要合并、不要拆分
        - start_seconds 和 end_seconds 必须是浮点数字
        - total_duration 等于最后一个句子的 end_seconds
        - 不要输出任何 JSON 以外的内容
        """
    }
}
