import Foundation

public struct SegmentationService: Sendable {
    public init() {}

    public func segment(_ text: String, title: String? = nil, timing: TimingProfile = .standard) -> PromptDocument {
        let sentences = splitSentences(text).map { sentenceText in
            SentenceSegment(
                text: sentenceText,
                phrases: splitPhrases(sentenceText).map { phraseText in
                    var phrase = PhraseSegment(text: phraseText)
                    phrase.estimatedDuration = timing.duration(for: phrase)
                    return phrase
                }
            )
        }
        return PromptDocument(
            title: title ?? defaultTitle(from: text),
            rawText: text,
            sentences: sentences
        )
    }

    public func splitSentences(_ text: String) -> [String] {
        var sentences: [String] = []
        var buffer = ""
        let terminators = CharacterSet(charactersIn: "。！？.!?")

        for scalar in text.unicodeScalars {
            if CharacterSet.newlines.contains(scalar) {
                appendTrimmed(buffer, to: &sentences)
                buffer = ""
                continue
            }

            buffer.unicodeScalars.append(scalar)

            if terminators.contains(scalar) {
                appendTrimmed(buffer, to: &sentences)
                buffer = ""
            }
        }

        appendTrimmed(buffer, to: &sentences)
        return sentences
    }

    public func splitPhrases(_ sentence: String) -> [String] {
        let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 12 else { return [trimmed] }

        var chunks: [String] = []
        var buffer = ""
        let softStops = CharacterSet(charactersIn: "，、,；;：:")

        for scalar in trimmed.unicodeScalars {
            buffer.unicodeScalars.append(scalar)
            if softStops.contains(scalar) {
                appendTrimmed(buffer, to: &chunks)
                buffer = ""
            }
        }
        appendTrimmed(buffer, to: &chunks)

        let connectorSplit = chunks.flatMap(splitLeadingConnector)
        if connectorSplit.count > 1 {
            return connectorSplit
        }
        return splitLongPhrase(trimmed)
    }

    private func splitLeadingConnector(_ text: String) -> [String] {
        let connectors = ["更像一个", "而是", "但是", "所以", "然后", "同时", "接着"]
        for connector in connectors where text.hasPrefix(connector) && text.count > connector.count + 4 {
            let rest = String(text.dropFirst(connector.count))
            return [connector, rest]
        }
        return [text]
    }

    private func splitLongPhrase(_ text: String) -> [String] {
        guard text.count > 24 else { return [text] }
        let targetCount = min(4, max(2, Int(ceil(Double(text.count) / 14.0))))
        let chunkSize = Int(ceil(Double(text.count) / Double(targetCount)))
        var phrases: [String] = []
        var index = text.startIndex

        while index < text.endIndex {
            let end = text.index(index, offsetBy: chunkSize, limitedBy: text.endIndex) ?? text.endIndex
            phrases.append(String(text[index..<end]))
            index = end
        }

        if phrases.count > 4 {
            let tail = phrases.dropFirst(3).joined()
            phrases = Array(phrases.prefix(3)) + [tail]
        }
        return phrases
    }

    private func appendTrimmed(_ text: String, to collection: inout [String]) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            collection.append(trimmed)
        }
    }

    private func defaultTitle(from text: String) -> String {
        let firstLine = text
            .split(whereSeparator: \.isNewline)
            .first
            .map(String.init)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? "Untitled"
        return firstLine.isEmpty ? "Untitled" : String(firstLine.prefix(24))
    }
}
