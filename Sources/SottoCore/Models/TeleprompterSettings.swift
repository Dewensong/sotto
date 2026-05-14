import Foundation

public struct TeleprompterSettings: Codable, Equatable, Sendable {
    public var fontSize: Double
    public var width: Double
    public var height: Double
    public var opacity: Double
    public var brightness: Double
    public var position: TeleprompterPosition
    public var readingMode: PromptReadingMode
    public var hidesFromScreenShare: Bool
    public var speedMultiplier: Double
    public var voiceActivationThreshold: Double
    public var cursorMode: TokenCursorMode
    public var bodyFontName: String?
    public var lineSpacing: Double
    public var tracking: Double
    public var mirrored: Bool

    public var usesPixelFont: Bool { bodyFontName == nil }

    public init(
        fontSize: Double = 36,
        width: Double = 900,
        height: Double = 520,
        opacity: Double = 0.96,
        brightness: Double = 1.04,
        position: TeleprompterPosition = .cameraNear,
        readingMode: PromptReadingMode = .timed,
        hidesFromScreenShare: Bool = false,
        speedMultiplier: Double = 0.72,
        voiceActivationThreshold: Double = 0.12,
        cursorMode: TokenCursorMode = .character,
        bodyFontName: String? = nil,
        lineSpacing: Double = 0.18,
        tracking: Double = 0,
        mirrored: Bool = false
    ) {
        self.fontSize = fontSize
        self.width = width
        self.height = height
        self.opacity = opacity
        self.brightness = brightness
        self.position = position
        self.readingMode = readingMode
        self.hidesFromScreenShare = hidesFromScreenShare
        self.speedMultiplier = speedMultiplier
        self.voiceActivationThreshold = voiceActivationThreshold
        self.cursorMode = cursorMode
        self.bodyFontName = bodyFontName
        self.lineSpacing = lineSpacing
        self.tracking = tracking
        self.mirrored = mirrored
    }
}

public enum TeleprompterPosition: String, Codable, CaseIterable, Sendable {
    case upperCenter
    case cameraNear
    case custom
}

public enum PromptReadingMode: String, Codable, CaseIterable, Sendable {
    case timed
    case voiceActivated
}

public enum TokenCursorMode: String, Codable, CaseIterable, Sendable {
    case character
    case word
    case line
}
