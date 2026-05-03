import Foundation

public struct TeleprompterSettings: Codable, Equatable, Sendable {
    public var fontSize: Double
    public var width: Double
    public var opacity: Double
    public var brightness: Double
    public var position: TeleprompterPosition

    public init(
        fontSize: Double = 34,
        width: Double = 820,
        opacity: Double = 0.86,
        brightness: Double = 1,
        position: TeleprompterPosition = .upperCenter
    ) {
        self.fontSize = fontSize
        self.width = width
        self.opacity = opacity
        self.brightness = brightness
        self.position = position
    }
}

public enum TeleprompterPosition: String, Codable, CaseIterable, Sendable {
    case upperCenter
    case cameraNear
    case custom
}
