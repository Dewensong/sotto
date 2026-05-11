import XCTest
import SottoCore
@testable import Sotto

@MainActor
final class AppModelTests: XCTestCase {
    func testDefaultPromptSettingsFavorRecordingReadyShowcase() {
        let model = AppModel()

        XCTAssertEqual(model.settings.position, .cameraNear)
        XCTAssertEqual(model.settings.width, 900)
        XCTAssertEqual(model.settings.height, 520)
        XCTAssertEqual(model.settings.fontSize, 36)
        XCTAssertEqual(model.settings.opacity, 0.96)
        XCTAssertEqual(model.settings.brightness, 1.04)
        XCTAssertEqual(model.settings.speedMultiplier, 0.72)
    }

    func testPlaybackTickUsesCurrentTimingInsteadOfStoredPhraseEstimate() {
        let document = PromptDocument(
            title: "Timing",
            rawText: "第一段，第二段。",
            sentences: [
                SentenceSegment(
                    text: "第一段，第二段。",
                    phrases: [
                        PhraseSegment(text: "第一段，", estimatedDuration: 99),
                        PhraseSegment(text: "第二段。", estimatedDuration: 99)
                    ]
                )
            ]
        )
        let model = AppModel()
        model.timing = .compact
        model.setPromptSpeedMultiplier(1)
        model.session = PromptSession(document: document, timing: .compact, isPlaying: true)

        let start = Date(timeIntervalSinceReferenceDate: 1_000)
        model.tickPlayback(now: start)
        model.tickPlayback(now: start.addingTimeInterval(TimingProfile.compact.duration(for: document.sentences[0].phrases[0]) + 0.02))

        XCTAssertEqual(model.session?.currentPhraseIndex, 1)
        XCTAssertLessThan(model.phraseProgress, 0.1)
    }

    func testTimedPlaybackStartsSlowerWithGlobalSpeedMultiplier() {
        let document = twoPhraseDocument()
        let model = AppModel()
        model.session = PromptSession(document: document, timing: .compact, isPlaying: true)

        let start = Date(timeIntervalSinceReferenceDate: 1_000)
        model.tickPlayback(now: start)
        model.tickPlayback(now: start.addingTimeInterval(TimingProfile.compact.duration(for: document.sentences[0].phrases[0]) + 0.02))

        XCTAssertEqual(model.session?.currentPhraseIndex, 0)
        XCTAssertGreaterThan(model.phraseProgress, 0.5)
    }

    func testGlobalSpeedMultiplierCanAccelerateTimedPlayback() {
        let document = twoPhraseDocument()
        let model = AppModel()
        model.setPromptSpeedMultiplier(1.35)
        model.session = PromptSession(document: document, timing: .compact, isPlaying: true)

        let start = Date(timeIntervalSinceReferenceDate: 1_000)
        model.tickPlayback(now: start)
        model.tickPlayback(now: start.addingTimeInterval(TimingProfile.compact.duration(for: document.sentences[0].phrases[0]) * 0.82))

        XCTAssertEqual(model.session?.currentPhraseIndex, 1)
    }

    func testVoiceActivatedPlaybackPausesWhenMicrophoneIsQuiet() {
        let document = twoPhraseDocument()
        let model = AppModel()
        model.settings.readingMode = .voiceActivated
        model.microphoneLevel = 0.02
        model.setPromptSpeedMultiplier(1)
        model.session = PromptSession(document: document, timing: .compact, isPlaying: true)

        let start = Date(timeIntervalSinceReferenceDate: 1_000)
        model.tickPlayback(now: start)
        // Hysteresis requires 4 consecutive quiet frames before pausing.
        // First 3 quiet ticks still advance; the 4th and beyond block.
        let duration = TimingProfile.compact.duration(for: document.sentences[0].phrases[0])
        // Advance once while gate is still open.
        model.tickPlayback(now: start.addingTimeInterval(duration + 0.02))
        XCTAssertEqual(model.session?.currentPhraseIndex, 1)

        // Now tick 4 more times with quiet mic to trigger hysteresis block.
        let later = start.addingTimeInterval(duration + 0.02)
        model.tickPlayback(now: later.addingTimeInterval(0.03))
        model.tickPlayback(now: later.addingTimeInterval(0.06))
        model.tickPlayback(now: later.addingTimeInterval(0.09))
        model.tickPlayback(now: later.addingTimeInterval(0.12))

        // After hysteresis kicks in, further ticks should not advance.
        let phraseBefore = model.session?.currentPhraseIndex
        model.tickPlayback(now: later.addingTimeInterval(5))
        XCTAssertEqual(model.session?.currentPhraseIndex, phraseBefore)
    }

    func testVoiceActivatedPlaybackAdvancesWhenMicrophoneIsActive() {
        let document = twoPhraseDocument()
        let model = AppModel()
        model.settings.readingMode = .voiceActivated
        model.microphoneLevel = 0.42
        model.setPromptSpeedMultiplier(1)
        model.session = PromptSession(document: document, timing: .compact, isPlaying: true)

        let start = Date(timeIntervalSinceReferenceDate: 1_000)
        model.tickPlayback(now: start)
        model.tickPlayback(now: start.addingTimeInterval(TimingProfile.compact.duration(for: document.sentences[0].phrases[0]) + 0.02))

        XCTAssertEqual(model.session?.currentPhraseIndex, 1)
    }

    func testTeleprompterSettingsClampForLiveControls() {
        let model = AppModel()

        model.adjustFontSize(-100)
        XCTAssertEqual(model.settings.fontSize, 24)
        model.adjustFontSize(100)
        XCTAssertEqual(model.settings.fontSize, 48)

        model.adjustOpacity(-10)
        XCTAssertEqual(model.settings.opacity, 0.55)
        model.adjustOpacity(10)
        XCTAssertEqual(model.settings.opacity, 1)

        model.adjustPromptWidth(-10_000)
        XCTAssertEqual(model.settings.width, 620)
        model.adjustPromptWidth(10_000)
        XCTAssertEqual(model.settings.width, 1180)
    }

    func testTeleprompterSettingsClampForSliderControls() {
        let model = AppModel()

        model.setPromptFontSize(-100)
        XCTAssertEqual(model.settings.fontSize, 24)
        model.setPromptFontSize(100)
        XCTAssertEqual(model.settings.fontSize, 48)

        model.setPromptOpacity(0)
        XCTAssertEqual(model.settings.opacity, 0.55)
        model.setPromptOpacity(2)
        XCTAssertEqual(model.settings.opacity, 1)

        model.setPromptWidth(100)
        XCTAssertEqual(model.settings.width, 620)
        model.setPromptWidth(2_000)
        XCTAssertEqual(model.settings.width, 1180)
    }

    func testTimingSliderIndexMapsToTimingProfiles() {
        let model = AppModel()
        model.open(SegmentationService().segment("第一句。"))

        model.setTimingIndex(-10)
        XCTAssertEqual(model.timing, .relaxed)
        XCTAssertEqual(model.session?.timing, .relaxed)

        model.setTimingIndex(1.4)
        XCTAssertEqual(model.timing, .standard)
        XCTAssertEqual(model.session?.timing, .standard)

        model.setTimingIndex(20)
        XCTAssertEqual(model.timing, .compact)
        XCTAssertEqual(model.session?.timing, .compact)
    }

    func testJumpToSentenceResetsPhraseProgressAndKeepsPlaybackState() {
        let document = SegmentationService().segment("第一句。第二句。第三句。")
        let model = AppModel()
        model.open(document)
        model.togglePlayback()
        model.phraseProgress = 0.72

        model.jumpToSentence(at: 2)

        XCTAssertEqual(model.session?.currentSentenceIndex, 2)
        XCTAssertEqual(model.session?.currentPhraseIndex, 0)
        XCTAssertEqual(model.selectedSentenceID, document.sentences[2].id)
        XCTAssertEqual(model.phraseProgress, 0)
        XCTAssertEqual(model.session?.isPlaying, true)
    }

    func testPromptWindowSizeSyncClampsDraggedSize() {
        let model = AppModel()

        model.syncPromptWindowSize(width: 100, height: 100)
        XCTAssertEqual(model.settings.width, 620)
        XCTAssertEqual(model.settings.height, 380)

        model.syncPromptWindowSize(width: 2_000, height: 1_200)
        XCTAssertEqual(model.settings.width, 1180)
        XCTAssertEqual(model.settings.height, 720)
    }

    func testPromptWindowCanResizeFromEdgesAsWellAsCorners() {
        let model = AppModel()

        model.resizePromptWindow(to: CGSize(width: 900, height: 520), anchor: .right)
        XCTAssertEqual(model.settings.width, 900)
        XCTAssertEqual(model.settings.height, 520)

        model.resizePromptWindow(to: CGSize(width: 760, height: 460), anchor: .bottom)
        XCTAssertEqual(model.settings.width, 760)
        XCTAssertEqual(model.settings.height, 460)
    }

    func testSelectedSentenceRhythmSettingsSyncToDocumentAndSession() {
        let model = AppModel(store: temporaryStore())
        let document = SegmentationService().segment("第一句。第二句。")
        model.open(document)

        model.setSelectedSentencePause(.long)
        model.setSelectedSentenceEmphasis(.emphasized)

        XCTAssertEqual(model.currentDocument?.sentences[0].pause, .long)
        XCTAssertEqual(model.currentDocument?.sentences[0].emphasis, .emphasized)
        XCTAssertEqual(model.session?.document.sentences[0].pause, .long)
        XCTAssertEqual(model.session?.document.sentences[0].emphasis, .emphasized)
    }

    func testSelectedSentenceTextEditUpdatesRawTextSessionAndRecentDocument() throws {
        let store = temporaryStore()
        let model = AppModel(store: store)
        let document = SegmentationService().segment("第一句。第二句。")
        model.open(document)

        model.updateSelectedSentenceText("第一句改成更自然的说法。")

        XCTAssertEqual(model.currentDocument?.sentences.map(\.text), ["第一句改成更自然的说法。", "第二句。"])
        XCTAssertEqual(model.currentDocument?.rawText, "第一句改成更自然的说法。\n第二句。")
        XCTAssertEqual(model.session?.document.rawText, "第一句改成更自然的说法。\n第二句。")
        XCTAssertEqual(try store.loadRecentDocuments().first?.rawText, "第一句改成更自然的说法。\n第二句。")
    }

    func testSplittingSelectedSentenceCreatesAnotherSentenceAndKeepsSelectionNearSplit() {
        let model = AppModel(store: temporaryStore())
        let document = PromptDocument(
            title: "Split",
            rawText: "这句话前半段保留，后半段应该另起一句。",
            sentences: [SentenceSegment(text: "这句话前半段保留，后半段应该另起一句。")]
        )
        model.open(document)

        model.splitSelectedSentence(at: 9)

        XCTAssertEqual(model.currentDocument?.sentences.map(\.text), ["这句话前半段保留，", "后半段应该另起一句。"])
        XCTAssertEqual(model.currentDocument?.rawText, "这句话前半段保留，\n后半段应该另起一句。")
        XCTAssertEqual(model.session?.document.sentences.map(\.text), ["这句话前半段保留，", "后半段应该另起一句。"])
        XCTAssertEqual(model.session?.currentSentenceIndex, 0)
    }

    func testMergingSelectedSentenceWithPreviousCombinesSentencesAndUpdatesSession() {
        let model = AppModel(store: temporaryStore())
        let document = SegmentationService().segment("第一句。第二句。第三句。")
        model.open(document)
        model.selectSentence(document.sentences[1])

        model.mergeSelectedSentenceWithPrevious()

        XCTAssertEqual(model.currentDocument?.sentences.map(\.text), ["第一句。第二句。", "第三句。"])
        XCTAssertEqual(model.currentDocument?.rawText, "第一句。第二句。\n第三句。")
        XCTAssertEqual(model.session?.currentSentenceIndex, 0)
        XCTAssertEqual(model.selectedSentenceID, model.currentDocument?.sentences[0].id)
    }

    func testPromptBrightnessAndPositionSettingsClamp() {
        let model = AppModel()

        model.setPromptBrightness(0)
        XCTAssertEqual(model.settings.brightness, 0.65)
        model.setPromptBrightness(2)
        XCTAssertEqual(model.settings.brightness, 1.2)

        model.setPromptPosition(.cameraNear)
        XCTAssertEqual(model.settings.position, .cameraNear)
    }

    func testRecentDocumentCanBeCopiedBackToInput() {
        let model = AppModel()
        var document = SegmentationService().segment("这是一段可以重新上场的稿件。")
        document.title = "Reusable"
        model.copyRecentDocumentToInput(document)

        XCTAssertEqual(model.inputText, document.rawText)
        XCTAssertEqual(model.phase, .home)
    }

    func testCanOpenDocumentManagerFromHomeAndReturnHome() {
        let model = AppModel(store: temporaryStore())

        model.openDocumentManager()
        XCTAssertEqual(model.phase, .documentManager)

        model.closeDocumentManager()
        XCTAssertEqual(model.phase, .home)
    }

    func testCreateDocumentFromInputAddsDraftToDocumentLibrary() async throws {
        let store = temporaryStore()
        let model = AppModel(store: store)
        model.inputText = "首页粘贴进来的第一段稿件。"

        model.createDocumentFromInput()
        try await Task.sleep(for: .milliseconds(900))

        XCTAssertEqual(model.phase, .editor)
        XCTAssertEqual(try store.loadRecentDocuments().first?.rawText, "首页粘贴进来的第一段稿件。")
    }

    private func temporaryStore() -> PromptDocumentStore {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        return PromptDocumentStore(directory: directory)
    }

    private func twoPhraseDocument() -> PromptDocument {
        PromptDocument(
            title: "Voice",
            rawText: "第一段，第二段。",
            sentences: [
                SentenceSegment(
                    text: "第一段，第二段。",
                    phrases: [
                        PhraseSegment(text: "第一段，", estimatedDuration: 1),
                        PhraseSegment(text: "第二段。", estimatedDuration: 1)
                    ]
                )
            ]
        )
    }
}
