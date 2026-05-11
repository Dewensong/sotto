import AppKit
import Combine
import Foundation
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

    private let segmentationService = SegmentationService()
    private let store: PromptDocumentStore
    private let teleprompterWindowController = TeleprompterWindowController()
    private let audioLevelMonitor = AudioLevelMonitor()
    private var lastPlaybackTick: Date?
    private var playbackSegmentStart: Date?
    private var playbackPausedElapsed: TimeInterval = 0
    private var voiceGateQuietFrameCount: Int = 0
    private var cancellables: Set<AnyCancellable> = []

    private let promptFontSizeRange: ClosedRange<Double> = 24...48
    private let promptOpacityRange: ClosedRange<Double> = 0.55...1
    private let promptWidthRange: ClosedRange<Double> = 620...1180
    private let promptHeightRange: ClosedRange<Double> = 380...720
    private let promptBrightnessRange: ClosedRange<Double> = 0.65...1.2
    private let promptSpeedMultiplierRange: ClosedRange<Double> = 0.55...1.65
    private let voiceActivationThresholdRange: ClosedRange<Double> = 0.08...0.50

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
        var document = segmentationService.segment(trimmed, title: "新的提词稿", timing: timing)
        document.title = generatedTitle(from: trimmed)
        do {
            try store.save(document)
            loadRecentDocuments()
            triggerSaveToast("已保存到全部稿件")
        } catch {
            triggerErrorToast("稿件保存失败")
        }
    }

    func createDocumentFromInput() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var document = segmentationService.segment(trimmed, title: "新的提词稿", timing: timing)
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
        toast = SottoToastMessage(text: message, kind: .success)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            toast = nil
        }
    }

    private func triggerErrorToast(_ message: String) {
        toast = SottoToastMessage(text: message, kind: .error)
        Task { @MainActor in
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
            } else if phase == .documentManager {
                phase = .documentManager
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
        let duration = max(0.35, session.timing.duration(
            for: phrase,
            in: sentence,
            phraseIndex: session.currentPhraseIndex
        ))
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
        let firstLine = text.split(whereSeparator: \.isNewline).first.map(String.init) ?? "新的提词稿"
        let title = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? "新的提词稿" : String(title.prefix(18))
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
