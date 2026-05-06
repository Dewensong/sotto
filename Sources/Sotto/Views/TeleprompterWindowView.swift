import SwiftUI
import SottoCore

struct TeleprompterWindowView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        PromptCardLayout(fullWindow: true)
            .frame(width: model.settings.width)
            .frame(height: 460)
            .onReceive(Timer.publish(every: 1 / 30, on: .main, in: .common).autoconnect()) { date in
                model.tickPlayback(now: date)
            }
    }
}

struct PromptCardLayout: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPromptHovering = false
    var fullWindow = false

    var body: some View {
        if fullWindow {
            SottoGlassPanel(role: .prompt) {
                promptContent
            }
            .opacity(model.settings.opacity)
            .onHover { isPromptHovering = $0 }
            .animation(.easeOut(duration: SottoMotionTokens.duration(0.18, reduceMotion: reduceMotion)), value: isPromptHovering)
        } else {
            promptContent
                .padding(12)
                .background(Color.black.opacity(0.28))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var promptContent: some View {
        VStack(spacing: fullWindow ? 14 : 10) {
            HStack(spacing: fullWindow ? 26 : 16) {
                promptSidebar
                    .frame(width: fullWindow ? 150 : 82)

                Divider()
                    .overlay(Color.sottoPrimary.opacity(fullWindow ? 0.20 : 0.10))

                readingArea
            }

            SottoRhythmLine(amplitude: fullWindow ? 0.75 : 0.36, opacity: fullWindow ? 0.42 : 0.20, animated: !reduceMotion)
                .frame(height: fullWindow ? 34 : 16)

            if fullWindow {
                controls
                    .opacity(isPromptHovering ? 1 : 0.36)
                    .offset(y: isPromptHovering || reduceMotion ? 0 : 4)
                    .animation(.easeOut(duration: SottoMotionTokens.duration(0.18, reduceMotion: reduceMotion)), value: isPromptHovering)
            }
        }
    }

    private var promptSidebar: some View {
        VStack(alignment: .leading, spacing: 20) {
            SottoSignalText(text: "SOTTO\nPROMPT", size: fullWindow ? 16 : 11, color: .sottoPrimary, dot: 1.6, spacing: 4, tracking: 2)
                .frame(width: fullWindow ? 108 : 72, height: fullWindow ? 62 : 44, alignment: .leading)

            Circle()
                .fill(Color.sottoGreen)
                .frame(width: 10, height: 10)
                .shadow(color: Color.sottoGreen.opacity(0.8), radius: 8)

            Spacer(minLength: 24)

            VStack(alignment: .leading, spacing: 8) {
                Text("• REC")
                    .font(SottoFont.pixel(13))
                    .tracking(1.5)
                Text("01:24")
                    .font(SottoFont.pixel(16))
            }
            .foregroundStyle(Color.sottoSecondary)

            Spacer(minLength: 12)

            VStack(alignment: .leading, spacing: 8) {
                Text(progressText)
                    .font(SottoFont.pixel(16))
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

            VStack(alignment: .leading, spacing: fullWindow ? 18 : 12) {
                if fullWindow, let previous = row(offset: -1) {
                    promptText(previous, size: 22, color: Color.sottoSecondary.opacity(0.68), weight: .regular, lineLimit: 1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: fullWindow ? 42 : 26, alignment: .leading)
                        .id("previous-\(previous)")
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                if currentSentenceText != nil {
                    highlightedCurrentSentence(size: currentSentenceSize, lineLimit: fullWindow ? 3 : 2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: fullWindow ? 148 : 80, alignment: .leading)
                        .id(currentSentenceID)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                VStack(alignment: .leading, spacing: fullWindow ? 13 : 8) {
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
                            .frame(height: fullWindow ? 30 : 34, alignment: .leading)
                            .id("future-\(offset)-\(text)")
                            .transition(.opacity)
                        }
                    }
                }
            }
            .animation(.easeInOut(duration: SottoMotionTokens.duration(0.34, reduceMotion: reduceMotion)), value: model.session?.currentSentenceIndex)
            .animation(.linear(duration: SottoMotionTokens.duration(0.08, reduceMotion: reduceMotion)), value: model.phraseProgress)

            SottoProgressiveEdgeFade(
                edges: [.top, .bottom],
                height: fullWindow ? 28 : 18,
                strength: fullWindow ? 0.46 : 0.24
            )
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
            .font(SottoFont.pixel(size))
            .lineSpacing(size * 0.18)
            .lineLimit(lineLimit)
            .foregroundStyle(color)
            .shadow(color: Color.sottoGlow.opacity(weight == .semibold ? 0.26 : 0.10), radius: weight == .semibold ? 12 : 6)
    }

    private var controls: some View {
        VStack(spacing: 7) {
            HStack(spacing: 10) {
                SottoIconButton(systemName: "backward.end.fill") { model.previousSentence() }
                SottoIconButton(systemName: model.session?.isPlaying == true ? "pause.fill" : "play.fill") { model.togglePlayback() }
                SottoIconButton(systemName: "forward.end.fill") { model.nextSentence() }
                divider
                controlStepper(label: speedText, minus: { stepTiming(-1) }, plus: { stepTiming(1) })
                divider
                Button("EXIT") { model.closeTeleprompter() }
                    .buttonStyle(.plain)
                    .font(SottoFont.pixel(13))
                    .tracking(4)
                    .foregroundStyle(Color.sottoSecondary)
                    .frame(minWidth: 58, minHeight: 30)
            }

            HStack(spacing: 10) {
                controlStepper(label: "\(Int(model.settings.fontSize))", minus: { model.adjustFontSize(-2) }, plus: { model.adjustFontSize(2) }, prefix: "A")
                divider
                controlStepper(label: "\(Int(model.settings.opacity * 100))%", minus: { model.adjustOpacity(-0.08) }, plus: { model.adjustOpacity(0.08) }, prefix: "α")
                divider
                controlStepper(label: "\(Int(model.settings.width))", minus: { model.adjustPromptWidth(-60) }, plus: { model.adjustPromptWidth(60) }, prefix: "W")
            }
            .opacity(0.78)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.sottoPrimary.opacity(0.22))
            .frame(width: 1, height: 30)
    }

    private func controlStepper(
        label: String,
        minus: @escaping () -> Void,
        plus: @escaping () -> Void,
        prefix: String? = nil
    ) -> some View {
        HStack(spacing: 8) {
            Button("−", action: minus)
                .buttonStyle(.plain)
                .font(SottoFont.pixel(20))
            Text(prefix.map { "\($0) \(label)" } ?? label)
                .font(SottoFont.pixel(13))
                .tracking(1.4)
                .foregroundStyle(Color.sottoSecondary)
                .frame(minWidth: prefix == nil ? 42 : 50)
            Button("+", action: plus)
                .buttonStyle(.plain)
                .font(SottoFont.pixel(18))
        }
        .foregroundStyle(Color.sottoPrimary.opacity(0.82))
    }

    private var currentSentenceText: String? {
        model.session?.currentSentence?.text
    }

    private var currentSentenceSize: CGFloat {
        guard fullWindow else { return 22 }
        let requested = CGFloat(model.settings.fontSize)
        let count = CGFloat(currentSentenceText?.filter { !$0.isWhitespace }.count ?? 0)
        if count > 58 { return min(requested, 26) }
        if count > 44 { return min(requested, 30) }
        if count > 34 { return min(requested, 34) }
        return min(requested, 42)
    }

    private var currentSentenceID: String {
        model.session?.currentSentence?.id.uuidString ?? "empty"
    }

    private func highlightedCurrentSentence(size: CGFloat, lineLimit: Int) -> some View {
        guard let session = model.session, let sentence = session.currentSentence else {
            return AnyView(EmptyView())
        }
        return AnyView(
            CurrentSentenceSweepView(
                sentence: sentence,
                currentPhraseIndex: session.currentPhraseIndex,
                progress: model.phraseProgress,
                size: size,
                lineLimit: lineLimit
            )
        )
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

private struct CurrentSentenceSweepView: View {
    let sentence: SentenceSegment
    let currentPhraseIndex: Int
    let progress: Double
    let size: CGFloat
    let lineLimit: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        FlowLayout(spacing: 0) {
            ForEach(Array(sentence.phrases.enumerated()), id: \.element.id) { index, phrase in
                PhraseSweepView(
                    text: phrase.text,
                    state: state(for: index),
                    progress: progress,
                    size: size,
                    lineLimit: lineLimit
                )
            }
        }
        .lineSpacing(size * 0.18)
        .shadow(color: Color.sottoGlow.opacity(0.28), radius: 12)
        .animation(.linear(duration: SottoMotionTokens.duration(0.08, reduceMotion: reduceMotion)), value: progress)
        .animation(.easeOut(duration: SottoMotionTokens.duration(0.24, reduceMotion: reduceMotion)), value: currentPhraseIndex)
    }

    private func state(for index: Int) -> PhraseSweepView.StateKind {
        if index < currentPhraseIndex { return .past }
        if index == currentPhraseIndex { return .current }
        return .future
    }
}

private struct PhraseSweepView: View {
    enum StateKind {
        case past
        case current
        case future
    }

    let text: String
    let state: StateKind
    let progress: Double
    let size: CGFloat
    let lineLimit: Int

    var body: some View {
        Text(text)
            .font(SottoFont.pixel(size))
            .lineLimit(lineLimit)
            .foregroundStyle(textColor)
            .padding(.horizontal, state == .current ? 5 : 0)
            .padding(.vertical, state == .current ? 4 : 0)
            .background {
                if state == .current {
                    PhraseGlow(progress: progress)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var textColor: Color {
        switch state {
        case .past:
            Color.sottoPrimary.opacity(0.94)
        case .current:
            Color.sottoPrimary
        case .future:
            Color.sottoPrimary.opacity(0.62)
        }
    }
}

private struct PhraseGlow: View {
    let progress: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1)
            let bandWidth = max(width * 0.72, 44)
            let x = reduceMotion ? (width - bandWidth) / 2 : -bandWidth + (width + bandWidth * 2) * min(max(progress, 0), 1)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.sottoGlow.opacity(0.12))
                LinearGradient(
                    colors: [
                        .clear,
                        Color.sottoGlow.opacity(0.32),
                        Color.white.opacity(0.14),
                        Color.sottoGlow.opacity(0.24),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: bandWidth)
                .offset(x: x)
                .blur(radius: reduceMotion ? 7 : 5)
            }
        }
    }
}
