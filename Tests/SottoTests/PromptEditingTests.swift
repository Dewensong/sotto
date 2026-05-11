import XCTest
@testable import SottoCore

final class PromptEditingTests: XCTestCase {
    func testTogglesManualSplitPointBetweenCharacters() {
        var sentence = SentenceSegment(text: "最近我看到一个很有意思的项目。")

        PromptEditingService.toggleSplit(at: 6, in: &sentence, timing: .standard)

        XCTAssertEqual(sentence.phrases.map(\.text), ["最近我看到", "一个很有意思的项目。"])

        PromptEditingService.toggleSplit(at: 6, in: &sentence, timing: .standard)

        XCTAssertEqual(sentence.phrases.map(\.text), ["最近我看到一个很有意思的项目。"])
    }

    func testIgnoresInvalidManualSplitPositions() {
        var sentence = SentenceSegment(text: "准备上场。")

        PromptEditingService.toggleSplit(at: 0, in: &sentence, timing: .standard)
        PromptEditingService.toggleSplit(at: 5, in: &sentence, timing: .standard)

        XCTAssertEqual(sentence.phrases.map(\.text), ["准备上场。"])
    }

    func testSplitsSentenceIntoTwoSentenceSegmentsAtCharacterBoundary() {
        let sentence = SentenceSegment(text: "这句话前半段保留，后半段应该另起一句。")

        let split = PromptEditingService.splitSentence(sentence, at: 9, timing: .standard)

        XCTAssertEqual(split?.map(\.text), ["这句话前半段保留，", "后半段应该另起一句。"])
        XCTAssertEqual(split?.first?.phrases.map(\.text), ["这句话前半段保留，"])
        XCTAssertEqual(split?.last?.phrases.map(\.text), ["后半段应该另起一句。"])
    }

    func testDoesNotSplitSentenceAtInvalidBoundary() {
        let sentence = SentenceSegment(text: "准备上场。")

        XCTAssertNil(PromptEditingService.splitSentence(sentence, at: 0, timing: .standard))
        XCTAssertNil(PromptEditingService.splitSentence(sentence, at: sentence.text.count, timing: .standard))
    }

    func testMergesTwoSentenceSegmentsAndRebuildsPhrases() {
        let first = SentenceSegment(text: "第一句。", pause: .long, emphasis: .emphasized)
        let second = SentenceSegment(text: "第二句继续说。")

        let merged = PromptEditingService.mergeSentences(first, second, timing: .standard)

        XCTAssertEqual(merged.text, "第一句。第二句继续说。")
        XCTAssertEqual(merged.pause, .long)
        XCTAssertEqual(merged.emphasis, .emphasized)
        XCTAssertEqual(merged.phrases.map(\.text), ["第一句。第二句继续说。"])
    }
}
