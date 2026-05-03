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
            var phrase = PhraseSegment(text: sentence.text)
            phrase.estimatedDuration = timing.duration(for: phrase)
            return [phrase]
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
}
