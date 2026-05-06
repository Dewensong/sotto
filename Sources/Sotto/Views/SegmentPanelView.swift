import SwiftUI
import SottoCore

struct SegmentPanelView: View {
    @EnvironmentObject private var model: AppModel
    @State private var pause = "短停顿"
    @State private var emphasis = "普通"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header

            if let sentence = model.selectedSentence {
                VStack(alignment: .leading, spacing: 8) {
                    selectedSentence(sentence)
                    phraseSplitter(sentence)
                    HStack(alignment: .top, spacing: 12) {
                        pauseControl
                        emphasisControl
                        duration(sentence)
                    }
                }
            } else {
                Text("选择一句稿件后，可以在这里微调短语边界。")
                    .font(SottoFont.pixel(13))
                    .foregroundStyle(Color.sottoMuted)
            }
        }
        .sottoEditorPanel(cornerRadius: 16)
    }

    private var header: some View {
        HStack {
            Image(systemName: "waveform")
                .font(SottoFont.pixel(18))
                .foregroundStyle(Color.sottoPrimary)
            VStack(alignment: .leading, spacing: 2) {
                Text("短语切分 / 节奏调整")
                    .font(SottoFont.pixel(13))
                    .foregroundStyle(Color.sottoPrimary)
                Text("当前编辑：第 \(String(format: "%02d", (model.selectedSentenceIndex ?? 0) + 1)) 句")
                    .font(SottoFont.pixel(10))
                    .foregroundStyle(Color.sottoMuted)
            }
            Spacer()
            SottoSignalText(text: "SOTTO", size: 14, color: .sottoPrimary, dot: 1.2, spacing: 3.4)
                .frame(width: 62, height: 20)
        }
    }

    private func selectedSentence(_ sentence: SentenceSegment) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("当前选中句子")
                .font(SottoFont.pixel(10))
                .foregroundStyle(Color.sottoMuted)
            Text(sentence.text)
                .font(SottoFont.pixel(14))
                .lineLimit(2)
                .foregroundStyle(Color.sottoPrimary.opacity(0.90))
                .shadow(color: Color.sottoGlow.opacity(0.10), radius: 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: 30, alignment: .leading)
        }
    }

    private func phraseSplitter(_ sentence: SentenceSegment) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("短语切分")
                    .font(SottoFont.pixel(12))
                    .foregroundStyle(Color.sottoPrimary)
                Text("点击切分点")
                    .font(SottoFont.pixel(10))
                    .foregroundStyle(Color.sottoMuted)
            }

            ZStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(Array(sentence.phrases.enumerated()), id: \.element.id) { index, phrase in
                            Text(phrase.text)
                                .font(SottoFont.pixel(11))
                                .foregroundStyle(Color.sottoPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 7)
                                .frame(minHeight: 32)
                                .background(Color.white.opacity(0.035))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                            if index < sentence.phrases.count - 1 {
                                splitNode(sentence: sentence, phraseIndex: index)
                            }
                        }
                    }
                }

                HStack {
                    SottoProgressiveEdgeFade(edges: .leading, height: 26, strength: 0.42)
                        .frame(width: 28)
                    Spacer()
                    SottoProgressiveEdgeFade(edges: .trailing, height: 26, strength: 0.42)
                        .frame(width: 28)
                }
            }
            .padding(8)
            .background(Color.black.opacity(0.30))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func splitNode(sentence: SentenceSegment, phraseIndex: Int) -> some View {
        SplitNodeView {
            let offset = sentence.phrases.prefix(phraseIndex + 1).reduce(0) { $0 + $1.text.count } + 1
            model.toggleSplit(in: sentence, at: offset)
        }
    }

    private var pauseControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                SottoSemanticIcon(systemName: "timer", trigger: pause, kind: .pause)
                Text("停顿设置")
            }
            .font(SottoFont.pixel(11))
            .foregroundStyle(Color.sottoPrimary)
            Picker("停顿设置", selection: $pause) {
                Text("无").tag("无")
                Text("短停顿").tag("短停顿")
                Text("长停顿").tag("长停顿")
            }
            .pickerStyle(.segmented)
            .font(SottoFont.pixel(10))
            .tint(Color.sottoPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emphasisControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                SottoSemanticIcon(systemName: "target", trigger: emphasis, kind: .emphasis)
                Text("强调设置")
            }
            .font(SottoFont.pixel(11))
            .foregroundStyle(Color.sottoPrimary)
            Picker("强调设置", selection: $emphasis) {
                Text("普通").tag("普通")
                Text("强调").tag("强调")
            }
            .pickerStyle(.segmented)
            .font(SottoFont.pixel(10))
            .tint(Color.sottoPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func duration(_ sentence: SentenceSegment) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("预计耗时", systemImage: "clock")
                .font(SottoFont.pixel(11))
                .foregroundStyle(Color.sottoMuted)
            Text("\(estimatedDuration(sentence), specifier: "%.1f") 秒")
                .font(SottoFont.pixel(16))
                .foregroundStyle(Color.sottoPrimary)
        }
        .frame(width: 112, alignment: .leading)
    }

    private func estimatedDuration(_ sentence: SentenceSegment) -> Double {
        sentence.phrases.reduce(0) { $0 + model.timing.duration(for: $1) }
    }
}

private struct SplitNodeView: View {
    let action: () -> Void
    @State private var hovering = false
    @State private var pulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            action()
            guard !reduceMotion else { return }
            withAnimation(SottoMotionTokens.confirm) {
                pulse = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
                withAnimation(SottoMotionTokens.confirm) {
                    pulse = false
                }
            }
        } label: {
            ZStack {
                Circle()
                    .stroke(Color.sottoGlow.opacity(pulse ? 0.55 : 0), lineWidth: 1)
                    .frame(width: pulse ? 26 : 8, height: pulse ? 26 : 8)
                    .opacity(pulse ? 1 : 0)

                VStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.sottoPrimary.opacity(hovering ? 0.95 : 0.76))
                        .frame(width: hovering ? 3 : 2, height: 24)
                        .shadow(color: Color.sottoGlow.opacity(hovering || pulse ? 0.75 : 0.42), radius: hovering ? 10 : 7)
                    Circle()
                        .fill(Color.sottoPrimary)
                        .frame(width: hovering ? 10 : 8, height: hovering ? 10 : 8)
                        .shadow(color: Color.sottoGlow.opacity(hovering || pulse ? 0.78 : 0.48), radius: hovering ? 10 : 7)
                }
            }
            .frame(width: 18)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(SottoMotionTokens.hover, value: hovering)
    }
}
