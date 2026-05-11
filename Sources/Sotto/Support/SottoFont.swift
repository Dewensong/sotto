import AppKit
import CoreText
import SwiftUI

@MainActor
public enum SottoFont {
    private static var registeredPixelFontName: String?

    public static func registerBundledFonts() {
        guard registeredPixelFontName == nil,
              let url = bundledFontURL()
        else {
            assertionFailure("Fusion Pixel Font resource was not found in Bundle.module.")
            return
        }

        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)

        guard let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor],
              let descriptor = descriptors.first,
              let fontName = CTFontDescriptorCopyAttribute(descriptor, kCTFontNameAttribute) as? String
        else { return }

        registeredPixelFontName = fontName
    }

    public static var isPixelFontLoaded: Bool {
        registeredPixelFontName != nil
    }

    public static func pixel(_ size: CGFloat) -> Font {
        guard let registeredPixelFontName else {
            return .system(size: size, weight: .regular, design: .monospaced)
        }
        return .custom(registeredPixelFontName, size: size)
    }

    public static func pixelUIFont(size: CGFloat) -> NSFont? {
        guard let registeredPixelFontName else { return nil }
        return NSFont(name: registeredPixelFontName, size: size)
    }

    public static func bodyFont(_ fontName: String?, size: CGFloat) -> Font {
        if let fontName, !fontName.isEmpty {
            return .custom(fontName, size: size)
        }
        return pixel(size)
    }

    public static func bodyUIFont(_ fontName: String?, size: CGFloat) -> NSFont {
        if let fontName, !fontName.isEmpty, let nsFont = NSFont(name: fontName, size: size) {
            return nsFont
        }
        return pixelUIFont(size: size) ?? NSFont.systemFont(ofSize: size)
    }

    public static let readableSystemFonts: [(name: String, label: String)] = [
        ("HelveticaNeue", "Helvetica Neue"),
        ("HelveticaNeue-Light", "Helvetica Neue Light"),
        ("SFProDisplay-Regular", "SF Pro Display"),
        ("SFProText-Regular", "SF Pro Text"),
        ("Georgia", "Georgia"),
        ("TimesNewRomanPSMT", "Times New Roman"),
        ("AvenirNext-Regular", "Avenir Next"),
        ("Menlo-Regular", "Menlo"),
    ]

    public static var availableSystemFonts: [(name: String, label: String)] {
        let installed = readableSystemFonts.filter { NSFont(name: $0.name, size: 12) != nil }
        if installed.isEmpty {
            return [("HelveticaNeue", "Helvetica Neue")]
        }
        return installed
    }

    private static func bundledFontURL() -> URL? {
        Bundle.module.url(
            forResource: "fusion-pixel-12px-proportional",
            withExtension: "otf"
        ) ?? Bundle.module.url(
            forResource: "fusion-pixel-12px-proportional",
            withExtension: "otf",
            subdirectory: "Fonts"
        )
    }
}
