import SwiftUI
import SottoCore

struct SpotlightPreviewView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 12) {
                Text("聚光流预览")
                    .font(.headline)
                    .foregroundStyle(Color.sottoPrimary)
                PromptLinesView(compact: true)
            }

            Spacer()

            controls
        }
        .sottoPanel()
        .onReceive(Timer.publish(every: 1.1, on: .main, in: .common).autoconnect()) { _ in
            model.advancePhrase()
        }
    }

    private var controls: some View {
        VStack(spacing: 10) {
            Button {
                model.togglePlayback()
            } label: {
                Image(systemName: model.session?.isPlaying == true ? "pause.fill" : "play.fill")
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)
            .background(Color.sottoGlow.opacity(0.18))
            .clipShape(Circle())

            HStack {
                Button {
                    model.previousSentence()
                } label: {
                    Image(systemName: "backward.end.fill")
                }
                Button {
                    model.nextSentence()
                } label: {
                    Image(systemName: "forward.end.fill")
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.sottoSecondary)
        }
    }
}

struct PromptLinesView: View {
    @EnvironmentObject private var model: AppModel
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 14) {
            ForEach(displayRows, id: \.offset) { row in
                Text(row.text)
                    .font(font(for: row.offset))
                    .foregroundStyle(color(for: row.offset))
                    .lineLimit(compact ? 1 : 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, row.offset == 0 ? 12 : 0)
                    .padding(.vertical, row.offset == 0 ? 8 : 0)
                    .background(row.offset == 0 ? Color.sottoGlow.opacity(0.16) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private var displayRows: [(offset: Int, text: String)] {
        guard let session = model.session else { return [] }
        let sentences = session.document.sentences
        let current = session.currentSentenceIndex
        let offsets = [-1, 0, 1, 2, 3]

        return offsets.compactMap { offset in
            let index = current + offset
            guard sentences.indices.contains(index) else { return nil }
            if offset == 0 {
                return (offset, highlightedText(for: sentences[index], phraseIndex: session.currentPhraseIndex))
            }
            return (offset, sentences[index].text)
        }
    }

    private func highlightedText(for sentence: SentenceSegment, phraseIndex: Int) -> String {
        guard sentence.phrases.indices.contains(phraseIndex) else { return sentence.text }
        return sentence.phrases.enumerated().map { index, phrase in
            index == phraseIndex ? "「\(phrase.text)」" : phrase.text
        }.joined()
    }

    private func font(for offset: Int) -> Font {
        if offset == 0 {
            return .system(size: compact ? 21 : model.settings.fontSize, weight: .semibold, design: .rounded)
        }
        return .system(size: compact ? 15 : max(20, model.settings.fontSize - 8), weight: .medium, design: .rounded)
    }

    private func color(for offset: Int) -> Color {
        switch offset {
        case 0: .sottoPrimary
        case 1: .sottoSecondary
        case 2: .sottoSecondary.opacity(0.82)
        case 3: .sottoMuted
        default: .sottoMuted.opacity(0.72)
        }
    }
}
