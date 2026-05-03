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
}
