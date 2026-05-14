import Foundation

public struct SentenceSegment: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var text: String
    public var phrases: [PhraseSegment]
    public var pause: PauseLevel
    public var emphasis: EmphasisLevel
    public var manualSplitOffsets: Set<Int>
    public var targetStartSeconds: TimeInterval?
    public var targetEndSeconds: TimeInterval?
    public var paragraphIndex: Int?

    public init(
        id: UUID = UUID(),
        text: String,
        phrases: [PhraseSegment]? = nil,
        pause: PauseLevel = .normal,
        emphasis: EmphasisLevel = .normal,
        manualSplitOffsets: Set<Int> = [],
        targetStartSeconds: TimeInterval? = nil,
        targetEndSeconds: TimeInterval? = nil,
        paragraphIndex: Int? = nil
    ) {
        self.id = id
        self.text = text
        self.phrases = phrases ?? [PhraseSegment(text: text)]
        self.pause = pause
        self.emphasis = emphasis
        self.manualSplitOffsets = manualSplitOffsets
        self.targetStartSeconds = targetStartSeconds
        self.targetEndSeconds = targetEndSeconds
        self.paragraphIndex = paragraphIndex
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        phrases = try container.decode([PhraseSegment].self, forKey: .phrases)
        pause = try container.decode(PauseLevel.self, forKey: .pause)
        emphasis = try container.decode(EmphasisLevel.self, forKey: .emphasis)
        manualSplitOffsets = try container.decode(Set<Int>.self, forKey: .manualSplitOffsets)
        targetStartSeconds = try container.decodeIfPresent(TimeInterval.self, forKey: .targetStartSeconds)
        targetEndSeconds = try container.decodeIfPresent(TimeInterval.self, forKey: .targetEndSeconds)
        paragraphIndex = try container.decodeIfPresent(Int.self, forKey: .paragraphIndex)
    }
}

public enum PauseLevel: String, Codable, CaseIterable, Sendable {
    case normal
    case short
    case long
}

public enum EmphasisLevel: String, Codable, CaseIterable, Sendable {
    case normal
    case emphasized
}
