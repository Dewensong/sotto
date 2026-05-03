import SwiftUI

struct PreparingView: View {
    private let steps = [
        ("1", "识别段落", "智能识别段落结构与语义边界"),
        ("2", "切分句子", "捕捉自然停顿，切分呼吸节点"),
        ("3", "生成短语高亮节奏", "生成聚光节奏，匹配表达重心")
    ]

    var body: some View {
        VStack(spacing: 32) {
            topBar

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

                    HStack(spacing: 8) {
                        Circle().fill(Color.sottoPrimary.opacity(0.9)).frame(width: 10, height: 10)
                        Circle().fill(Color.sottoPrimary.opacity(0.78)).frame(width: 10, height: 10)
                        Circle().fill(Color.sottoPrimary.opacity(0.62)).frame(width: 10, height: 10)
                    }

                    VStack(alignment: .leading, spacing: 34) {
                        ForEach(steps, id: \.0) { step in
                            HStack(spacing: 22) {
                                Text(step.0)
                                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                                    .foregroundStyle(Color.sottoPrimary)
                                    .frame(width: 42, height: 42)
                                    .background(Circle().stroke(Color.sottoPrimary.opacity(step.0 == "1" ? 0.9 : 0.24), lineWidth: 1))
                                    .shadow(color: Color.sottoGlow.opacity(step.0 == "1" ? 0.55 : 0), radius: 14)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(step.1)
                                        .font(.system(size: 22, weight: .medium))
                                        .foregroundStyle(Color.sottoPrimary)
                                    Text(step.2)
                                        .foregroundStyle(Color.sottoMuted)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: 300, alignment: .leading)

                    SottoRhythmLine(amplitude: 1.0, opacity: 0.42)
                        .frame(height: 76)

                    Text("舞台尚未点亮，但每一次呼吸都被听见")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.sottoSecondary)
                }
                .frame(width: 318, height: 620)
            }

            Spacer()
        }
        .padding(.horizontal, 36)
        .padding(.top, 34)
        .padding(.bottom, 28)
    }

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                PixelText(text: "Sotto", size: 34, color: .sottoPrimary, dot: 2.1, spacing: 5.4)
                    .frame(width: 142, height: 42, alignment: .leading)
                Text("a quiet backstage for speaking well")
                    .font(.system(size: 12, weight: .regular))
                    .lineLimit(1)
                    .foregroundStyle(Color.sottoSecondary)
            }
            Spacer()
            SottoStatusBadge(title: "PREP", color: .sottoPrimary)
            Image(systemName: "gearshape")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(Color.sottoSecondary)
                .padding(.leading, 14)
        }
    }
}
