import AppKit
import SwiftUI
import SottoCore

@MainActor
enum PromptWindowAppearance {
    static let cornerRadius: CGFloat = 30

    static func configureHostingView(_ hostingView: NSView) {
        hostingView.wantsLayer = true
        guard let layer = hostingView.layer else { return }
        layer.backgroundColor = NSColor.clear.cgColor
        layer.isOpaque = false
        layer.cornerRadius = cornerRadius
        layer.cornerCurve = .continuous
        layer.masksToBounds = true
    }

    static func configureWindow(_ window: NSWindow, hidesFromScreenShare: Bool = false) {
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.isMovableByWindowBackground = false
        window.sharingType = hidesFromScreenShare ? .none : .readOnly
    }
}

@MainActor
enum PromptWindowVisibility {
    static func shouldHideWindow(
        _ window: NSWindow,
        promptWindow: NSWindow,
        wasVisible: Bool
    ) -> Bool {
        wasVisible && window !== promptWindow
    }
}

@MainActor
final class TeleprompterWindowController: NSObject, NSWindowDelegate {
    private var window: PromptPanel?
    private weak var model: AppModel?
    private var hiddenBackgroundWindows: [NSWindow] = []
    private var isApplyingPresetPosition = false

    func show(model: AppModel) {
        if let window {
            window.makeKeyAndOrderFront(nil)
            hideBackgroundWindows(except: window)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        self.model = model

        let rootView = TeleprompterWindowView()
            .environmentObject(model)

        let hostingView = NSHostingView(rootView: rootView)
        PromptWindowAppearance.configureHostingView(hostingView)

        let windowSize = CGSize(width: model.settings.width, height: model.settings.height)
        let window = PromptPanel(
            contentRect: CGRect(origin: .zero, size: windowSize),
            styleMask: [.borderless, .nonactivatingPanel, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Sotto Prompt"
        window.contentView = hostingView
        PromptWindowAppearance.configureWindow(window, hidesFromScreenShare: model.settings.hidesFromScreenShare)
        window.minSize = CGSize(width: 620, height: 380)
        window.maxSize = CGSize(width: 1180, height: 720)
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.delegate = self
        window.standardWindowButton(.closeButton)?.isHidden = true
        position(window, settings: model.settings)
        window.orderFrontRegardless()
        hideBackgroundWindows(except: window)
        NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }

    func close() {
        window?.delegate = nil
        window?.close()
        restoreBackgroundWindows()
        window = nil
        model = nil
    }

    func resize(to size: CGSize) {
        resize(to: size, anchor: .topLeft, animated: true)
    }

    func resize(to size: CGSize, anchor: PromptResizeAnchor, animated: Bool = true) {
        guard let window else { return }
        let frame = window.frame
        let origin: CGPoint
        switch anchor {
        case .topLeft:
            origin = CGPoint(x: frame.minX, y: frame.maxY - size.height)
        case .topRight:
            origin = CGPoint(x: frame.maxX - size.width, y: frame.maxY - size.height)
        case .bottomLeft:
            origin = frame.origin
        case .bottomRight:
            origin = CGPoint(x: frame.maxX - size.width, y: frame.minY)
        case .top:
            origin = CGPoint(x: frame.minX, y: frame.maxY - size.height)
        case .bottom:
            origin = CGPoint(x: frame.minX, y: frame.minY)
        case .left:
            origin = CGPoint(x: frame.maxX - size.width, y: frame.minY)
        case .right:
            origin = CGPoint(x: frame.minX, y: frame.minY)
        }
        window.setFrame(CGRect(origin: origin, size: size), display: true, animate: animated)
    }

    func reposition(settings: TeleprompterSettings) {
        guard let window else { return }
        position(window, settings: settings)
    }

    func applyScreenSharingVisibility(settings: TeleprompterSettings) {
        guard let window else { return }
        window.sharingType = settings.hidesFromScreenShare ? .none : .readOnly
    }

    func windowDidResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        model?.syncPromptWindowSize(width: window.frame.width, height: window.frame.height)
    }

    func windowDidMove(_ notification: Notification) {
        guard !isApplyingPresetPosition else { return }
        model?.markPromptPositionCustom()
    }

    func windowWillClose(_ notification: Notification) {
        restoreBackgroundWindows()
        window = nil
        model = nil
    }

    private func position(_ window: NSWindow, settings: TeleprompterSettings) {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let size = CGSize(width: settings.width, height: settings.height)
        let origin: CGPoint
        switch settings.position {
        case .upperCenter:
            origin = CGPoint(
                x: visible.midX - size.width / 2,
                y: visible.maxY - size.height - 80
            )
        case .cameraNear:
            origin = CGPoint(
                x: visible.midX - size.width / 2,
                y: visible.maxY - size.height - 24
            )
        case .custom:
            return
        }

        isApplyingPresetPosition = true
        window.setFrame(CGRect(origin: origin, size: size), display: true)
        DispatchQueue.main.async { [weak self] in
            self?.isApplyingPresetPosition = false
        }
    }

    private func hideBackgroundWindows(except promptWindow: NSWindow) {
        let windowsToHide = NSApp.windows.filter { window in
            PromptWindowVisibility.shouldHideWindow(
                window,
                promptWindow: promptWindow,
                wasVisible: window.isVisible
            )
        }
        for window in windowsToHide where !hiddenBackgroundWindows.contains(where: { $0 === window }) {
            hiddenBackgroundWindows.append(window)
        }
        windowsToHide.forEach { $0.orderOut(nil) }
    }

    private func restoreBackgroundWindows() {
        let windows = hiddenBackgroundWindows
        hiddenBackgroundWindows = []
        windows.forEach { window in
            window.makeKeyAndOrderFront(nil)
        }
    }
}

private final class PromptPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
