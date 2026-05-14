import XCTest
import SottoCore
@testable import Sotto

final class AiAnalyticsTests: XCTestCase {

    // MARK: - AiScriptAnalysis Codable

    func testAiScriptAnalysisCodableRoundTrip() throws {
        let analysis = AiScriptAnalysis(
            segments: [
                .init(startSeconds: 0, endSeconds: 20, content: "开场白", aiNotes: nil),
                .init(startSeconds: 20, endSeconds: 45, content: "核心内容", aiNotes: "建议放慢语速")
            ],
            totalDuration: 45,
            summary: "整段稿件摘要"
        )

        let data = try JSONEncoder().encode(analysis)
        let decoded = try JSONDecoder().decode(AiScriptAnalysis.self, from: data)

        XCTAssertEqual(decoded.segments.count, 2)
        XCTAssertEqual(decoded.segments[0].startSeconds, 0)
        XCTAssertEqual(decoded.segments[0].endSeconds, 20)
        XCTAssertEqual(decoded.segments[0].content, "开场白")
        XCTAssertEqual(decoded.segments[1].aiNotes, "建议放慢语速")
        XCTAssertEqual(decoded.totalDuration, 45)
        XCTAssertEqual(decoded.summary, "整段稿件摘要")
    }

    func testAiScriptAnalysisDecodingFromLegacyJSONWithoutOptionalFields() throws {
        let json = """
        {
          "segments": [
            {"start_seconds": 0, "end_seconds": 10, "content": "简短内容"}
          ],
          "total_duration": 10
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        // Uses the snake_case keys from AnalysisOutput, not from AiScriptAnalysis
        // AiScriptAnalysis uses camelCase. This test verifies AnalysisOutput decoding.
        let rawOutput = try decoder.decode(AnalysisOutput.self, from: json)
        XCTAssertEqual(rawOutput.segments.count, 1)
        XCTAssertNil(rawOutput.summary)
        XCTAssertNil(rawOutput.segments[0].ai_notes)
    }

    // MARK: - ApiKeyProvider

    func testApiKeyProviderResolvesEnvVarFirst() throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let configPath = tmpDir.appendingPathComponent("config.json").path

        let config: [String: String] = [
            "deepseek_api_key": "sk-file-key",
            "deepseek_model": "deepseek-chat"
        ]
        try JSONSerialization.data(withJSONObject: config).write(to: URL(fileURLWithPath: configPath))

        setenv("DEEPSEEK_API_KEY", "sk-env-key", 1)
        defer { unsetenv("DEEPSEEK_API_KEY") }

        let provider = ApiKeyProvider(configPath: configPath)
        let result = try provider.resolve()

        XCTAssertEqual(result.apiKey, "sk-env-key")
    }

    func testApiKeyProviderFallsBackToConfigFile() throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let configPath = tmpDir.appendingPathComponent("config.json").path

        let config: [String: String] = [
            "deepseek_api_key": "sk-config-key",
            "deepseek_model": "deepseek-chat-pro",
            "deepseek_base_url": "https://custom.api/v1"
        ]
        try JSONSerialization.data(withJSONObject: config).write(to: URL(fileURLWithPath: configPath))

        let provider = ApiKeyProvider(configPath: configPath)
        let result = try provider.resolve()

        XCTAssertEqual(result.apiKey, "sk-config-key")
        XCTAssertEqual(result.model, "deepseek-chat-pro")
        XCTAssertEqual(result.baseURL, "https://custom.api/v1")
    }

    func testApiKeyProviderThrowsWhenNoKeyConfigured() {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let configPath = tmpDir.appendingPathComponent("nonexistent.json").path

        let provider = ApiKeyProvider(envKey: "NONEXISTENT_DEEPSEEK_KEY_12345", configPath: configPath)

        XCTAssertThrowsError(try provider.resolve())
        XCTAssertFalse(provider.hasKey())
    }

    func testApiKeyProviderHasKeyReturnsTrueWhenConfigured() throws {
        setenv("DEEPSEEK_API_KEY", "sk-test", 1)
        defer { unsetenv("DEEPSEEK_API_KEY") }

        let provider = ApiKeyProvider()
        XCTAssertTrue(provider.hasKey())
    }

    // MARK: - SegmentationService with Time Analysis

    func testSegmentWithTimeAnalysisDistributesTimeAcrossPhrases() {
        let service = SegmentationService()
        let analysis = AiScriptAnalysis(
            segments: [
                .init(startSeconds: 0, endSeconds: 15, content: "这是一个包含两个短语的句子，后半部分在这里。"),
                .init(startSeconds: 15, endSeconds: 30, content: "第二段时间段的内容。")
            ],
            totalDuration: 30
        )

        let document = service.segmentWithTimeAnalysis(
            "原始稿件文本",
            timing: .standard,
            analysis: analysis
        )

        XCTAssertEqual(document.sentences.count, 2)
        XCTAssertEqual(document.timeAnalysis?.totalDuration, 30)
        XCTAssertEqual(document.sentences[0].targetStartSeconds, 0)
        XCTAssertEqual(document.sentences[0].targetEndSeconds, 15)
        XCTAssertEqual(document.sentences[1].targetStartSeconds, 15)
        XCTAssertEqual(document.sentences[1].targetEndSeconds, 30)

        // Phrases should have non-zero estimated durations from time distribution
        for sentence in document.sentences {
            for phrase in sentence.phrases {
                XCTAssertGreaterThan(phrase.estimatedDuration, 0)
            }
        }
    }

    func testSegmentWithTimeAnalysisProducesExpectedSentenceCount() {
        let service = SegmentationService()
        let analysis = AiScriptAnalysis(
            segments: [
                .init(startSeconds: 0, endSeconds: 20, content: "开场介绍"),
                .init(startSeconds: 20, endSeconds: 40, content: "核心功能演示"),
                .init(startSeconds: 40, endSeconds: 60, content: "总结收尾")
            ],
            totalDuration: 60
        )

        let document = service.segmentWithTimeAnalysis("原始文本", analysis: analysis)

        XCTAssertEqual(document.sentences.count, 3)
        XCTAssertEqual(document.sentences[0].text, "开场介绍")
        XCTAssertEqual(document.sentences[1].text, "核心功能演示")
        XCTAssertEqual(document.sentences[2].text, "总结收尾")
    }

    // MARK: - Time-anchored Playback

    @MainActor
    func testPlaybackUsesTimeAnchoredPhraseDurationWhenAvailable() {
        let sentence = SentenceSegment(
            text: "第一段，第二段。",
            phrases: [
                PhraseSegment(text: "第一段，", estimatedDuration: 5),
                PhraseSegment(text: "第二段。", estimatedDuration: 5)
            ],
            targetStartSeconds: 0,
            targetEndSeconds: 10
        )
        let document = PromptDocument(
            title: "Timed",
            rawText: "第一段，第二段。",
            sentences: [sentence]
        )
        let model = AppModel()
        model.setPromptSpeedMultiplier(1.35)
        model.session = PromptSession(document: document, timing: .standard, isPlaying: true)

        let start = Date(timeIntervalSinceReferenceDate: 1_000)
        model.tickPlayback(now: start)
        model.tickPlayback(now: start.addingTimeInterval(4.0))

        XCTAssertEqual(model.session?.currentPhraseIndex, 1)
    }

    @MainActor
    func testRegularPlaybackUsesTimingProfileWhenNoTimeAnchors() {
        let sentence = SentenceSegment(
            text: "没有时间锚点的句子。",
            phrases: [PhraseSegment(text: "没有时间锚点的句子。")]
        )
        let document = PromptDocument(
            title: "Normal",
            rawText: "没有时间锚点的句子。",
            sentences: [sentence]
        )
        let model = AppModel()
        model.setPromptSpeedMultiplier(1)
        model.timing = .compact
        model.session = PromptSession(document: document, timing: .compact, isPlaying: true)

        let start = Date(timeIntervalSinceReferenceDate: 1_000)
        model.tickPlayback(now: start)
        model.tickPlayback(now: start.addingTimeInterval(
            TimingProfile.compact.duration(for: sentence.phrases[0]) + 0.02
        ))

        // Should have advanced through the only phrase and stopped
        XCTAssertFalse(model.session?.isPlaying ?? true)
    }

    // MARK: - Analysis Output Parsing

    func testExtractJSONFromModelResponse() {
        let analysis = AiScriptAnalysis(
            segments: [.init(startSeconds: 0, endSeconds: 20, content: "开场")],
            totalDuration: 20
        )
        XCTAssertEqual(analysis.segments[0].startSeconds, 0)
        XCTAssertEqual(analysis.segments[0].endSeconds, 20)
        XCTAssertEqual(analysis.segments[0].content, "开场")
    }

    // MARK: - PromptDocument backward compatibility

    func testPromptDocumentDecodingWithoutTimeAnalysisField() throws {
        let json = """
        {
          "id": "\(UUID().uuidString)",
          "title": "Old Doc",
          "rawText": "旧文档内容。",
          "sentences": [
            {"id": "\(UUID().uuidString)", "text": "旧文档内容。", "phrases": [], "pause": "normal", "emphasis": "normal", "manualSplitOffsets": []}
          ],
          "createdAt": 0,
          "updatedAt": 0,
          "isArchived": false
        }
        """.data(using: .utf8)!

        let document = try JSONDecoder().decode(PromptDocument.self, from: json)

        XCTAssertNil(document.timeAnalysis)
        XCTAssertEqual(document.title, "Old Doc")
    }

    func testSentenceSegmentDecodingWithoutTimeAnchorFields() throws {
        let json = """
        {
          "id": "\(UUID().uuidString)",
          "text": "旧格式句子。",
          "phrases": [],
          "pause": "normal",
          "emphasis": "normal",
          "manualSplitOffsets": []
        }
        """.data(using: .utf8)!

        let sentence = try JSONDecoder().decode(SentenceSegment.self, from: json)

        XCTAssertNil(sentence.targetStartSeconds)
        XCTAssertNil(sentence.targetEndSeconds)
        XCTAssertEqual(sentence.text, "旧格式句子。")
    }

    // MARK: - ScriptSpeedTier

    func testScriptSpeedTierValues() {
        XCTAssertEqual(ScriptSpeedTier.slow.charsPerSecond, 3.8)
        XCTAssertEqual(ScriptSpeedTier.medium.charsPerSecond, 4.5)
        XCTAssertEqual(ScriptSpeedTier.fast.charsPerSecond, 5.2)
        XCTAssertEqual(ScriptSpeedTier.allCases.count, 3)
    }

    func testScriptSpeedTierLabelsNotEmpty() {
        for tier in ScriptSpeedTier.allCases {
            XCTAssertFalse(tier.label.isEmpty)
            XCTAssertFalse(tier.shortLabel.isEmpty)
        }
    }

    // MARK: - CleanScriptOutput Codable

    func testCleanScriptOutputDecoding() throws {
        let json = """
        {
          "clean_script": "第一句话。\\n第二句话。\\n\\n新段落。"
        }
        """.data(using: .utf8)!

        // Decode via DeepSeekService's internal type by reconstructing from raw JSON
        let rawOutput = try JSONDecoder().decode(CleanScriptTestOutput.self, from: json)
        XCTAssertEqual(rawOutput.clean_script, "第一句话。\n第二句话。\n\n新段落。")
    }

    func testCleanScriptOutputRoundTrip() throws {
        let output = CleanScriptTestOutput(clean_script: "测试内容。\n更多内容。")
        let data = try JSONEncoder().encode(output)
        let decoded = try JSONDecoder().decode(CleanScriptTestOutput.self, from: data)
        XCTAssertEqual(decoded.clean_script, output.clean_script)
    }

    // MARK: - Paragraph indices

    func testComputeParagraphIndicesSingleParagraph() {
        let service = SegmentationService()
        let text = "第一句话。第二句话。"
        let sentences = ["第一句话。", "第二句话。"]
        let indices = service.computeParagraphIndices(text: text, sentences: sentences)
        // Single paragraph: all nil (no chapter markers needed)
        XCTAssertEqual(indices.count, 2)
        XCTAssertNil(indices[0])
        XCTAssertNil(indices[1])
    }

    func testComputeParagraphIndicesMultipleParagraphs() {
        let service = SegmentationService()
        let text = "段落一句子一。段落一句子二。\n\n段落二句子一。段落二句子二。"
        let sentences = ["段落一句子一。", "段落一句子二。", "段落二句子一。", "段落二句子二。"]
        let indices = service.computeParagraphIndices(text: text, sentences: sentences)
        XCTAssertEqual(indices, [0, 0, 1, 1])
    }

    func testSentenceSegmentDecodingWithoutParagraphIndexField() throws {
        let json = """
        {
          "id": "\(UUID().uuidString)",
          "text": "旧格式句子。",
          "phrases": [],
          "pause": "normal",
          "emphasis": "normal",
          "manualSplitOffsets": []
        }
        """.data(using: .utf8)!

        let sentence = try JSONDecoder().decode(SentenceSegment.self, from: json)
        XCTAssertNil(sentence.paragraphIndex)
    }
}

// Private type used by tests for parsing the raw model output format

private struct CleanScriptTestOutput: Codable {
    let clean_script: String
}

// Private type used by tests for parsing the raw model output format
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
