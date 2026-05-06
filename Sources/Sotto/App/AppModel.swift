import AppKit
import Combine
import Foundation
import SottoCore

@MainActor
final class AppModel: ObservableObject {
    enum Phase {
        case home
        case preparing
        case editor
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
    @Published var errorMessage: String?
    @Published var showRhythmReadyAnnouncement = false

    private let segmentationService = SegmentationService()
    private let store = PromptDocumentStore()
    private let teleprompterWindowController = TeleprompterWindowController()
    private var lastPlaybackTick: Date?

    init() {
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

    func createDocumentFromInput() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var document = segmentationService.segment(trimmed, title: "新的提词稿", timing: timing)
        document.title = generatedTitle(from: trimmed)
        phase = .preparing
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(780))
            open(document, announceRhythmReady: true)
            saveCurrentDocument()
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
        showRhythmReadyAnnouncement = false
        phase = .home
    }

    func loadRecentDocuments() {
        do {
            recentDocuments = try store.loadRecentDocuments()
        } catch {
            errorMessage = "最近稿件读取失败"
        }
    }

    func saveCurrentDocument() {
        guard let currentDocument else { return }
        do {
            try store.save(currentDocument)
            loadRecentDocuments()
        } catch {
            errorMessage = "稿件保存失败"
        }
    }

    func updateRawText(_ text: String) {
        guard var document = currentDocument else { return }
        document.rawText = text
        document.updatedAt = Date()
        currentDocument = document
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
        if var session, let index = currentDocument?.sentences.firstIndex(where: { $0.id == sentence.id }) {
            session.currentSentenceIndex = index
            session.currentPhraseIndex = 0
            self.session = session
            phraseProgress = 0
            lastPlaybackTick = nil
        }
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
        guard var session, session.isPlaying, let phrase = session.currentPhrase else {
            lastPlaybackTick = nil
            return
        }

        guard let lastPlaybackTick else {
            self.lastPlaybackTick = now
            return
        }

        let elapsed = now.timeIntervalSince(lastPlaybackTick)
        self.lastPlaybackTick = now
        let duration = max(0.35, session.timing.duration(for: phrase))
        var progress = phraseProgress + elapsed / duration

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
        settings.fontSize = min(max(settings.fontSize + delta, 24), 48)
    }

    func adjustOpacity(_ delta: Double) {
        settings.opacity = min(max(settings.opacity + delta, 0.55), 1)
    }

    func adjustPromptWidth(_ delta: Double) {
        settings.width = min(max(settings.width + delta, 620), 980)
        teleprompterWindowController.resize(to: CGSize(width: settings.width, height: 460))
    }

    func openTeleprompter() {
        guard session != nil else { return }
        teleprompterWindowController.show(model: self)
    }

    func closeTeleprompter() {
        teleprompterWindowController.close()
    }

    private func generatedTitle(from text: String) -> String {
        let firstLine = text.split(whereSeparator: \.isNewline).first.map(String.init) ?? "新的提词稿"
        let title = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? "新的提词稿" : String(title.prefix(18))
    }
}
