import SwiftUI
import SottoCore

struct HomeView: View {
    @EnvironmentObject private var model: AppModel
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            topBar
            heroCopy
            materialStage
            recentDocuments
            Text("专注表达，聚光成句。")
                .font(SottoFont.pixel(13))
                .tracking(3)
                .foregroundStyle(Color.sottoSecondary)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    private var topBar: some View {
        HStack(alignment: .top) {
            HStack(spacing: 10) {
                PixelTeleprompterIcon()
                    .frame(width: 46, height: 40)
                VStack(alignment: .leading, spacing: 3) {
                    PixelText(text: "Sotto", size: 28, color: .sottoPrimary, dot: 1.7, spacing: 4.6)
                        .frame(width: 116, height: 34, alignment: .leading)
                    Text("a quiet backstage for speaking well")
                        .font(SottoFont.pixel(10))
                        .foregroundStyle(Color.sottoSecondary)
                }
            }

            Spacer()

            HStack(spacing: 28) {
                SottoStatusBadge(title: "READY.")
                    .scaleEffect(0.74, anchor: .trailing)
                Image(systemName: "gearshape")
                    .font(SottoFont.pixel(22))
                    .foregroundStyle(Color.sottoSecondary)
            }
            .padding(.top, 10)
        }
    }

    private var heroCopy: some View {
        VStack(spacing: 10) {
            PixelText(
                text: "今天想让哪段想法上场？",
                size: 22,
                weight: .regular,
                color: .sottoPrimary,
                dot: 1.45,
                spacing: 4.4,
                tracking: 2
            )
            .frame(maxWidth: 360, minHeight: 34)

            Text("把已经写好的稿子放进来，我会帮你整理成适合口播的提词节奏。")
                .font(SottoFont.pixel(12))
                .foregroundStyle(Color.sottoSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 12)
    }

    private var materialStage: some View {
        SottoGlassPanel(role: .hero) {
            VStack(spacing: 24) {
                if model.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isInputFocused {
                    VStack(spacing: 10) {
                        PixelDocumentIcon()
                            .frame(width: 50, height: 54)
                            .shadow(color: Color.sottoGlow.opacity(0.7), radius: 18)
                        Text("粘贴已有口播稿 / Notion 文稿 / AI 对话整理稿")
                            .font(SottoFont.pixel(14))
                            .foregroundStyle(Color.sottoPrimary)
                        Text("支持大段文本粘贴，自动切分句子与节奏。")
                            .font(SottoFont.pixel(11))
                            .foregroundStyle(Color.sottoSecondary)
                    }
                    .frame(height: 92)
                    .onTapGesture {
                        isInputFocused = true
                    }
                }

                TextEditor(text: $model.inputText)
                    .focused($isInputFocused)
                    .font(SottoFont.pixel(15))
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(Color.sottoPrimary)
                    .padding(16)
                    .frame(height: model.inputText.isEmpty && !isInputFocused ? 0 : 118)
                    .opacity(model.inputText.isEmpty && !isInputFocused ? 0 : 1)
                    .background(Color.black.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                capabilityRow

                SottoRhythmLine(amplitude: 0.8, opacity: 0.44)
                    .frame(height: 28)
                    .padding(.horizontal, 20)

                Button {
                    model.createDocumentFromInput()
                } label: {
                    HStack(spacing: 14) {
                        DotField(spacing: 5, dotSize: 1.7, opacity: 0.54)
                            .frame(width: 42, height: 28)
                        VStack(spacing: 2) {
                            Text("ON STAGE")
                                .font(SottoFont.pixel(18))
                                .tracking(2)
                            Text("准备上场")
                                .font(SottoFont.pixel(11))
                                .tracking(4)
                        }
                        DotField(spacing: 5, dotSize: 1.7, opacity: 0.54)
                            .frame(width: 42, height: 28)
                    }
                    .foregroundStyle(Color.sottoPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.sottoGlow.opacity(0.11))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.sottoPrimary.opacity(0.72), lineWidth: 1.2)
                    )
                    .shadow(color: Color.sottoGlow.opacity(0.55), radius: 20)
                }
                .buttonStyle(.plain)
                .disabled(model.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(model.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var capabilityRow: some View {
        HStack(spacing: 12) {
            CapabilityItem(icon: "square.grid.3x3", title: "段落识别")
            CapabilityItem(icon: "scissors", title: "短语切分")
            CapabilityItem(icon: "rectangle.split.3x1", title: "停顿建议")
            CapabilityItem(icon: "sun.max", title: "聚光预览")
        }
        .foregroundStyle(Color.sottoSecondary)
        .padding(.top, 2)
    }

    private var recentDocuments: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("✶")
                    .foregroundStyle(Color.sottoPrimary)
                Text("最近稿件")
                    .font(SottoFont.pixel(16))
                    .foregroundStyle(Color.sottoPrimary)
                Spacer()
            }

            SottoGlassPanel(role: .utility) {
                VStack(spacing: 0) {
                    if model.recentDocuments.isEmpty {
                        Text("最近准备过的提词稿会出现在这里。")
                            .font(SottoFont.pixel(12))
                            .foregroundStyle(Color.sottoMuted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 22)
                    } else {
                        ForEach(Array(model.recentDocuments.prefix(1).enumerated()), id: \.element.id) { index, document in
                            RecentDocumentRow(document: document, index: index) {
                                model.open(document)
                            }
                            if document.id != model.recentDocuments.prefix(1).last?.id {
                                Divider().overlay(Color.sottoPrimary.opacity(0.10))
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct CapabilityItem: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(SottoFont.pixel(13))
            Text(title)
                .font(SottoFont.pixel(11))
        }
    }
}

private struct RecentDocumentRow: View {
    let document: PromptDocument
    let index: Int
    let action: () -> Void

    private var initials: String {
        let letters = ["T", "N", "C"]
        return letters[index % letters.count]
    }

    private var status: (String, Color) {
        switch index % 3 {
        case 0: ("待持续", .yellow)
        case 1: ("已切分", .cyan)
        default: ("润词中", .green)
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                PixelText(text: initials, size: 24, color: index == 2 ? .sottoGreen : .sottoPrimary, dot: 1.8, spacing: 4)
                    .frame(width: 38, height: 42)

                VStack(alignment: .leading, spacing: 8) {
                    Text(document.title)
                        .font(SottoFont.pixel(15))
                        .foregroundStyle(Color.sottoPrimary)
                        .lineLimit(1)
                    Text("最后编辑  \(document.updatedAt.formatted(date: .omitted, time: .shortened))")
                        .font(SottoFont.pixel(11))
                        .foregroundStyle(Color.sottoMuted)
                }

                Spacer()

                HStack(spacing: 8) {
                    Circle().fill(status.1).frame(width: 8, height: 8)
                    Text(status.0)
                        .font(SottoFont.pixel(12))
                }
                .foregroundStyle(status.1)

                Image(systemName: "ellipsis")
                    .foregroundStyle(Color.sottoSecondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
        }
        .buttonStyle(.plain)
    }
}

private struct PixelTeleprompterIcon: View {
    var body: some View {
        Canvas { context, _ in
            let color = Color.sottoPrimary
            for y in 0..<7 {
                for x in 0..<9 where y == 0 || y == 6 || x == 0 || x == 8 || (y == 2 && x > 1 && x < 7) || (y == 4 && x > 1 && x < 7) {
                    context.fill(Path(ellipseIn: CGRect(x: x * 8, y: y * 8, width: 4, height: 4)), with: .color(color))
                }
            }
            var stand = Path()
            stand.move(to: CGPoint(x: 36, y: 58))
            stand.addLine(to: CGPoint(x: 24, y: 68))
            stand.move(to: CGPoint(x: 36, y: 58))
            stand.addLine(to: CGPoint(x: 48, y: 68))
            context.stroke(stand, with: .color(color.opacity(0.8)), lineWidth: 2)
        }
    }
}

private struct PixelDocumentIcon: View {
    var body: some View {
        PixelText(text: "▤", size: 66, color: .sottoPrimary, dot: 2.6, spacing: 6)
    }
}
