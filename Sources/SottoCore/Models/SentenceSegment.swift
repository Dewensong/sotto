import Foundation

public struct SentenceSegment: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var text: String
    public var phrases: [PhraseSegment]
    public var pause: PauseLevel
    public var emphasis: EmphasisLevel
    public var manualSplitOffsets: Set<Int>

    public init(
        id: UUID = UUID(),
        text: String,
        phrases: [PhraseSegment]? = nil,
        pause: PauseLevel = .normal,
        emphasis: EmphasisLevel = .normal,
        manualSplitOffsets: Set<Int> = []
    ) {
        self.id = id
        self.text = text
        self.phrases = phrases ?? [PhraseSegment(text: text)]
        self.pause = pause
        self.emphasis = emphasis
        self.manualSplitOffsets = manualSplitOffsets
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
