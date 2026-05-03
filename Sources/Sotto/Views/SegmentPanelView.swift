import SwiftUI
import SottoCore

struct SegmentPanelView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("节奏卡")
                .font(.headline)
                .foregroundStyle(Color.sottoPrimary)

            if let sentence = model.selectedSentence {
                Text(sentence.text)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.sottoPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 10) {
                    Text("短语切分")
                        .font(.caption)
                        .foregroundStyle(Color.sottoMuted)

                    FlowLayout(spacing: 8) {
                        ForEach(sentence.phrases) { phrase in
                            Text(phrase.text)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.sottoPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(Color.sottoGlow.opacity(0.13))
                                .clipShape(Capsule())
                        }
                    }
                }

                Divider().overlay(.white.opacity(0.12))

                Text("点击字间位置插入或取消切分点")
                    .font(.caption)
                    .foregroundStyle(Color.sottoMuted)

                FlowLayout(spacing: 5) {
                    let characters = Array(sentence.text)
                    ForEach(characters.indices, id: \.self) { index in
                        HStack(spacing: 4) {
                            Text(String(characters[index]))
                                .foregroundStyle(Color.sottoSecondary)
                            if index < characters.count - 1 {
                                Button {
                                    model.toggleSplit(in: sentence, at: index + 2)
                                } label: {
                                    Circle()
                                        .fill(sentence.manualSplitOffsets.contains(index + 1) ? Color.sottoGlow : Color.white.opacity(0.20))
                                        .frame(width: 7, height: 7)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Spacer()

                Text("预计当前句 \(estimatedDuration(sentence), specifier: "%.1f") 秒")
                    .font(.caption)
                    .foregroundStyle(Color.sottoMuted)
            } else {
                Text("选择一句稿件后，可以在这里微调短语边界。")
                    .foregroundStyle(Color.sottoMuted)
            }
        }
        .sottoPanel()
    }

    private func estimatedDuration(_ sentence: SentenceSegment) -> Double {
        sentence.phrases.reduce(0) { $0 + model.timing.duration(for: $1) }
    }
}
