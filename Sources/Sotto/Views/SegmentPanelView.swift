import SwiftUI
import SottoCore

struct SegmentPanelView: View {
    @EnvironmentObject private var model: AppModel
    @State private var pause = "短停顿"
    @State private var emphasis = "普通"

    var body: some View {
        SottoGlassPanel(role: .workbench) {
            VStack(alignment: .leading, spacing: 12) {
                header

                if let sentence = model.selectedSentence {
                    selectedSentence(sentence)
                    phraseSplitter(sentence)
                    pauseControl
                    emphasisControl
                    duration(sentence)
                } else {
                    Text("选择一句稿件后，可以在这里微调短语边界。")
                        .font(SottoFont.pixel(13))
                        .foregroundStyle(Color.sottoMuted)
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: "waveform")
                .font(SottoFont.pixel(24))
                .foregroundStyle(Color.sottoPrimary)
            VStack(alignment: .leading, spacing: 4) {
                Text("短语切分 / 节奏调整")
                    .font(SottoFont.pixel(14))
                    .foregroundStyle(Color.sottoPrimary)
                Text("当前编辑：第 \(String(format: "%02d", (model.selectedSentenceIndex ?? 0) + 1)) 句")
                    .font(SottoFont.pixel(11))
                    .foregroundStyle(Color.sottoMuted)
            }
            Spacer()
            PixelText(text: "SOTTO", size: 14, color: .sottoPrimary, dot: 1.2, spacing: 3.4)
                .frame(width: 62, height: 20)
        }
    }

    private func selectedSentence(_ sentence: SentenceSegment) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("当前选中句子")
                .font(SottoFont.pixel(11))
                .foregroundStyle(Color.sottoMuted)
            Text(sentence.text)
                .font(SottoFont.pixel(18))
                .lineLimit(2)
                .foregroundStyle(Color.sottoPrimary.opacity(0.90))
                .shadow(color: Color.sottoGlow.opacity(0.12), radius: 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: 42, alignment: .leading)
        }
    }

    private func phraseSplitter(_ sentence: SentenceSegment) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("短语切分")
                    .font(SottoFont.pixel(15))
                    .foregroundStyle(Color.sottoPrimary)
                Text("点击切分点")
                    .font(SottoFont.pixel(11))
                    .foregroundStyle(Color.sottoMuted)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(sentence.phrases.enumerated()), id: \.element.id) { index, phrase in
                        Text(phrase.text)
                            .font(SottoFont.pixel(13))
                            .foregroundStyle(Color.sottoPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 10)
                            .frame(minHeight: 42)
                            .background(Color.white.opacity(0.045))
                            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

                        if index < sentence.phrases.count - 1 {
                            splitNode(sentence: sentence, phraseIndex: index)
                        }
                    }
                }
            }
            .padding(12)
            .background(Color.black.opacity(0.20))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.sottoPrimary.opacity(0.12), lineWidth: 1)
            )
        }
    }

    private func splitNode(sentence: SentenceSegment, phraseIndex: Int) -> some View {
        Button {
            let offset = sentence.phrases.prefix(phraseIndex + 1).reduce(0) { $0 + $1.text.count } + 1
            model.toggleSplit(in: sentence, at: offset)
        } label: {
            VStack(spacing: 4) {
                Rectangle()
                    .fill(Color.sottoPrimary)
                    .frame(width: 2, height: 32)
                    .shadow(color: Color.sottoGlow.opacity(0.8), radius: 10)
                Circle()
                    .fill(Color.sottoPrimary)
                    .frame(width: 10, height: 10)
                    .shadow(color: Color.sottoGlow.opacity(0.8), radius: 10)
            }
            .frame(width: 20)
        }
        .buttonStyle(.plain)
    }

    private var pauseControl: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("停顿设置", systemImage: "timer")
                .font(SottoFont.pixel(13))
                .foregroundStyle(Color.sottoPrimary)
            Picker("停顿设置", selection: $pause) {
                Text("无").tag("无")
                Text("短停顿").tag("短停顿")
                Text("长停顿").tag("长停顿")
            }
            .pickerStyle(.segmented)
            .font(SottoFont.pixel(12))
            .tint(Color.sottoPrimary)
        }
    }

    private var emphasisControl: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("强调设置", systemImage: "target")
                .font(SottoFont.pixel(13))
                .foregroundStyle(Color.sottoPrimary)
            Picker("强调设置", selection: $emphasis) {
                Text("普通").tag("普通")
                Text("强调").tag("强调")
            }
            .pickerStyle(.segmented)
            .font(SottoFont.pixel(12))
            .tint(Color.sottoPrimary)
        }
    }

    private func duration(_ sentence: SentenceSegment) -> some View {
        HStack(spacing: 18) {
            Label("当前句预计耗时", systemImage: "clock")
                .font(SottoFont.pixel(12))
                .foregroundStyle(Color.sottoSecondary)
            Text("\(estimatedDuration(sentence), specifier: "%.1f") 秒")
                .font(SottoFont.pixel(18))
                .foregroundStyle(Color.sottoPrimary)
        }
    }

    private func estimatedDuration(_ sentence: SentenceSegment) -> Double {
        sentence.phrases.reduce(0) { $0 + model.timing.duration(for: $1) }
    }
}
