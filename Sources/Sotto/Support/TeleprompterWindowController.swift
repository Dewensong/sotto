import AppKit
import SwiftUI

@MainActor
final class TeleprompterWindowController {
    private var window: PromptPanel?

    func show(model: AppModel) {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let rootView = TeleprompterWindowView()
            .environmentObject(model)

        let hostingView = NSHostingView(rootView: rootView)
        let window = PromptPanel(
            contentRect: CGRect(x: 0, y: 0, width: model.settings.width, height: 420),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.title = "Sotto Prompt"
        window.contentView = hostingView
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        window.standardWindowButton(.closeButton)?.isHidden = true
        position(window, width: model.settings.width)
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }

    func close() {
        window?.close()
        window = nil
    }

    private func position(_ window: NSWindow, width: Double) {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let size = CGSize(width: width, height: 420)
        let origin = CGPoint(
            x: visible.midX - size.width / 2,
            y: visible.maxY - size.height - 80
        )
        window.setFrame(CGRect(origin: origin, size: size), display: true)
    }
}

private final class PromptPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
