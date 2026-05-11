import XCTest
@testable import SottoCore

final class PromptSessionTests: XCTestCase {
    func testPlaybackPauseAndManualNavigation() {
        let document = PromptDocument(title: "Demo", rawText: "第一句。第二句。", sentences: SegmentationService().segment("第一句。第二句。").sentences)
        var session = PromptSession(document: document, timing: .standard)

        XCTAssertFalse(session.isPlaying)
        session.togglePlayback()
        XCTAssertTrue(session.isPlaying)
        session.nextSentence()
        XCTAssertEqual(session.currentSentenceIndex, 1)
        session.previousSentence()
        XCTAssertEqual(session.currentSentenceIndex, 0)
        session.togglePlayback()
        XCTAssertFalse(session.isPlaying)
    }

    func testAdvancesPhrasesAndStopsAtEnd() {
        let document = SegmentationService().segment("它不是普通播放器，更像一个 AI DJ。")
        var session = PromptSession(document: document, timing: .standard)
        session.isPlaying = true

        for _ in 0..<10 {
            session.advancePhrase()
        }

        XCTAssertEqual(session.currentSentenceIndex, document.sentences.count - 1)
        XCTAssertEqual(session.currentPhraseIndex, document.sentences.last!.phrases.count - 1)
        XCTAssertFalse(session.isPlaying)
    }

    func testTimingProfilesProduceDifferentDurations() {
        let phrase = PhraseSegment(text: "这是一段用于测试节奏的短语")

        XCTAssertGreaterThan(TimingProfile.relaxed.duration(for: phrase), TimingProfile.standard.duration(for: phrase))
        XCTAssertGreaterThan(TimingProfile.standard.duration(for: phrase), TimingProfile.compact.duration(for: phrase))
    }

    func testSentencePauseAndEmphasisAffectDuration() {
        let phrases = [
            PhraseSegment(text: "第一段"),
            PhraseSegment(text: "第二段")
        ]
        let normal = SentenceSegment(text: "第一段，第二段。", phrases: phrases)
        let shortPause = SentenceSegment(text: "第一段，第二段。", phrases: phrases, pause: .short)
        let longPause = SentenceSegment(text: "第一段，第二段。", phrases: phrases, pause: .long)
        let emphasized = SentenceSegment(text: "第一段，第二段。", phrases: phrases, emphasis: .emphasized)

        XCTAssertGreaterThan(TimingProfile.standard.duration(for: shortPause), TimingProfile.standard.duration(for: normal))
        XCTAssertGreaterThan(TimingProfile.standard.duration(for: longPause), TimingProfile.standard.duration(for: shortPause))
        XCTAssertGreaterThan(TimingProfile.standard.duration(for: emphasized), TimingProfile.standard.duration(for: normal))
    }
}
