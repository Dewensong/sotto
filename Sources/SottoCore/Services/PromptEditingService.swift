import Foundation

public enum PromptEditingService {
    public static func toggleSplit(at characterOffset: Int, in sentence: inout SentenceSegment, timing: TimingProfile) {
        guard characterOffset > 1, characterOffset < sentence.text.count else { return }
        let splitOffset = characterOffset - 1

        if sentence.manualSplitOffsets.contains(splitOffset) {
            sentence.manualSplitOffsets.remove(splitOffset)
        } else {
            sentence.manualSplitOffsets.insert(splitOffset)
        }

        sentence.phrases = rebuildPhrases(for: sentence, timing: timing)
    }

    public static func rebuildPhrases(for sentence: SentenceSegment, timing: TimingProfile) -> [PhraseSegment] {
        let sortedOffsets = sentence.manualSplitOffsets.sorted()
        guard !sortedOffsets.isEmpty else {
            return phrases(for: sentence.text, timing: timing)
        }

        var phrases: [PhraseSegment] = []
        var start = sentence.text.startIndex

        for offset in sortedOffsets where offset > 0 && offset < sentence.text.count {
            let end = sentence.text.index(sentence.text.startIndex, offsetBy: offset)
            let text = String(sentence.text[start..<end])
            var phrase = PhraseSegment(text: text)
            phrase.estimatedDuration = timing.duration(for: phrase)
            phrases.append(phrase)
            start = end
        }

        let tail = String(sentence.text[start..<sentence.text.endIndex])
        if !tail.isEmpty {
            var phrase = PhraseSegment(text: tail)
            phrase.estimatedDuration = timing.duration(for: phrase)
            phrases.append(phrase)
        }

        return phrases
    }

    public static func splitSentence(_ sentence: SentenceSegment, at characterOffset: Int, timing: TimingProfile) -> [SentenceSegment]? {
        guard characterOffset > 0, characterOffset < sentence.text.count else { return nil }
        let splitIndex = sentence.text.index(sentence.text.startIndex, offsetBy: characterOffset)
        let firstText = String(sentence.text[..<splitIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
        let secondText = String(sentence.text[splitIndex...]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !firstText.isEmpty, !secondText.isEmpty else { return nil }

        return [
            sentenceWithText(firstText, pause: sentence.pause, emphasis: sentence.emphasis, timing: timing),
            sentenceWithText(secondText, pause: .normal, emphasis: .normal, timing: timing)
        ]
    }

    public static func mergeSentences(_ first: SentenceSegment, _ second: SentenceSegment, timing: TimingProfile) -> SentenceSegment {
        sentenceWithText(
            first.text + second.text,
            pause: first.pause,
            emphasis: first.emphasis,
            timing: timing
        )
    }

    public static func updateSentenceText(_ sentence: SentenceSegment, text: String, timing: TimingProfile) -> SentenceSegment? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        var updated = sentence
        updated.text = trimmed
        updated.manualSplitOffsets = []
        updated.phrases = phrases(for: trimmed, timing: timing)
        return updated
    }

    public static func rawText(from sentences: [SentenceSegment]) -> String {
        sentences.map(\.text).joined(separator: "\n")
    }

    private static func sentenceWithText(
        _ text: String,
        pause: PauseLevel,
        emphasis: EmphasisLevel,
        timing: TimingProfile
    ) -> SentenceSegment {
        SentenceSegment(
            text: text,
            phrases: phrases(for: text, timing: timing),
            pause: pause,
            emphasis: emphasis
        )
    }

    private static let segmenter = SegmentationService()

    private static func phrases(for text: String, timing: TimingProfile) -> [PhraseSegment] {
        segmenter.splitPhrases(text).map { phraseText in
            var phrase = PhraseSegment(text: phraseText)
            phrase.estimatedDuration = timing.duration(for: phrase)
            return phrase
        }
    }
}
