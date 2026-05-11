import Foundation

public enum PromptTextFitEstimator {
    public static func estimatedLineCount(text: String, fontSize: Double, containerWidth: Double) -> Int {
        guard containerWidth > 0, !text.isEmpty else { return 0 }
        let width = estimatedTextWidth(text, fontSize: fontSize)
        return max(1, Int(ceil(width / containerWidth)))
    }

    public static func fittedFontSize(
        text: String,
        requestedSize: Double,
        minimumSize: Double,
        containerWidth: Double,
        targetLines: Int
    ) -> Double {
        guard targetLines > 0, containerWidth > 0 else { return requestedSize }
        var size = requestedSize
        while size > minimumSize {
            if estimatedLineCount(text: text, fontSize: size, containerWidth: containerWidth) <= targetLines {
                return size
            }
            size -= 1
        }
        return minimumSize
    }

    private static func estimatedTextWidth(_ text: String, fontSize: Double) -> Double {
        text.reduce(0) { partial, character in
            partial + characterWidthFactor(character) * fontSize
        }
    }

    private static func characterWidthFactor(_ character: Character) -> Double {
        if character.isWhitespace { return 0.34 }
        if character.isASCIIAlphanumeric { return 0.58 }
        if character.isASCIIPunctuation { return 0.42 }
        return 0.96
    }
}

private extension Character {
    var isWhitespace: Bool {
        unicodeScalars.allSatisfy { CharacterSet.whitespacesAndNewlines.contains($0) }
    }

    var isASCIIAlphanumeric: Bool {
        unicodeScalars.allSatisfy {
            $0.value < 128 && (CharacterSet.letters.contains($0) || CharacterSet.decimalDigits.contains($0))
        }
    }

    var isASCIIPunctuation: Bool {
        unicodeScalars.allSatisfy {
            $0.value < 128 && CharacterSet.punctuationCharacters.contains($0)
        }
    }
}
