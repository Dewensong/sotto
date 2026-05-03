import Foundation

public struct PromptSession: Codable, Equatable, Sendable {
    public var document: PromptDocument
    public var timing: TimingProfile
    public var currentSentenceIndex: Int
    public var currentPhraseIndex: Int
    public var isPlaying: Bool

    public init(
        document: PromptDocument,
        timing: TimingProfile,
        currentSentenceIndex: Int = 0,
        currentPhraseIndex: Int = 0,
        isPlaying: Bool = false
    ) {
        self.document = document
        self.timing = timing
        self.currentSentenceIndex = currentSentenceIndex
        self.currentPhraseIndex = currentPhraseIndex
        self.isPlaying = isPlaying
    }

    public var currentSentence: SentenceSegment? {
        guard document.sentences.indices.contains(currentSentenceIndex) else { return nil }
        return document.sentences[currentSentenceIndex]
    }

    public var currentPhrase: PhraseSegment? {
        guard let sentence = currentSentence, sentence.phrases.indices.contains(currentPhraseIndex) else { return nil }
        return sentence.phrases[currentPhraseIndex]
    }

    public mutating func togglePlayback() {
        isPlaying.toggle()
    }

    public mutating func nextSentence() {
        guard currentSentenceIndex < document.sentences.count - 1 else {
            isPlaying = false
            return
        }
        currentSentenceIndex += 1
        currentPhraseIndex = 0
    }

    public mutating func previousSentence() {
        guard currentSentenceIndex > 0 else {
            currentPhraseIndex = 0
            return
        }
        currentSentenceIndex -= 1
        currentPhraseIndex = 0
    }

    public mutating func advancePhrase() {
        guard isPlaying, let sentence = currentSentence else { return }
        if currentPhraseIndex < sentence.phrases.count - 1 {
            currentPhraseIndex += 1
        } else if currentSentenceIndex < document.sentences.count - 1 {
            currentSentenceIndex += 1
            currentPhraseIndex = 0
        } else {
            isPlaying = false
        }
    }

    public mutating func updateTiming(_ profile: TimingProfile) {
        timing = profile
    }
}
