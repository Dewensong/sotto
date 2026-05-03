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
    @Published var settings = TeleprompterSettings()
    @Published var recentDocuments: [PromptDocument] = []
    @Published var errorMessage: String?

    private let segmentationService = SegmentationService()
    private let store = PromptDocumentStore()
    private let teleprompterWindowController = TeleprompterWindowController()

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
            open(document)
            saveCurrentDocument()
        }
    }

    func open(_ document: PromptDocument) {
        currentDocument = document
        selectedSentenceID = document.sentences.first?.id
        session = PromptSession(document: document, timing: timing)
        phase = .editor
    }

    func returnHome() {
        teleprompterWindowController.close()
        currentDocument = nil
        session = nil
        selectedSentenceID = nil
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
        saveCurrentDocument()
    }

    func setTiming(_ profile: TimingProfile) {
        timing = profile
        if var session {
            session.updateTiming(profile)
            self.session = session
        }
    }

    func togglePlayback() {
        guard var session else { return }
        session.togglePlayback()
        self.session = session
    }

    func nextSentence() {
        guard var session else { return }
        session.nextSentence()
        selectedSentenceID = session.currentSentence?.id
        self.session = session
    }

    func previousSentence() {
        guard var session else { return }
        session.previousSentence()
        selectedSentenceID = session.currentSentence?.id
        self.session = session
    }

    func advancePhrase() {
        guard var session else { return }
        session.advancePhrase()
        selectedSentenceID = session.currentSentence?.id
        self.session = session
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
