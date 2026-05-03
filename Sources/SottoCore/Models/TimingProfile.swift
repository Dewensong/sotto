import Foundation

public enum TimingProfile: String, Codable, CaseIterable, Identifiable, Sendable {
    case relaxed
    case standard
    case compact

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .relaxed: "舒缓"
        case .standard: "标准"
        case .compact: "紧凑"
        }
    }

    public var secondsPerUnit: Double {
        switch self {
        case .relaxed: 0.27
        case .standard: 0.20
        case .compact: 0.145
        }
    }

    public func duration(for phrase: PhraseSegment) -> TimeInterval {
        let units = max(4, phrase.text.filter { !$0.isWhitespace }.count)
        return max(0.8, Double(units) * secondsPerUnit)
    }
}
