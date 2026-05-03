import XCTest
@testable import SottoCore

final class SegmentationServiceTests: XCTestCase {
    func testSplitsChineseEnglishAndParagraphSentences() {
        let text = """
        最近我看到一个很有意思的 AI 电台项目。它不是普通播放器！
        It feels calm, focused, and useful.
        """

        let sentences = SegmentationService().segment(text).sentences

        XCTAssertEqual(sentences.map(\.text), [
            "最近我看到一个很有意思的 AI 电台项目。",
            "它不是普通播放器！",
            "It feels calm, focused, and useful."
        ])
    }

    func testSplitsPhrasesByNaturalPunctuationAndConnectors() {
        let text = "它不是普通播放器，更像一个会根据你状态说话的 AI DJ。"

        let sentence = SegmentationService().segment(text).sentences[0]

        XCTAssertEqual(sentence.phrases.map(\.text), [
            "它不是普通播放器，",
            "更像一个",
            "会根据你状态说话的 AI DJ。"
        ])
    }

    func testLongSentenceSplitsIntoReadablePhrases() {
        let text = "今天我们先把产品的核心路径跑通让录制时能稳定看到当前句下一句和整体节奏。"

        let sentence = SegmentationService().segment(text).sentences[0]

        XCTAssertGreaterThanOrEqual(sentence.phrases.count, 2)
        XCTAssertLessThanOrEqual(sentence.phrases.count, 4)
        XCTAssertEqual(sentence.phrases.map(\.text).joined(), text)
    }

    func testShortSentenceStaysWhole() {
        let text = "准备上场。"

        let sentence = SegmentationService().segment(text).sentences[0]

        XCTAssertEqual(sentence.phrases.map(\.text), ["准备上场。"])
    }
}
