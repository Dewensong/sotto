import AppKit
import XCTest
@testable import Sotto

@MainActor
final class PromptWindowAppearanceTests: XCTestCase {
    func testHostingViewIsMaskedToPromptCornerRadius() {
        let view = NSView(frame: CGRect(x: 0, y: 0, width: 760, height: 460))

        PromptWindowAppearance.configureHostingView(view)

        XCTAssertTrue(view.wantsLayer)
        XCTAssertEqual(view.layer?.cornerRadius, PromptWindowAppearance.cornerRadius)
        XCTAssertEqual(view.layer?.cornerCurve, .continuous)
        XCTAssertEqual(view.layer?.masksToBounds, true)
        XCTAssertEqual(view.layer?.backgroundColor?.alpha, 0)
        XCTAssertEqual(view.layer?.isOpaque, false)
    }

    func testPromptWindowSurfaceStaysTransparentAndShadowless() {
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 760, height: 460),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        PromptWindowAppearance.configureWindow(window)

        XCTAssertEqual(window.isOpaque, false)
        XCTAssertEqual(window.backgroundColor, .clear)
        XCTAssertEqual(window.hasShadow, false)
        XCTAssertEqual(window.isMovableByWindowBackground, false)
    }

    func testPromptWindowCanBeHiddenFromScreenSharing() {
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 760, height: 460),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        PromptWindowAppearance.configureWindow(window, hidesFromScreenShare: true)

        XCTAssertEqual(window.sharingType, .none)
    }

    func testPromptWindowDefaultsToReadableForScreenSharing() {
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 760, height: 460),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        PromptWindowAppearance.configureWindow(window, hidesFromScreenShare: false)

        XCTAssertEqual(window.sharingType, .readOnly)
    }

    func testPromptWindowVisibilityKeepsPromptAndHidesVisibleBackgroundWindows() {
        let promptWindow = NSWindow()
        let mainWindow = NSWindow()

        XCTAssertFalse(
            PromptWindowVisibility.shouldHideWindow(
                promptWindow,
                promptWindow: promptWindow,
                wasVisible: true
            )
        )

        XCTAssertTrue(
            PromptWindowVisibility.shouldHideWindow(
                mainWindow,
                promptWindow: promptWindow,
                wasVisible: true
            )
        )

        XCTAssertFalse(
            PromptWindowVisibility.shouldHideWindow(
                mainWindow,
                promptWindow: promptWindow,
                wasVisible: false
            )
        )
    }
}
