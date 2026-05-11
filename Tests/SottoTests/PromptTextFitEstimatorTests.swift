import XCTest
@testable import SottoCore

final class PromptTextFitEstimatorTests: XCTestCase {
    func testWiderContainerReducesEstimatedLineCount() {
        let text = "我建议下一步做真实录屏验证和两个小修正。"

        let narrow = PromptTextFitEstimator.estimatedLineCount(text: text, fontSize: 34, containerWidth: 280)
        let wide = PromptTextFitEstimator.estimatedLineCount(text: text, fontSize: 34, containerWidth: 760)

        XCTAssertGreaterThan(narrow, wide)
        XCTAssertEqual(wide, 1)
    }

    func testFittedFontSizeShrinksOnlyWhenLineBudgetRequiresIt() {
        let text = "这一句需要根据提词窗口宽度动态适配，而不是固定按短语换行。"

        let narrow = PromptTextFitEstimator.fittedFontSize(
            text: text,
            requestedSize: 42,
            minimumSize: 26,
            containerWidth: 360,
            targetLines: 2
        )
        let wide = PromptTextFitEstimator.fittedFontSize(
            text: text,
            requestedSize: 42,
            minimumSize: 26,
            containerWidth: 920,
            targetLines: 2
        )

        XCTAssertLessThan(narrow, wide)
        XCTAssertEqual(wide, 42)
    }
}
