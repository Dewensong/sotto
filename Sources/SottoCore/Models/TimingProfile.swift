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

    public func duration(for sentence: SentenceSegment) -> TimeInterval {
        let phraseDuration = sentence.phrases.reduce(0) { partialResult, phrase in
            partialResult + duration(for: phrase)
        }
        return phraseDuration * sentence.emphasis.durationMultiplier + sentence.pause.extraSeconds
    }

    public func duration(for phrase: PhraseSegment, in sentence: SentenceSegment, phraseIndex: Int) -> TimeInterval {
        var phraseDuration = duration(for: phrase) * sentence.emphasis.durationMultiplier
        if phraseIndex == sentence.phrases.count - 1 {
            phraseDuration += sentence.pause.extraSeconds
        }
        return phraseDuration
    }
}

public extension PauseLevel {
    var title: String {
        switch self {
        case .normal: "无"
        case .short: "短停顿"
        case .long: "长停顿"
        }
    }

    var extraSeconds: TimeInterval {
        switch self {
        case .normal: 0
        case .short: 0.42
        case .long: 0.88
        }
    }
}

public extension EmphasisLevel {
    var title: String {
        switch self {
        case .normal: "普通"
        case .emphasized: "强调"
        }
    }

    var durationMultiplier: Double {
        switch self {
        case .normal: 1
        case .emphasized: 1.08
        }
    }
}
