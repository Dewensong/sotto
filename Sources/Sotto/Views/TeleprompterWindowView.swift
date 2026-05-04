import SwiftUI
import SottoCore

struct TeleprompterWindowView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        PromptCardLayout(fullWindow: true)
            .frame(width: model.settings.width)
            .frame(height: 430)
            .onReceive(Timer.publish(every: 1.1, on: .main, in: .common).autoconnect()) { _ in
                model.advancePhrase()
            }
    }
}

struct PromptCardLayout: View {
    @EnvironmentObject private var model: AppModel
    var fullWindow = false

    var body: some View {
        SottoGlassPanel(role: .prompt) {
            VStack(spacing: 18) {
                HStack(spacing: 26) {
                    promptSidebar
                        .frame(width: fullWindow ? 150 : 94)

                    Divider()
                        .overlay(Color.sottoPrimary.opacity(0.20))

                    readingArea
                }

                SottoRhythmLine(amplitude: fullWindow ? 0.75 : 0.42, opacity: fullWindow ? 0.42 : 0.26)
                    .frame(height: fullWindow ? 34 : 20)

                if fullWindow {
                    controls
                }
            }
        }
    }

    private var promptSidebar: some View {
        VStack(alignment: .leading, spacing: 20) {
            PixelText(text: "SOTTO\nPROMPT", size: fullWindow ? 16 : 11, color: .sottoPrimary, dot: 1.6, spacing: 4, tracking: 2)
                .frame(width: fullWindow ? 108 : 72, height: fullWindow ? 62 : 44, alignment: .leading)

            Circle()
                .fill(Color.sottoGreen)
                .frame(width: 10, height: 10)
                .shadow(color: Color.sottoGreen.opacity(0.8), radius: 8)

            Spacer(minLength: 24)

            VStack(alignment: .leading, spacing: 8) {
                Text("• REC")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .tracking(1.5)
                Text("01:24")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
            }
            .foregroundStyle(Color.sottoSecondary)

            Spacer(minLength: 12)

            VStack(alignment: .leading, spacing: 8) {
                Text(progressText)
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                Rectangle()
                    .fill(Color.sottoPrimary.opacity(0.82))
                    .frame(width: 38, height: 3)
                Rectangle()
                    .fill(Color.sottoPrimary.opacity(0.22))
                    .frame(width: 70, height: 1)
                    .offset(y: -10)
            }
            .foregroundStyle(Color.sottoSecondary)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var readingArea: some View {
        ZStack {
            LinearGradient(
                colors: [.clear, Color.sottoGlow.opacity(0.25), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: fullWindow ? 72 : 42)
            .blur(radius: 10)
            .offset(y: fullWindow ? -58 : -38)

            VStack(alignment: .leading, spacing: fullWindow ? 24 : 12) {
                if fullWindow, let previous = row(offset: -1) {
                    promptText(previous, size: 22, color: Color.sottoSecondary.opacity(0.68), weight: .regular, lineLimit: 1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: fullWindow ? 42 : 26, alignment: .leading)
                }

                if let current = currentSentenceText {
                    promptText(
                        current,
                        size: fullWindow ? 32 : 22,
                        color: .sottoPrimary,
                        weight: .semibold,
                        lineLimit: fullWindow ? 3 : 2
                    )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: fullWindow ? 112 : 42, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: fullWindow ? 18 : 8) {
                    ForEach(fullWindow ? [1, 2, 3] : [1, 2], id: \.self) { offset in
                        if let text = row(offset: offset) {
                            promptText(
                                text,
                                size: fullWindow ? max(16, 22 - CGFloat(offset * 2)) : 15,
                                color: Color.sottoSecondary.opacity(0.68 - Double(offset) * 0.10),
                                weight: .regular,
                                lineLimit: 1
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(height: fullWindow ? 30 : 22, alignment: .leading)
                        }
                    }
                }
            }
        }
    }

    private func promptText(
        _ text: String,
        size: CGFloat,
        color: Color,
        weight: Font.Weight,
        lineLimit: Int
    ) -> some View {
        Text(text)
            .font(.system(size: size, weight: weight, design: .rounded))
            .lineSpacing(size * 0.18)
            .lineLimit(lineLimit)
            .foregroundStyle(color)
            .shadow(color: Color.sottoGlow.opacity(weight == .semibold ? 0.26 : 0.10), radius: weight == .semibold ? 12 : 6)
    }

    private var controls: some View {
        HStack(spacing: fullWindow ? 26 : 14) {
            SottoIconButton(systemName: "backward.end.fill") { model.previousSentence() }
            divider
            SottoIconButton(systemName: model.session?.isPlaying == true ? "pause.fill" : "play.fill") { model.togglePlayback() }
            divider
            SottoIconButton(systemName: "forward.end.fill") { model.nextSentence() }
            divider
            Button("−") { stepTiming(-1) }
                .buttonStyle(.plain)
                .font(.system(size: 24, weight: .light, design: .monospaced))
                .foregroundStyle(Color.sottoPrimary.opacity(0.82))
            Text(speedText)
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .tracking(2)
                .foregroundStyle(Color.sottoSecondary)
            Button("+") { stepTiming(1) }
                .buttonStyle(.plain)
                .font(.system(size: 22, weight: .light, design: .monospaced))
                .foregroundStyle(Color.sottoPrimary.opacity(0.82))
            divider
            Button("EXIT") { model.closeTeleprompter() }
                .buttonStyle(.plain)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .tracking(4)
                .foregroundStyle(Color.sottoSecondary)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.sottoPrimary.opacity(0.22))
            .frame(width: 1, height: 30)
    }

    private var currentSentenceText: String? {
        model.session?.currentSentence?.text
    }

    private var progressText: String {
        guard let session = model.session else { return "00 / 00" }
        return "\(String(format: "%02d", session.currentSentenceIndex + 1)) / \(String(format: "%02d", session.document.sentences.count))"
    }

    private var speedText: String {
        switch model.timing {
        case .relaxed: "0.8x"
        case .standard: "0.9x"
        case .compact: "1.1x"
        }
    }

    private func row(offset: Int) -> String? {
        guard let session = model.session else { return nil }
        let index = session.currentSentenceIndex + offset
        guard session.document.sentences.indices.contains(index) else { return nil }
        return session.document.sentences[index].text
    }

    private func stepTiming(_ direction: Int) {
        let cases = TimingProfile.allCases
        guard let current = cases.firstIndex(of: model.timing) else { return }
        let next = min(max(current + direction, 0), cases.count - 1)
        model.setTiming(cases[next])
    }
}
