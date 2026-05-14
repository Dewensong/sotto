import AppKit
import Combine
import Foundation
import UniformTypeIdentifiers
import SottoCore

@MainActor
final class AppModel: ObservableObject {
    enum Phase {
        case home
        case preparing
        case documentManager
        case editor
    }

    enum DocumentFilter: String, CaseIterable {
        case all
        case unarchived
        case archived
    }

    @Published var phase: Phase = .home
    @Published var inputText: String = ""
    @Published var currentDocument: PromptDocument?
    @Published var selectedSentenceID: SentenceSegment.ID?
    @Published var timing: TimingProfile = .standard
    @Published var session: PromptSession?
    @Published var phraseProgress: Double = 0
    @Published var settings = TeleprompterSettings()
    @Published var recentDocuments: [PromptDocument] = []
    @Published var documentFilter: DocumentFilter = .unarchived
    @Published var showRhythmReadyAnnouncement = false
    @Published var showSettingsPanel = false
    @Published var showSentencePicker = false
    @Published var settingsRotation: Double = 0
    @Published var microphoneLevel: Double = 0
    @Published private(set) var microphoneIsListening = false
    @Published private(set) var microphonePermissionDenied = false
    @Published var toast: SottoToastMessage?
    @Published private(set) var playbackElapsedDisplay = "00:00"
    @Published private(set) var isAnalyzing = false
    @Published var showAiOptions = false
    @Published var pipelineProgressLabel = ""
    @Published var pipelineSpeedTier: ScriptSpeedTier = .medium
    @Published private(set) var bookmarkedSentenceIndex: Int?
    @Published private(set) var canUndoInput = false
    @Published var apiKeyInput: String = ""
    @Published private(set) var hasApiKey: Bool = false
    @Published private(set) var apiTestState: ApiTestState = .idle
    @Published private(set) var countdownPhase: Int? = nil

    enum ApiTestState: Equatable {
        case idle
        case testing
        case success
        case failed(String)
    }

    private let segmentationService = SegmentationService()
    private let store: PromptDocumentStore
    private let teleprompterWindowController = TeleprompterWindowController()
    private let audioLevelMonitor = AudioLevelMonitor()
    private let apiKeyProvider = ApiKeyProvider()
    private var lastPlaybackTick: Date?
    private var playbackSegmentStart: Date?
    private var playbackPausedElapsed: TimeInterval = 0
    private var voiceGateQuietFrameCount: Int = 0
    private var toastDismissTask: Task<Void, Never>?
    private var analyzeTask: Task<Void, Never>?
    private var pipelineTask: Task<Void, Never>?
    private var apiTestTask: Task<Void, Never>?
    private var countdownTask: Task<Void, Never>?
    private var inputHistory: [String] = []
    private var cancellables: Set<AnyCancellable> = []

    private static let defaultDocumentTitle = "新的提词稿"

    private let promptFontSizeRange: ClosedRange<Double> = 24...48
    private let promptOpacityRange: ClosedRange<Double> = 0.55...1
    private let promptWidthRange: ClosedRange<Double> = 620...1180
    private let promptHeightRange: ClosedRange<Double> = 380...720
    private let promptBrightnessRange: ClosedRange<Double> = 0.65...1.2
    private let promptSpeedMultiplierRange: ClosedRange<Double> = 0.55...1.65
    private let voiceActivationThresholdRange: ClosedRange<Double> = 0.08...0.50
    private let lineSpacingRange: ClosedRange<Double> = 0.06...0.42
    private let trackingRange: ClosedRange<Double> = 0...6

    init(store: PromptDocumentStore = PromptDocumentStore()) {
        self.store = store
        audioLevelMonitor.$level
            .receive(on: RunLoop.main)
            .assign(to: &$microphoneLevel)
        audioLevelMonitor.$isListening
            .receive(on: RunLoop.main)
            .assign(to: &$microphoneIsListening)
        audioLevelMonitor.$permissionStatus
            .receive(on: RunLoop.main)
            .sink { [weak self] status in
                if status == .denied || status == .restricted {
                    self?.microphonePermissionDenied = true
                } else {
                    self?.microphonePermissionDenied = false
                }
            }
            .store(in: &cancellables)
        loadRecentDocuments()
        refreshApiKeyStatus()
    }

    var selectedSentenceIndex: Int? {
        guard let selectedSentenceID, let currentDocument else { return nil }
        return currentDocument.sentences.firstIndex { $0.id == selectedSentenceID }
    }

    var selectedSentence: SentenceSegment? {
        guard let index = selectedSentenceIndex else { return currentDocument?.sentences.first }
        return currentDocument?.sentences[index]
    }

    var filteredDocuments: [PromptDocument] {
        switch documentFilter {
        case .all: recentDocuments
        case .unarchived: recentDocuments.filter { !$0.isArchived }
        case .archived: recentDocuments.filter { $0.isArchived }
        }
    }

    func saveInputToLibrary() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var document = segmentationService.segment(trimmed, title: Self.defaultDocumentTitle, timing: timing)
        document.title = generatedTitle(from: trimmed)
        do {
            try store.save(document)
            loadRecentDocuments()
            triggerSaveToast("已保存到全部稿件")
        } catch {
            triggerErrorToast("稿件保存失败")
        }
    }

    func analyzeScript(mode: AiAnalysisMode) {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let config = try? apiKeyProvider.resolve() else {
            triggerErrorToast("未配置 DeepSeek API Key。请在设置面板（齿轮图标）中填入 Key。")
            return
        }

        showAiOptions = false
        isAnalyzing = true
        let service = DeepSeekService(config: config)

        analyzeTask = Task { @MainActor in
            do {
                let analysis = try await service.analyzeScript(trimmed, mode: mode)
                isAnalyzing = false
                applyAnalysis(analysis, mode: mode)
            } catch {
                isAnalyzing = false
                if Task.isCancelled { return }
                triggerErrorToast("AI 分析失败：\(error.localizedDescription)")
            }
        }
    }

    func cancelAnalysis() {
        analyzeTask?.cancel()
        analyzeTask = nil
        isAnalyzing = false
    }

    func processScriptWithAiPipeline(speed: ScriptSpeedTier? = nil) {
        let tier = speed ?? pipelineSpeedTier
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let config = try? apiKeyProvider.resolve() else {
            triggerErrorToast("未配置 DeepSeek API Key。请在设置面板（齿轮图标）中填入 Key。")
            return
        }

        showAiOptions = false
        isAnalyzing = true
        pipelineProgressLabel = "提取纯净稿..."
        let service = DeepSeekService(config: config)

        pipelineTask = Task { @MainActor in
            // Step 1: extract clean script
            let cleanScript: String
            do {
                cleanScript = try await service.extractCleanScript(trimmed)
            } catch {
                isAnalyzing = false
                pipelineProgressLabel = ""
                if Task.isCancelled { return }
                triggerErrorToast("纯净稿提取失败：\(error.localizedDescription)")
                return
            }

            if Task.isCancelled {
                isAnalyzing = false
                pipelineProgressLabel = ""
                return
            }

            pushInputHistory()
            inputText = cleanScript
            pipelineProgressLabel = "估算时间..."

            // Step 2: estimate timing
            let analysis: AiScriptAnalysis
            do {
                analysis = try await service.estimateTiming(cleanScript: cleanScript, speed: tier)
            } catch {
                isAnalyzing = false
                pipelineProgressLabel = ""
                if Task.isCancelled { return }
                triggerErrorToast("时间估算失败，纯净稿已提取到编辑器中。")
                return
            }

            isAnalyzing = false
            pipelineProgressLabel = ""
            applyPipelineResult(cleanScript: cleanScript, analysis: analysis)
        }
    }

    func cancelPipeline() {
        pipelineTask?.cancel()
        pipelineTask = nil
        isAnalyzing = false
        pipelineProgressLabel = ""
    }

    private func applyPipelineResult(cleanScript: String, analysis: AiScriptAnalysis) {
        var document = segmentationService.segmentWithTimeAnalysis(
            cleanScript,
            title: generatedTitle(from: cleanScript),
            timing: timing,
            analysis: analysis
        )
        document.title = generatedTitle(from: document.rawText)

        do {
            try store.save(document)
            loadRecentDocuments()
            triggerSaveToast("AI 分析完成，已保存到全部稿件")
        } catch {
            triggerErrorToast("稿件保存失败")
        }

        open(document, announceRhythmReady: true)
    }

    // MARK: - Bookmarks

    func setBookmark() {
        guard let index = session?.currentSentenceIndex else { return }
        bookmarkedSentenceIndex = index
    }

    func jumpToBookmark() {
        guard let index = bookmarkedSentenceIndex else { return }
        jumpToSentence(at: index)
    }

    func clearBookmark() {
        bookmarkedSentenceIndex = nil
    }

    // MARK: - Input history

    func pushInputHistory() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let last = inputHistory.last, last == trimmed { return }
        inputHistory.append(trimmed)
        if inputHistory.count > 20 { inputHistory.removeFirst() }
        canUndoInput = true
    }

    func undoInputChange() {
        guard let previous = inputHistory.popLast() else { return }
        inputText = previous
        canUndoInput = !inputHistory.isEmpty
    }

    // MARK: - Export

    func exportCurrentDocument() {
        guard let document = currentDocument ?? session?.document else {
            triggerErrorToast("没有可导出的稿件")
            return
        }

        let panel = NSSavePanel()
        panel.title = "导出提词稿"
        panel.message = "选择导出格式和位置"
        panel.allowedContentTypes = [UTType.plainText, UTType(filenameExtension: "md") ?? .plainText]
        panel.nameFieldStringValue = "\(document.title).md"

        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            let isMarkdown = url.pathExtension.lowercased() == "md"
            let content = isMarkdown ? self?.exportMarkdown(document: document) : self?.exportPlainText(document: document)
            guard let content else { return }
            do {
                try content.write(to: url, atomically: true, encoding: .utf8)
                Task { @MainActor in
                    self?.triggerSaveToast("稿件已导出到 \(url.lastPathComponent)")
                }
            } catch {
                Task { @MainActor in
                    self?.triggerErrorToast("导出失败：\(error.localizedDescription)")
                }
            }
        }
    }

    private func exportMarkdown(document: PromptDocument) -> String {
        var output = "# \(document.title)\n\n"

        if let analysis = document.timeAnalysis {
            let totalMin = Int(analysis.totalDuration) / 60
            let totalSec = Int(analysis.totalDuration) % 60
            output += "**全片总时长**: \(String(format: "%d:%02d", totalMin, totalSec))\n\n"
        }

        var currentPara: Int?
        for sentence in document.sentences {
            if let para = sentence.paragraphIndex, para != currentPara {
                currentPara = para
                output += "### 段落 \(para + 1)\n\n"
            }

            if let start = sentence.targetStartSeconds, let end = sentence.targetEndSeconds {
                let startStr = formatSeconds(start)
                let endStr = formatSeconds(end)
                let duration = Int(end - start)
                output += "| \(startStr) | \(endStr) | \(duration)s | \(sentence.text) |\n"
            } else {
                output += "\(sentence.text)\n\n"
            }
        }

        if let analysis = document.timeAnalysis, let summary = analysis.summary {
            output += "\n---\n\n**摘要**: \(summary)\n"
        }

        return output
    }

    private func exportPlainText(document: PromptDocument) -> String {
        var output = document.rawText
        if let analysis = document.timeAnalysis {
            let totalMin = Int(analysis.totalDuration) / 60
            let totalSec = Int(analysis.totalDuration) % 60
            output += "\n\n---\n全片总时长: \(String(format: "%d:%02d", totalMin, totalSec))"
        }
        return output
    }

    private func formatSeconds(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
    }

    func refreshApiKeyStatus() {
        hasApiKey = apiKeyProvider.hasKey()
        if let config = try? apiKeyProvider.resolve() {
            apiKeyInput = config.apiKey
        }
    }

    func saveApiKey() {
        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            triggerErrorToast("API Key 不能为空")
            return
        }
        do {
            try apiKeyProvider.saveConfig(.init(apiKey: trimmed))
            hasApiKey = true
            triggerSaveToast("API Key 已保存")
        } catch {
            triggerErrorToast("API Key 保存失败：\(error.localizedDescription)")
        }
    }

    func testApiConnection() {
        guard let config = try? apiKeyProvider.resolve() else {
            apiTestState = .failed("未配置 Key")
            return
        }

        apiTestTask?.cancel()
        apiTestState = .testing

        apiTestTask = Task { @MainActor in
            do {
                struct TestRequest: Codable {
                    let model: String
                    let messages: [Message]
                    let max_tokens: Int
                    let stream: Bool
                    struct Message: Codable {
                        let role: String
                        let content: String
                    }
                }
                let body = TestRequest(
                    model: config.model,
                    messages: [.init(role: "user", content: "hi")],
                    max_tokens: 5,
                    stream: false
                )
                var urlRequest = URLRequest(url: URL(string: "\(config.baseURL)/chat/completions")!)
                urlRequest.httpMethod = "POST"
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                urlRequest.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
                urlRequest.timeoutInterval = 15
                urlRequest.httpBody = try JSONEncoder().encode(body)

                let (data, response) = try await URLSession.shared.data(for: urlRequest)

                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        apiTestState = .success
                    } else {
                        let body = String(data: data, encoding: .utf8) ?? ""
                        let prefix = String(body.prefix(120))
                        if httpResponse.statusCode == 401 {
                            apiTestState = .failed("Key 无效 (401)")
                        } else if httpResponse.statusCode == 403 {
                            apiTestState = .failed("权限不足 (403)")
                        } else {
                            apiTestState = .failed("\(httpResponse.statusCode): \(prefix)")
                        }
                    }
                } else {
                    apiTestState = .failed("无效响应")
                }
            } catch {
                if Task.isCancelled { return }
                let message = error.localizedDescription
                if message.contains("Internet") || message.contains("offline") || message.contains("connect") {
                    apiTestState = .failed("网络不通")
                } else {
                    apiTestState = .failed(message.prefix(80).description)
                }
            }
        }
    }

    private func applyAnalysis(_ analysis: AiScriptAnalysis, mode: AiAnalysisMode) {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        var document = segmentationService.segmentWithTimeAnalysis(
            trimmed,
            title: generatedTitle(from: trimmed),
            timing: timing,
            analysis: analysis
        )
        document.title = generatedTitle(from: document.rawText)

        do {
            try store.save(document)
            loadRecentDocuments()
            triggerSaveToast("AI 分析完成，已保存到全部稿件")
        } catch {
            triggerErrorToast("稿件保存失败")
        }

        open(document, announceRhythmReady: true)
    }

    func createDocumentFromInput() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var document = segmentationService.segment(trimmed, title: Self.defaultDocumentTitle, timing: timing)
        document.title = generatedTitle(from: trimmed)

        do {
            try store.save(document)
            loadRecentDocuments()
            triggerSaveToast("已保存到全部稿件")
        } catch {
            triggerErrorToast("稿件保存失败")
        }

        phase = .preparing
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(780))
            open(document, announceRhythmReady: true)
        }
    }

    private func triggerSaveToast(_ message: String) {
        toastDismissTask?.cancel()
        toast = SottoToastMessage(text: message, kind: .success)
        toastDismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            toast = nil
        }
    }

    private func triggerErrorToast(_ message: String) {
        toastDismissTask?.cancel()
        toast = SottoToastMessage(text: message, kind: .error)
        toastDismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            toast = nil
        }
    }

    func open(_ document: PromptDocument, announceRhythmReady: Bool = false) {
        currentDocument = document
        selectedSentenceID = document.sentences.first?.id
        session = PromptSession(document: document, timing: timing)
        phraseProgress = 0
        lastPlaybackTick = nil
        phase = .editor
        showRhythmReadyAnnouncement = announceRhythmReady
    }

    func returnHome() {
        teleprompterWindowController.close()
        currentDocument = nil
        session = nil
        selectedSentenceID = nil
        phraseProgress = 0
        lastPlaybackTick = nil
        playbackPausedElapsed = 0
        playbackSegmentStart = nil
        playbackElapsedDisplay = "00:00"
        showRhythmReadyAnnouncement = false
        showSettingsPanel = false
        phase = .home
    }

    func openDocumentManager() {
        teleprompterWindowController.close()
        currentDocument = nil
        session = nil
        selectedSentenceID = nil
        phraseProgress = 0
        lastPlaybackTick = nil
        showRhythmReadyAnnouncement = false
        showSettingsPanel = false
        documentFilter = .unarchived
        loadRecentDocuments()
        phase = .documentManager
    }

    func closeDocumentManager() {
        phase = .home
    }

    func loadRecentDocuments() {
        do {
            recentDocuments = try store.loadRecentDocuments()
        } catch {
            triggerErrorToast("最近稿件读取失败")
        }
    }

    func saveCurrentDocument() {
        guard let currentDocument else { return }
        do {
            try store.save(currentDocument)
            loadRecentDocuments()
        } catch {
            triggerErrorToast("稿件保存失败")
        }
    }

    func removeRecentDocument(_ document: PromptDocument) {
        do {
            try store.remove(id: document.id)
            if currentDocument?.id == document.id {
                currentDocument = nil
                session = nil
                selectedSentenceID = nil
                phase = .home
            }
            loadRecentDocuments()
        } catch {
            triggerErrorToast("最近稿件移除失败")
        }
    }

    func setDocumentFilter(_ filter: DocumentFilter) {
        documentFilter = filter
    }

    func showError(_ message: String) {
        triggerErrorToast(message)
    }

    func toggleArchive(_ document: PromptDocument) {
        var updated = document
        updated.isArchived.toggle()
        updated.updatedAt = Date()
        do {
            try store.save(updated)
            loadRecentDocuments()
        } catch {
            triggerErrorToast("归档操作失败")
        }
    }

    func copyRecentDocumentToInput(_ document: PromptDocument) {
        teleprompterWindowController.close()
        inputText = document.rawText
        currentDocument = nil
        session = nil
        selectedSentenceID = nil
        phraseProgress = 0
        lastPlaybackTick = nil
        showRhythmReadyAnnouncement = false
        phase = .home
    }

    func updateRawText(_ text: String) {
        guard var document = currentDocument else { return }
        document.rawText = text
        document.updatedAt = Date()
        currentDocument = document
        saveCurrentDocument()
    }

    func resegmentCurrentDocument() {
        guard let document = currentDocument else { return }
        var segmented = segmentationService.segment(document.rawText, title: document.title, timing: timing)
        segmented.id = document.id
        segmented.createdAt = document.createdAt
        segmented.updatedAt = Date()
        currentDocument = segmented
        selectedSentenceID = segmented.sentences.first?.id
        session = PromptSession(document: segmented, timing: timing)
        saveCurrentDocument()
    }

    func selectSentence(_ sentence: SentenceSegment) {
        selectedSentenceID = sentence.id
        if session != nil, let index = currentDocument?.sentences.firstIndex(where: { $0.id == sentence.id }) {
            jumpToSentence(at: index)
        }
    }

    func jumpToSentence(at index: Int) {
        guard var session, session.document.sentences.indices.contains(index) else { return }
        session.currentSentenceIndex = index
        session.currentPhraseIndex = 0
        selectedSentenceID = session.currentSentence?.id
        phraseProgress = 0
        lastPlaybackTick = session.isPlaying ? Date() : nil
        self.session = session
    }

    func toggleSplit(in sentence: SentenceSegment, at offset: Int) {
        guard var document = currentDocument,
              let sentenceIndex = document.sentences.firstIndex(where: { $0.id == sentence.id })
        else { return }

        PromptEditingService.toggleSplit(at: offset, in: &document.sentences[sentenceIndex], timing: timing)
        document.updatedAt = Date()
        currentDocument = document
        session = PromptSession(document: document, timing: timing, currentSentenceIndex: sentenceIndex)
        phraseProgress = 0
        lastPlaybackTick = nil
        saveCurrentDocument()
    }

    func updateSelectedSentenceText(_ text: String) {
        guard var document = currentDocument,
              let sentenceIndex = selectedSentenceIndex,
              let updatedSentence = PromptEditingService.updateSentenceText(
                document.sentences[sentenceIndex],
                text: text,
                timing: timing
              )
        else { return }

        document.sentences[sentenceIndex] = updatedSentence
        commitSentenceChanges(document, currentSentenceIndex: sentenceIndex, selectedSentenceID: updatedSentence.id)
    }

    func splitSelectedSentence(at offset: Int) {
        guard var document = currentDocument,
              let sentenceIndex = selectedSentenceIndex,
              let splitSentences = PromptEditingService.splitSentence(
                document.sentences[sentenceIndex],
                at: offset,
                timing: timing
              )
        else { return }

        document.sentences.replaceSubrange(sentenceIndex...sentenceIndex, with: splitSentences)
        commitSentenceChanges(document, currentSentenceIndex: sentenceIndex, selectedSentenceID: splitSentences[0].id)
    }

    func mergeSelectedSentenceWithPrevious() {
        guard var document = currentDocument,
              let sentenceIndex = selectedSentenceIndex,
              sentenceIndex > 0
        else { return }

        let merged = PromptEditingService.mergeSentences(
            document.sentences[sentenceIndex - 1],
            document.sentences[sentenceIndex],
            timing: timing
        )
        document.sentences.replaceSubrange((sentenceIndex - 1)...sentenceIndex, with: [merged])
        commitSentenceChanges(document, currentSentenceIndex: sentenceIndex - 1, selectedSentenceID: merged.id)
    }

    func mergeSelectedSentenceWithNext() {
        guard var document = currentDocument,
              let sentenceIndex = selectedSentenceIndex,
              sentenceIndex < document.sentences.count - 1
        else { return }

        let merged = PromptEditingService.mergeSentences(
            document.sentences[sentenceIndex],
            document.sentences[sentenceIndex + 1],
            timing: timing
        )
        document.sentences.replaceSubrange(sentenceIndex...(sentenceIndex + 1), with: [merged])
        commitSentenceChanges(document, currentSentenceIndex: sentenceIndex, selectedSentenceID: merged.id)
    }

    func setSelectedSentencePause(_ pause: PauseLevel) {
        updateSelectedSentence { sentence in
            sentence.pause = pause
        }
    }

    func setSelectedSentenceEmphasis(_ emphasis: EmphasisLevel) {
        updateSelectedSentence { sentence in
            sentence.emphasis = emphasis
        }
    }

    func setTiming(_ profile: TimingProfile) {
        timing = profile
        if var session {
            session.updateTiming(profile)
            self.session = session
            phraseProgress = 0
            lastPlaybackTick = session.isPlaying ? Date() : nil
        }
    }

    func togglePlayback() {
        guard var session else { return }
        session.togglePlayback()
        lastPlaybackTick = session.isPlaying ? Date() : nil
        if session.isPlaying {
            playbackPausedElapsed = 0
            playbackSegmentStart = Date()
        } else {
            if let start = playbackSegmentStart {
                playbackPausedElapsed += Date().timeIntervalSince(start)
            }
            playbackSegmentStart = nil
        }
        refreshElapsedDisplay()
        self.session = session
    }

    func nextSentence() {
        guard var session else { return }
        session.nextSentence()
        selectedSentenceID = session.currentSentence?.id
        phraseProgress = 0
        lastPlaybackTick = session.isPlaying ? Date() : nil
        self.session = session
    }

    func previousSentence() {
        guard var session else { return }
        session.previousSentence()
        selectedSentenceID = session.currentSentence?.id
        phraseProgress = 0
        lastPlaybackTick = session.isPlaying ? Date() : nil
        self.session = session
    }

    func advancePhrase() {
        guard var session else { return }
        session.advancePhrase()
        selectedSentenceID = session.currentSentence?.id
        phraseProgress = 0
        lastPlaybackTick = session.isPlaying ? Date() : nil
        self.session = session
    }

    func tickPlayback(now: Date = Date()) {
        guard var session,
              session.isPlaying,
              let sentence = session.currentSentence,
              let phrase = session.currentPhrase
        else {
            lastPlaybackTick = nil
            return
        }

        guard let lastPlaybackTick else {
            self.lastPlaybackTick = now
            return
        }

        guard shouldAdvancePlayback else {
            self.lastPlaybackTick = now
            self.session = session
            return
        }

        let elapsed = now.timeIntervalSince(lastPlaybackTick)
        self.lastPlaybackTick = now
        refreshElapsedDisplay()

        let duration: TimeInterval
        if sentence.targetStartSeconds != nil || sentence.targetEndSeconds != nil {
            let base = max(0.35, phrase.estimatedDuration * sentence.emphasis.durationMultiplier)
            duration = session.currentPhraseIndex == sentence.phrases.count - 1
                ? base + sentence.pause.extraSeconds
                : base
        } else {
            duration = max(0.35, session.timing.duration(
                for: phrase,
                in: sentence,
                phraseIndex: session.currentPhraseIndex
            ))
        }
        var progress = phraseProgress + (elapsed * settings.speedMultiplier) / duration

        while progress >= 1, session.isPlaying {
            progress -= 1
            session.advancePhrase()
            selectedSentenceID = session.currentSentence?.id
            if session.currentPhrase == nil || !session.isPlaying {
                progress = 0
            }
        }

        phraseProgress = min(max(progress, 0), 1)
        self.session = session
    }

    func adjustFontSize(_ delta: Double) {
        setPromptFontSize(settings.fontSize + delta)
    }

    func adjustOpacity(_ delta: Double) {
        setPromptOpacity(settings.opacity + delta)
    }

    func adjustPromptWidth(_ delta: Double) {
        setPromptWidth(settings.width + delta, animated: true)
    }

    func setPromptFontSize(_ value: Double) {
        settings.fontSize = clamp(value, to: promptFontSizeRange)
    }

    func setBodyFont(_ fontName: String?) {
        settings.bodyFontName = fontName
    }

    func setLineSpacing(_ value: Double) {
        settings.lineSpacing = clamp(value, to: lineSpacingRange)
    }

    func setTracking(_ value: Double) {
        settings.tracking = clamp(value, to: trackingRange)
    }

    func adjustSpeed(by delta: Double) {
        setPromptSpeedMultiplier(settings.speedMultiplier + delta)
    }

    func setMirrored(_ enabled: Bool) {
        settings.mirrored = enabled
    }

    func startPlaybackWithCountdown() {
        guard session != nil, session?.isPlaying == false, countdownPhase == nil else { return }
        countdownTask?.cancel()
        countdownTask = Task { @MainActor in
            countdownPhase = 3
            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled else { countdownPhase = nil; return }
            countdownPhase = 2
            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled else { countdownPhase = nil; return }
            countdownPhase = 1
            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled else { countdownPhase = nil; return }
            countdownPhase = nil
            togglePlayback()
        }
    }

    func setPromptOpacity(_ value: Double) {
        settings.opacity = clamp(value, to: promptOpacityRange)
    }

    func setPromptBrightness(_ value: Double) {
        settings.brightness = clamp(value, to: promptBrightnessRange)
    }

    func setPromptSpeedMultiplier(_ value: Double) {
        settings.speedMultiplier = clamp(value, to: promptSpeedMultiplierRange)
        lastPlaybackTick = session?.isPlaying == true ? Date() : nil
    }

    func setVoiceActivationThreshold(_ value: Double) {
        settings.voiceActivationThreshold = clamp(value, to: voiceActivationThresholdRange)
    }

    func restoreDefaultSettings() {
        settings = TeleprompterSettings()
        teleprompterWindowController.reposition(settings: settings)
    }

    func setPromptWidth(_ value: Double, animated: Bool = false) {
        settings.width = clamp(value, to: promptWidthRange)
        teleprompterWindowController.resize(to: CGSize(width: settings.width, height: settings.height), anchor: .topLeft, animated: animated)
    }

    func setPromptPosition(_ position: TeleprompterPosition) {
        settings.position = position
        teleprompterWindowController.reposition(settings: settings)
    }

    func setReadingMode(_ mode: PromptReadingMode) {
        settings.readingMode = mode
        if mode == .voiceActivated,
           audioLevelMonitor.permissionStatus == .denied || audioLevelMonitor.permissionStatus == .restricted {
            triggerErrorToast("麦克风权限未开启，跟声模式无法使用")
        }
    }

    func setCursorMode(_ mode: TokenCursorMode) {
        settings.cursorMode = mode
    }

    func toggleSettingsPanel() {
        settingsRotation += showSettingsPanel ? -180 : 180
        showSettingsPanel.toggle()
    }

    func toggleSentencePicker() {
        showSentencePicker.toggle()
    }

    func setHidePromptFromScreenShare(_ enabled: Bool) {
        settings.hidesFromScreenShare = enabled
        teleprompterWindowController.applyScreenSharingVisibility(settings: settings)
    }

    func markPromptPositionCustom() {
        settings.position = .custom
    }

    func setTimingIndex(_ value: Double) {
        let cases = TimingProfile.allCases
        let index = Int(clamp(value.rounded(), to: 0...Double(cases.count - 1)))
        setTiming(cases[index])
    }

    func syncPromptWindowSize(width: Double, height: Double) {
        settings.width = clamp(width, to: promptWidthRange)
        settings.height = clamp(height, to: promptHeightRange)
    }

    func resizePromptWindow(to size: CGSize, anchor: PromptResizeAnchor) {
        settings.width = clamp(size.width, to: promptWidthRange)
        settings.height = clamp(size.height, to: promptHeightRange)
        teleprompterWindowController.resize(
            to: CGSize(width: settings.width, height: settings.height),
            anchor: anchor,
            animated: false
        )
    }

    func openTeleprompter() {
        guard session != nil else { return }
        startVoiceMonitoring()
        teleprompterWindowController.show(model: self)
    }

    func closeTeleprompter() {
        teleprompterWindowController.close()
        playbackPausedElapsed = 0
        playbackSegmentStart = nil
        playbackElapsedDisplay = "00:00"
    }

    func restartSession() {
        guard var session else { return }
        session.currentSentenceIndex = 0
        session.currentPhraseIndex = 0
        session.isPlaying = false
        selectedSentenceID = session.currentSentence?.id
        phraseProgress = 0
        lastPlaybackTick = nil
        playbackPausedElapsed = 0
        playbackSegmentStart = nil
        playbackElapsedDisplay = "00:00"
        self.session = session
    }

    func startVoiceMonitoring() {
        audioLevelMonitor.start()
        if audioLevelMonitor.permissionStatus == .denied || audioLevelMonitor.permissionStatus == .restricted {
            triggerErrorToast("麦克风权限未开启，跟声模式将无法工作")
        }
    }

    func stopVoiceMonitoring() {
        audioLevelMonitor.stop()
        microphoneLevel = 0
    }

    private func refreshElapsedDisplay() {
        let total: TimeInterval
        if session?.isPlaying == true, let start = playbackSegmentStart {
            total = playbackPausedElapsed + Date().timeIntervalSince(start)
        } else {
            total = playbackPausedElapsed
        }
        let t = max(0, Int(total))
        playbackElapsedDisplay = String(format: "%02d:%02d", t / 60, t % 60)
    }

    func openMicrophoneSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
    }

    private func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
        min(max(value, range.lowerBound), range.upperBound)
    }

    private var shouldAdvancePlayback: Bool {
        switch settings.readingMode {
        case .timed:
            return true
        case .voiceActivated:
            let isLoud = microphoneLevel >= settings.voiceActivationThreshold
            if isLoud {
                voiceGateQuietFrameCount = 0
                return true
            } else {
                voiceGateQuietFrameCount += 1
                return voiceGateQuietFrameCount < 4
            }
        }
    }

    private func updateSelectedSentence(_ update: (inout SentenceSegment) -> Void) {
        guard var document = currentDocument,
              let sentenceIndex = selectedSentenceIndex
        else { return }

        update(&document.sentences[sentenceIndex])
        commitSentenceChanges(document, currentSentenceIndex: sentenceIndex, selectedSentenceID: document.sentences[sentenceIndex].id)
    }

    private func commitSentenceChanges(
        _ document: PromptDocument,
        currentSentenceIndex: Int,
        selectedSentenceID: SentenceSegment.ID?
    ) {
        var updatedDocument = document
        updatedDocument.rawText = PromptEditingService.rawText(from: updatedDocument.sentences)
        updatedDocument.updatedAt = Date()
        currentDocument = updatedDocument
        self.selectedSentenceID = selectedSentenceID

        let boundedIndex: Int
        if updatedDocument.sentences.isEmpty {
            boundedIndex = 0
        } else {
            boundedIndex = min(max(currentSentenceIndex, 0), updatedDocument.sentences.count - 1)
        }

        if var session {
            session.document = updatedDocument
            session.currentSentenceIndex = boundedIndex
            session.currentPhraseIndex = 0
            self.session = session
        } else {
            session = PromptSession(document: updatedDocument, timing: timing, currentSentenceIndex: boundedIndex)
        }

        phraseProgress = 0
        lastPlaybackTick = session?.isPlaying == true ? Date() : nil
        saveCurrentDocument()
    }

    private func generatedTitle(from text: String) -> String {
        let firstLine = text.split(whereSeparator: \.isNewline).first.map(String.init) ?? Self.defaultDocumentTitle
        let title = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? Self.defaultDocumentTitle : String(title.prefix(18))
    }
}

enum PromptResizeAnchor {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case top
    case bottom
    case left
    case right
}
