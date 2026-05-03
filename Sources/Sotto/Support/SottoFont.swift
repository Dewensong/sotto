import AppKit
import CoreText
import SwiftUI

@MainActor
enum SottoFont {
    private static var registeredPixelFontName: String?

    static func registerBundledFonts() {
        guard registeredPixelFontName == nil,
              let url = Bundle.module.url(
                  forResource: "fusion-pixel-12px-proportional",
                  withExtension: "otf",
                  subdirectory: "Fonts"
              )
        else { return }

        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)

        guard let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor],
              let descriptor = descriptors.first,
              let fontName = CTFontDescriptorCopyAttribute(descriptor, kCTFontNameAttribute) as? String
        else { return }

        registeredPixelFontName = fontName
    }

    static func pixel(_ size: CGFloat) -> Font {
        guard let registeredPixelFontName else {
            return .system(size: size, weight: .regular, design: .monospaced)
        }
        return .custom(registeredPixelFontName, size: size)
    }

    static func pixelUIFont(size: CGFloat) -> NSFont? {
        guard let registeredPixelFontName else { return nil }
        return NSFont(name: registeredPixelFontName, size: size)
    }
}
