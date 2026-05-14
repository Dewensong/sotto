import Foundation

public struct AiScriptAnalysis: Codable, Equatable, Sendable {
    public var segments: [TimeSegment]
    public var totalDuration: TimeInterval
    public var summary: String?

    public init(
        segments: [TimeSegment],
        totalDuration: TimeInterval,
        summary: String? = nil
    ) {
        self.segments = segments
        self.totalDuration = totalDuration
        self.summary = summary
    }

    public struct TimeSegment: Codable, Equatable, Identifiable, Sendable {
        public var id: UUID
        public var startSeconds: TimeInterval
        public var endSeconds: TimeInterval
        public var content: String
        public var aiNotes: String?

        public init(
            id: UUID = UUID(),
            startSeconds: TimeInterval,
            endSeconds: TimeInterval,
            content: String,
            aiNotes: String? = nil
        ) {
            self.id = id
            self.startSeconds = startSeconds
            self.endSeconds = endSeconds
            self.content = content
            self.aiNotes = aiNotes
        }
    }
}
