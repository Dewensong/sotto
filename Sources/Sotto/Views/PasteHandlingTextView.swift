import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct PasteHandlingTextView: NSViewRepresentable {
    @Binding var text: String
    var isFocused: Bool
    var onFocusChange: (Bool) -> Void
    var onFileURLsPasted: ([URL]) -> Void

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.autohidesScrollers = true

        let textView = PasteInterceptingTextView()
        textView.delegate = context.coordinator
        textView.font = SottoFont.pixelUIFont(size: 15) ?? NSFont.monospacedSystemFont(ofSize: 15, weight: .regular)
        textView.textColor = NSColor(red: 0.96, green: 0.925, blue: 0.84, alpha: 1.0)
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.isRichText = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainerInset = NSSize(width: 0, height: 4)
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.minSize = .zero
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.onFileURLsPasted = { urls in
            onFileURLsPasted(urls)
        }

        scrollView.documentView = textView
        context.coordinator.textView = textView

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? PasteInterceptingTextView else { return }

        if textView.string != text {
            textView.string = text
        }

        if isFocused, let window = scrollView.window, window.firstResponder != textView {
            DispatchQueue.main.async {
                window.makeFirstResponder(textView)
            }
        }

        if !isFocused, let window = scrollView.window, window.firstResponder == textView {
            DispatchQueue.main.async {
                window.makeFirstResponder(nil)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onFocusChange: onFocusChange)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: String
        var onFocusChange: (Bool) -> Void
        weak var textView: PasteInterceptingTextView?

        init(text: Binding<String>, onFocusChange: @escaping (Bool) -> Void) {
            self._text = text
            self.onFocusChange = onFocusChange
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = textView else { return }
            text = textView.string
        }

        func textDidBeginEditing(_ notification: Notification) {
            onFocusChange(true)
        }

        func textDidEndEditing(_ notification: Notification) {
            onFocusChange(false)
        }
    }
}

final class PasteInterceptingTextView: NSTextView {
    var onFileURLsPasted: (([URL]) -> Void)?

    override func paste(_ sender: Any?) {
        let pasteboard = NSPasteboard.general
        if let urls = fileURLs(from: pasteboard), !urls.isEmpty {
            onFileURLsPasted?(urls)
            return
        }
        super.paste(sender)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        if let urls = fileURLs(from: sender.draggingPasteboard), !urls.isEmpty {
            onFileURLsPasted?(urls)
            return true
        }
        return super.performDragOperation(sender)
    }

    private func fileURLs(from pasteboard: NSPasteboard) -> [URL]? {
        guard let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL],
              !urls.isEmpty
        else { return nil }
        let supported = urls.filter { FileTextExtractor.supportedExtensions.contains($0.pathExtension.lowercased()) }
        return supported.isEmpty ? nil : supported
    }
}
