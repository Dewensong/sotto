import Foundation

public struct PromptDocument: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var rawText: String
    public var sentences: [SentenceSegment]
    public var createdAt: Date
    public var updatedAt: Date
    public var isArchived: Bool

    public init(
        id: UUID = UUID(),
        title: String,
        rawText: String,
        sentences: [SentenceSegment],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isArchived: Bool = false
    ) {
        self.id = id
        self.title = title
        self.rawText = rawText
        self.sentences = sentences
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        rawText = try container.decode(String.self, forKey: .rawText)
        sentences = try container.decode([SentenceSegment].self, forKey: .sentences)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
    }
}
