import Foundation

public struct PhraseSegment: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var text: String
    public var estimatedDuration: TimeInterval

    public init(id: UUID = UUID(), text: String, estimatedDuration: TimeInterval = 0) {
        self.id = id
        self.text = text
        self.estimatedDuration = estimatedDuration
    }
}
