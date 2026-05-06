import XCTest
import SottoCore
@testable import Sotto

@MainActor
final class AppModelTests: XCTestCase {
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
        model.session = PromptSession(document: document, timing: .compact, isPlaying: true)

        let start = Date(timeIntervalSinceReferenceDate: 1_000)
        model.tickPlayback(now: start)
        model.tickPlayback(now: start.addingTimeInterval(TimingProfile.compact.duration(for: document.sentences[0].phrases[0]) + 0.02))

        XCTAssertEqual(model.session?.currentPhraseIndex, 1)
        XCTAssertLessThan(model.phraseProgress, 0.1)
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
        XCTAssertEqual(model.settings.width, 980)
    }
}
