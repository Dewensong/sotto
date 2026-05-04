import XCTest
@testable import Sotto

@MainActor
final class SottoFontTests: XCTestCase {
    func testBundledFusionPixelFontRegistersForProcess() {
        SottoFont.registerBundledFonts()

        XCTAssertTrue(SottoFont.isPixelFontLoaded)
        XCTAssertNotNil(SottoFont.pixelUIFont(size: 28))
    }
}
