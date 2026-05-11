import SwiftUI

struct PreparingView: View {
    @State private var visibleSteps = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var model: AppModel

    private let steps = [
        ("1", "识别段落", "智能识别段落结构与语义边界"),
        ("2", "切分句子", "捕捉自然停顿，切分呼吸节点"),
        ("3", "生成短语高亮节奏", "生成聚光节奏，匹配表达重心")
    ]

    var body: some View {
        VStack(spacing: 32) {
            topBar
                .sottoEntrance()

            Spacer(minLength: 10)

            SottoGlassPanel(role: .hero) {
                VStack(spacing: 46) {
                    PixelText(
                        text: "正在整理稿件\n提词节奏",
                        size: 22,
                        color: .sottoPrimary,
                        dot: 1.45,
                        spacing: 4.4
                    )
                    .frame(maxWidth: 292, minHeight: 68)
                    .sottoEntrance(delay: 0.04)

                    PreparingDots()

                    VStack(alignment: .leading, spacing: 34) {
                        ForEach(Array(steps.enumerated()), id: \.element.0) { index, step in
                            HStack(spacing: 22) {
                                Text(step.0)
                                    .font(SottoFont.pixel(18))
                                    .foregroundStyle(index < visibleSteps ? Color.sottoPrimary : Color.sottoMuted)
                                    .frame(width: 42, height: 42)
                                    .background(Circle().stroke(Color.sottoPrimary.opacity(index < visibleSteps ? 0.82 : 0.20), lineWidth: 1))
                                    .shadow(color: Color.sottoGlow.opacity(index == visibleSteps - 1 ? 0.55 : 0), radius: 14)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(step.1)
                                        .font(SottoFont.pixel(22))
                                        .foregroundStyle(index < visibleSteps ? Color.sottoPrimary : Color.sottoSecondary.opacity(0.55))
                                    Text(step.2)
                                        .font(SottoFont.pixel(14))
                                        .foregroundStyle(Color.sottoMuted)
                                }
                            }
                            .opacity(index < visibleSteps ? 1 : 0.36)
                            .offset(y: index < visibleSteps || reduceMotion ? 0 : 8)
                            .animation(.easeOut(duration: reduceMotion ? 0.01 : 0.24), value: visibleSteps)
                        }
                    }
                    .frame(maxWidth: 300, alignment: .leading)

                    SottoRhythmLine(amplitude: 1.0, opacity: 0.42, animated: !reduceMotion)
                        .frame(height: 76)

                    Text("舞台尚未点亮，但每一次呼吸都被听见")
                        .font(SottoFont.pixel(15))
                        .foregroundStyle(Color.sottoSecondary)
                }
                .frame(width: 318, height: 620)
            }

            Spacer()
        }
        .padding(.horizontal, 36)
        .padding(.top, 34)
        .padding(.bottom, 28)
        .onAppear(perform: revealSteps)
    }

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                SottoSignalText(text: "Sotto", size: 34, color: .sottoPrimary, dot: 2.1, spacing: 5.4)
                    .frame(width: 142, height: 42, alignment: .leading)
                Text("a quiet backstage for speaking well")
                    .font(SottoFont.pixel(12))
                    .lineLimit(1)
                    .foregroundStyle(Color.sottoSecondary)
            }
            Spacer()
            SottoStatusBadge(title: "PREP", color: .sottoPrimary)
            Button {
                model.showSettingsPanel.toggle()
            } label: {
                Image(systemName: "gearshape")
                    .font(SottoFont.pixel(26))
                    .foregroundStyle(Color.sottoSecondary)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .padding(.leading, 14)
        }
    }

    private func revealSteps() {
        visibleSteps = reduceMotion ? steps.count : 0
        guard !reduceMotion else { return }
        for index in 1...steps.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index - 1) * 0.18) {
                visibleSteps = index
            }
        }
    }
}

private struct PreparingDots: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    let pulse = 0.62 + 0.38 * sin(time * .pi / 1.2 + Double(index) * 0.55)
                    Circle()
                        .fill(Color.sottoPrimary.opacity(0.58 + 0.32 * pulse))
                        .frame(width: 10, height: 10)
                        .shadow(color: Color.sottoGlow.opacity(0.28 * pulse), radius: 6)
                }
            }
        }
    }
}
