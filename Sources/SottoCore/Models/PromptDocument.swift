import Foundation

public struct PromptDocument: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var rawText: String
    public var sentences: [SentenceSegment]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        rawText: String,
        sentences: [SentenceSegment],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.rawText = rawText
        self.sentences = sentences
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
