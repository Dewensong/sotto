import AppKit
import SwiftUI
import SottoCore

struct TeleprompterWindowView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        PromptWindowLayout(fullWindow: true)
            .frame(minWidth: 620, maxWidth: .infinity, minHeight: 380, maxHeight: .infinity)
            .background(Color.clear)
            .onReceive(Timer.publish(every: 1 / 30, on: .main, in: .common).autoconnect()) { date in
                model.tickPlayback(now: date)
            }
    }
}

struct PromptWindowLayout: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPromptHovering = false
    @State private var isCloseHovering = false
    @State private var showSettings = false
    var fullWindow = false

    var body: some View {
        if fullWindow {
            ZStack(alignment: .topTrailing) {
                Group {
                    SottoGlassPanel(role: .prompt) {
                        promptContent
                    }
                    .opacity(model.settings.opacity)
                    .brightness(model.settings.brightness - 1)

                    resizeHandles

                    WindowDragHandle()
                        .frame(height: 36)
                        .frame(maxWidth: .infinity)

                    closeButton
                        .padding(.top, 12)
                        .padding(.trailing, 12)
                }
                .scaleEffect(x: model.settings.mirrored ? -1 : 1, y: 1)
                .blur(radius: showSettings ? 8 : 0)
                .allowsHitTesting(!showSettings)

                if let phase = model.countdownPhase {
                    countdownOverlay(phase: phase)
                }

                if showSettings {
                    Color.black.opacity(0.001)
                        .contentShape(Rectangle())
                        .onTapGesture { showSettings = false }
                        .zIndex(10)

                    SottoSettingsPanel()
                        .environmentObject(model)
                        .padding(.vertical, 24)
                        .frame(maxHeight: 500)
                        .zIndex(20)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)).combined(with: .move(edge: .bottom)))
                }
            }
            .background(Color.clear)
            .clipShape(promptWindowShape)
            .contentShape(promptWindowShape)
            .onHover { isPromptHovering = $0 }
            .animation(.easeOut(duration: SottoMotionTokens.duration(0.18, reduceMotion: reduceMotion)), value: isPromptHovering)
        } else {
            promptContent
                .padding(12)
                .background(Color.black.opacity(0.28))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var promptWindowShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: PromptWindowAppearance.cornerRadius, style: .continuous)
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

            SottoVoiceWaveform(
                level: model.microphoneLevel,
                isListening: model.microphoneIsListening,
                opacity: fullWindow ? 0.50 : 0.28,
                barCount: fullWindow ? 54 : 34,
                animated: !reduceMotion
            )
            .frame(height: fullWindow ? 36 : 18)

            if fullWindow {
                controls
                    .opacity(isPromptHovering ? 1 : 0.36)
                    .offset(y: isPromptHovering || reduceMotion ? 0 : 4)
                    .animation(.easeOut(duration: SottoMotionTokens.duration(0.18, reduceMotion: reduceMotion)), value: isPromptHovering)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var promptSidebar: some View {
        let liveColor = model.session?.isPlaying == true ? Color.sottoRed : Color.sottoGreen

        return VStack(alignment: .leading, spacing: 14) {
            SottoSignalText(text: "SOTTO\nPROMPT", size: fullWindow ? 16 : 11, color: .sottoPrimary, dot: 1.6, spacing: 4, tracking: 2)
                .frame(width: fullWindow ? 108 : 72, height: fullWindow ? 56 : 40, alignment: .leading)

            Circle()
                .fill(liveColor)
                .frame(width: 8, height: 8)
                .shadow(color: liveColor.opacity(0.8), radius: 6)

            VStack(alignment: .leading, spacing: 6) {
                Text("• REC")
                    .font(SottoFont.pixel(11))
                    .tracking(1.5)
                Text(elapsedText)
                    .font(SottoFont.pixel(14))
            }
            .foregroundStyle(model.session?.isPlaying == true ? liveColor : Color.sottoSecondary)

            VStack(alignment: .leading, spacing: 6) {
                Button {
                    model.toggleSentencePicker()
                } label: {
                    Text(progressText)
                        .font(SottoFont.pixel(14))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $model.showSentencePicker, arrowEdge: .trailing) {
                    SentencePickerView(
                        sentences: model.session?.document.sentences ?? [],
                        currentIndex: model.session?.currentSentenceIndex ?? 0,
                        onSelect: { index in
                            model.jumpToSentence(at: index)
                            model.showSentencePicker = false
                        }
                    )
                    .frame(width: 300, height: 380)
                }
                Rectangle()
                    .fill(Color.sottoPrimary.opacity(0.82))
                    .frame(width: 32, height: 2)
            }
            .foregroundStyle(Color.sottoSecondary)

            if let para = currentParagraphInfo {
                VStack(alignment: .leading, spacing: 6) {
                    Text(para.name)
                        .font(SottoFont.pixel(11))
                        .tracking(1.5)
                        .lineLimit(1)
                    Text("\(para.current) / \(para.total)")
                        .font(SottoFont.pixel(14))
                }
                .foregroundStyle(Color.sottoSecondary)
            }

            if let bookmarkIndex = model.bookmarkedSentenceIndex {
                VStack(alignment: .leading, spacing: 6) {
                    Text("书签")
                        .font(SottoFont.pixel(11))
                        .tracking(1.5)
                    Button {
                        model.jumpToBookmark()
                    } label: {
                        Text("句 \(bookmarkIndex + 1)")
                            .font(SottoFont.pixel(14))
                    }
                    .buttonStyle(.plain)
                }
                .foregroundStyle(Color.sottoGlow)
            }

            Spacer(minLength: 4)

            VStack(alignment: .leading, spacing: 3) {
                shortcutHint(key: "Space", label: "播放/暂停")
                shortcutHint(key: "⇧⌘R", label: "从头")
                shortcutHint(key: "⌘J", label: "导航")
                shortcutHint(key: "← →", label: "上下句")
                shortcutHint(key: "⌘←→", label: "加减速")
                shortcutHint(key: "Esc", label: "退出")
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var currentParagraphInfo: (current: Int, total: Int, name: String)? {
        guard let session = model.session,
              let paraIndex = session.currentSentence?.paragraphIndex else { return nil }
        let sentences = session.document.sentences
        let uniqueParagraphs = Set(sentences.compactMap(\.paragraphIndex))
        guard !uniqueParagraphs.isEmpty else { return nil }
        let firstSentence = sentences.first { $0.paragraphIndex == paraIndex }
        let name = firstSentence.map { String($0.text.prefix(8)) } ?? "段落"
        return (current: paraIndex + 1, total: uniqueParagraphs.count, name: name)
    }

    private func countdownOverlay(phase: Int) -> some View {
        ZStack {
            Color.black.opacity(0.55)
            Text("\(phase)")
                .font(.system(size: 144, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.sottoPrimary)
                .shadow(color: Color.sottoGlow.opacity(0.6), radius: 32)
        }
        .ignoresSafeArea()
        .transition(.opacity.combined(with: .scale(scale: 1.4)))
        .animation(.easeInOut(duration: 0.25), value: phase)
        .zIndex(30)
    }

    private func shortcutHint(key: String, label: String) -> some View {
        HStack(spacing: 5) {
            Text(key)
                .font(SottoFont.pixel(9))
                .tracking(0.3)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .stroke(Color.sottoPrimary.opacity(0.10), lineWidth: 1)
                )
            Text(label)
                .font(SottoFont.pixel(9))
                .tracking(0.5)
        }
        .foregroundStyle(Color.sottoMuted.opacity(0.55))
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

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: fullWindow) {
                    LazyVStack(alignment: .leading, spacing: fullWindow ? 14 : 9) {
                        ForEach(promptDisplayItems) { item in
                            switch item {
                            case .row(let row):
                                promptRow(row)
                                    .id(row.index)
                            case .divider(let id):
                                paragraphDivider
                                    .id("divider-\(id)")
                            }
                        }
                    }
                    .padding(.vertical, fullWindow ? 54 : 18)
                }
                .onAppear {
                    scrollToCurrent(using: proxy, animated: false)
                }
                .onChange(of: model.session?.currentSentenceIndex) { _, _ in
                    scrollToCurrent(using: proxy, animated: true)
                }
            }
            .animation(.easeInOut(duration: SottoMotionTokens.duration(0.34, reduceMotion: reduceMotion)), value: model.session?.currentSentenceIndex)

            SottoProgressiveEdgeFade(
                edges: [.top, .bottom],
                height: fullWindow ? 28 : 18,
                strength: fullWindow ? 0.46 : 0.24
            )
        }
    }

    private enum PromptDisplayItem: Identifiable {
        case row(PromptDisplayRow)
        case divider(id: Int)

        var id: String {
            switch self {
            case .row(let row): return "row-\(row.index)"
            case .divider(let id): return "divider-\(id)"
            }
        }
    }

    private var promptDisplayItems: [PromptDisplayItem] {
        let rows = promptRows
        guard !rows.isEmpty else { return [] }

        let sentences = model.session?.document.sentences ?? []
        var items: [PromptDisplayItem] = []

        for row in rows {
            // Insert divider before row if paragraph changed from previous sentence
            if row.index > 0,
               let currentPara = sentences[row.index].paragraphIndex,
               let prevPara = sentences[row.index - 1].paragraphIndex,
               currentPara != prevPara {
                items.append(.divider(id: row.index))
            }
            items.append(.row(row))
        }

        return items
    }

    private var paragraphDivider: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(Color.sottoPrimary.opacity(0.12))
                .frame(height: 1)
            Circle()
                .fill(Color.sottoPrimary.opacity(0.18))
                .frame(width: 4, height: 4)
            Rectangle()
                .fill(Color.sottoPrimary.opacity(0.12))
                .frame(height: 1)
        }
        .padding(.horizontal, fullWindow ? 40 : 16)
        .padding(.vertical, fullWindow ? 4 : 2)
    }

    private func promptRow(_ row: PromptDisplayRow) -> some View {
        HStack(spacing: 6) {
            Text("\(row.index + 1)")
                .font(SottoFont.pixel(fullWindow ? 10 : 9))
                .foregroundStyle(Color.sottoMuted.opacity(row.isCurrent ? 0.55 : 0.30))
                .frame(width: fullWindow ? 22 : 16, alignment: .trailing)

            Button {
                model.jumpToSentence(at: row.index)
            } label: {
                Group {
                    if row.isCurrent {
                        highlightedCurrentSentence(size: currentSentenceSize, lineLimit: fullWindow ? 3 : 2)
                    } else {
                        promptText(
                            row.text,
                            size: rowTextSize(row),
                            color: rowColor(row),
                            weight: .regular,
                            lineLimit: fullWindow ? 2 : 1
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, row.isCurrent ? (fullWindow ? 14 : 10) : 8)
                .padding(.vertical, row.isCurrent ? (fullWindow ? 14 : 8) : 5)
                .background(row.isCurrent ? Color.sottoGlow.opacity(currentSentenceEmphasized ? 0.16 : (fullWindow ? 0.10 : 0.075)) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: row.isCurrent ? 14 : 8, style: .continuous))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
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
            .font(SottoFont.bodyFont(model.settings.bodyFontName, size: size))
            .lineSpacing(size * model.settings.lineSpacing)
            .tracking(model.settings.tracking)
            .lineLimit(lineLimit)
            .foregroundStyle(color)
            .shadow(color: Color.sottoGlow.opacity(weight == .semibold ? 0.26 : 0.10), radius: weight == .semibold ? 12 : 6)
    }

    private var controls: some View {
        HStack(spacing: 12) {
            SottoIconButton(systemName: "backward.end.fill") { model.previousSentence() }
            SottoIconButton(systemName: model.session?.isPlaying == true ? "pause.fill" : "play.fill") {
                if model.session?.isPlaying == true {
                    model.togglePlayback()
                } else {
                    model.startPlaybackWithCountdown()
                }
            }
            SottoIconButton(systemName: "forward.end.fill") { model.nextSentence() }
            divider
            Text(String(format: "%.2fx", model.settings.speedMultiplier))
                .font(SottoFont.pixel(10))
                .foregroundStyle(Color.sottoSecondary)
                .monospacedDigit()
            divider
            SottoIconButton(systemName: "slider.horizontal.3", title: "TUNE") {
                showSettings.toggle()
            }
            SottoIconButton(systemName: model.settings.position == .cameraNear ? "web.camera.fill" : "rectangle.topthird.inset.filled") {
                togglePromptPosition()
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func togglePromptPosition() {
        model.setPromptPosition(model.settings.position == .cameraNear ? .upperCenter : .cameraNear)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.sottoPrimary.opacity(0.22))
            .frame(width: 1, height: 30)
    }

    private var currentSentenceText: String? {
        model.session?.currentSentence?.text
    }

    private var currentSentenceSize: CGFloat {
        guard fullWindow else { return 22 }
        let requested = model.settings.fontSize
        let text = currentSentenceText ?? ""
        let count = text.filter { !$0.isWhitespace }.count
        let baseSize: Double
        if count > 58 {
            baseSize = min(requested, 30)
        } else if count > 44 {
            baseSize = min(requested, 34)
        } else if count > 34 {
            baseSize = min(requested, 38)
        } else {
            baseSize = requested
        }

        let availableWidth = max(model.settings.width - 230, 260)
        let targetLines = count <= 24 ? 1 : 2
        return CGFloat(PromptTextFitEstimator.fittedFontSize(
            text: text,
            requestedSize: baseSize,
            minimumSize: 24,
            containerWidth: availableWidth,
            targetLines: targetLines
        ))
    }

    private var currentSentenceID: String {
        model.session?.currentSentence?.id.uuidString ?? "empty"
    }

    private var currentSentenceEmphasized: Bool {
        model.session?.currentSentence?.emphasis == .emphasized
    }

    private var promptRows: [PromptDisplayRow] {
        guard let session = model.session else { return [] }
        let sentences = session.document.sentences
        let current = session.currentSentenceIndex

        if fullWindow {
            return sentences.indices.map { index in
                PromptDisplayRow(index: index, text: sentences[index].text, offset: index - current)
            }
        }

        let lower = max(sentences.startIndex, current - 1)
        let upper = min(sentences.endIndex - 1, current + 2)
        return (lower...upper).map { index in
            PromptDisplayRow(index: index, text: sentences[index].text, offset: index - current)
        }
    }

    private func highlightedCurrentSentence(size: CGFloat, lineLimit: Int) -> some View {
        guard let session = model.session, let sentence = session.currentSentence else {
            return AnyView(EmptyView())
        }
        switch model.settings.cursorMode {
        case .line:
            return AnyView(
                promptText(sentence.text, size: size, color: Color.sottoPrimary, weight: .semibold, lineLimit: lineLimit)
            )
        case .word, .character:
            let sweepMode: PhraseSweepMode = model.settings.cursorMode == .word ? .word : .character
            return AnyView(
                CurrentSentenceSweepView(
                    sentence: sentence,
                    currentPhraseIndex: session.currentPhraseIndex,
                    progress: model.phraseProgress,
                    size: size,
                    lineLimit: lineLimit,
                    emphasized: sentence.emphasis == .emphasized,
                    bodyFontName: model.settings.bodyFontName,
                    lineSpacing: model.settings.lineSpacing,
                    tracking: model.settings.tracking,
                    sweepMode: sweepMode
                )
            )
        }
    }

    private var elapsedText: String {
        model.playbackElapsedDisplay
    }

    private var progressText: String {
        guard let session = model.session else { return "00 / 00" }
        return "\(String(format: "%02d", session.currentSentenceIndex + 1)) / \(String(format: "%02d", session.document.sentences.count))"
    }

    private var timingIndexValue: Double {
        Double(TimingProfile.allCases.firstIndex(of: model.timing) ?? 1)
    }

    private var closeButton: some View {
        Button {
            model.closeTeleprompter()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.sottoPrimary.opacity(isCloseHovering ? 0.90 : 0.58))
                .frame(width: 26, height: 26)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color.black.opacity(isCloseHovering ? 0.30 : 0))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(Color.sottoPrimary.opacity(isCloseHovering ? 0.24 : 0), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .opacity(isCloseHovering ? 1 : (isPromptHovering || reduceMotion ? 0.72 : 0.50))
        .onHover { isCloseHovering = $0 }
        .help("退出提词")
    }

    private var resizeHandles: some View {
        GeometryReader { proxy in
            ZStack {
                PromptResizeGrip(anchor: .top, startSize: proxy.size)
                    .frame(width: max(proxy.size.width - 104, 80), height: 44)
                    .position(x: proxy.size.width / 2, y: 22)
                PromptResizeGrip(anchor: .bottom, startSize: proxy.size)
                    .frame(width: max(proxy.size.width - 180, 80), height: 14)
                    .position(x: proxy.size.width / 2, y: proxy.size.height - 7)
                PromptResizeGrip(anchor: .left, startSize: proxy.size)
                    .frame(width: 30, height: max(proxy.size.height - 120, 80))
                    .position(x: 15, y: proxy.size.height / 2)
                PromptResizeGrip(anchor: .right, startSize: proxy.size)
                    .frame(width: 30, height: max(proxy.size.height - 120, 80))
                    .position(x: proxy.size.width - 15, y: proxy.size.height / 2)
                PromptResizeGrip(anchor: .topLeft, startSize: proxy.size)
                    .frame(width: 64, height: 64)
                    .position(x: 32, y: 32)
                PromptResizeGrip(anchor: .topRight, startSize: proxy.size)
                    .frame(width: 64, height: 64)
                    .position(x: proxy.size.width - 32, y: 32)
                PromptResizeGrip(anchor: .bottomLeft, startSize: proxy.size)
                    .frame(width: 64, height: 64)
                    .position(x: 32, y: proxy.size.height - 32)
                PromptResizeGrip(anchor: .bottomRight, startSize: proxy.size)
                    .frame(width: 64, height: 64)
                    .position(x: proxy.size.width - 32, y: proxy.size.height - 32)
            }
        }
    }

    private func rowTextSize(_ row: PromptDisplayRow) -> CGFloat {
        guard fullWindow else { return row.offset < 0 ? 15 : 14 }
        let distance = min(abs(row.offset), 4)
        return max(16, 23 - CGFloat(distance * 2))
    }

    private func rowColor(_ row: PromptDisplayRow) -> Color {
        if row.offset < 0 {
            return Color.sottoSecondary.opacity(0.52)
        }
        let distance = min(abs(row.offset), 5)
        return Color.sottoSecondary.opacity(0.72 - Double(distance) * 0.08)
    }

    private func scrollToCurrent(using proxy: ScrollViewProxy, animated: Bool) {
        guard let index = model.session?.currentSentenceIndex else { return }
        let action = {
            proxy.scrollTo(index, anchor: .center)
        }
        if animated && !reduceMotion {
            withAnimation(.easeInOut(duration: 0.42)) {
                action()
            }
        } else {
            action()
        }
    }

    private func stepTiming(_ direction: Int) {
        let cases = TimingProfile.allCases
        guard let current = cases.firstIndex(of: model.timing) else { return }
        let next = min(max(current + direction, 0), cases.count - 1)
        model.setTiming(cases[next])
    }
}

private struct PromptDisplayRow: Identifiable {
    let index: Int
    let text: String
    let offset: Int

    var id: Int { index }
    var isCurrent: Bool { offset == 0 }
}

private struct SentencePickerView: View {
    let sentences: [SentenceSegment]
    let currentIndex: Int
    let onSelect: (Int) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("跳转到句子")
                .font(SottoFont.pixel(13))
                .tracking(1.2)
                .foregroundStyle(Color.sottoPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)

            Divider()
                .background(Color.sottoPrimary.opacity(0.10))

            ScrollViewReader { proxy in
                List(sentences.indices, id: \.self) { index in
                    let sentence = sentences[index]
                    let isCurrent = index == currentIndex
                    Button {
                        onSelect(index)
                    } label: {
                        HStack {
                            Text("\(index + 1)")
                                .font(SottoFont.pixel(12))
                                .foregroundStyle(isCurrent ? Color.sottoGreen : Color.sottoMuted)
                                .frame(width: 28, alignment: .trailing)
                            Text(sentence.text)
                                .font(SottoFont.pixel(12))
                                .foregroundStyle(isCurrent ? Color.sottoPrimary : Color.sottoSecondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(isCurrent ? Color.sottoGlow.opacity(0.14) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .id(index)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .onAppear {
                    proxy.scrollTo(currentIndex, anchor: .center)
                }
            }
        }
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThickMaterial)
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(red: 0.060, green: 0.056, blue: 0.050).opacity(0.86))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.sottoPrimary.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: Color.sottoGlow.opacity(0.22), radius: 24, y: 12)
    }
}

private struct PromptResizeGrip: View {
    let anchor: PromptResizeAnchor
    let startSize: CGSize
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        model.resizePromptWindow(
                            to: resized(base: startSize, translation: value.translation),
                            anchor: anchor
                        )
                    }
            )
    }

    private func resized(base: CGSize, translation: CGSize) -> CGSize {
        switch anchor {
        case .topLeft:
            CGSize(width: base.width - translation.width, height: base.height - translation.height)
        case .topRight:
            CGSize(width: base.width + translation.width, height: base.height - translation.height)
        case .bottomLeft:
            CGSize(width: base.width - translation.width, height: base.height + translation.height)
        case .bottomRight:
            CGSize(width: base.width + translation.width, height: base.height + translation.height)
        case .top:
            CGSize(width: base.width, height: base.height - translation.height)
        case .bottom:
            CGSize(width: base.width, height: base.height + translation.height)
        case .left:
            CGSize(width: base.width - translation.width, height: base.height)
        case .right:
            CGSize(width: base.width + translation.width, height: base.height)
        }
    }
}


private struct CurrentSentenceSweepView: View {
    let sentence: SentenceSegment
    let currentPhraseIndex: Int
    let progress: Double
    let size: CGFloat
    let lineLimit: Int
    let emphasized: Bool
    let bodyFontName: String?
    let lineSpacing: Double
    let tracking: Double
    let sweepMode: PhraseSweepMode
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        FlowLayout(spacing: 0) {
            ForEach(displayTokens) { token in
                SentenceTokenSweepPiece(
                    token: token,
                    state: state(for: token),
                    size: size,
                    emphasized: emphasized,
                    bodyFontName: bodyFontName
                )
            }
        }
        .lineSpacing(size * lineSpacing)
        .tracking(tracking)
        .shadow(color: Color.sottoGlow.opacity(emphasized ? 0.42 : 0.28), radius: emphasized ? 18 : 12)
        .animation(.easeOut(duration: SottoMotionTokens.duration(0.24, reduceMotion: reduceMotion)), value: currentPhraseIndex)
    }

    private var displayTokens: [SentenceSweepToken] {
        sentence.phrases.enumerated().flatMap { phraseIndex, phrase in
            SentenceSweepToken.tokenize(phrase.text, phraseIndex: phraseIndex)
        }
    }

    private var currentTokenOrdinal: Int {
        let currentTokens = displayTokens.filter { $0.phraseIndex == currentPhraseIndex && !$0.isWhitespace }
        guard !currentTokens.isEmpty else { return 0 }
        return max(min(Int((progress * Double(currentTokens.count)).rounded(.down)), currentTokens.count - 1), 0)
    }

    private func state(for token: SentenceSweepToken) -> PhraseSweepState {
        if token.phraseIndex < currentPhraseIndex { return .past }
        if token.phraseIndex > currentPhraseIndex { return .future }
        if token.isWhitespace { return .past }
        switch sweepMode {
        case .character:
            if token.ordinalInPhrase < currentTokenOrdinal { return .past }
            if token.ordinalInPhrase == currentTokenOrdinal { return .current }
            return .future
        case .word:
            return .current
        }
    }
}

private enum PhraseSweepState {
    case past
    case current
    case future
}

private enum PhraseSweepMode {
    case character
    case word
}

private struct SentenceSweepToken: Identifiable {
    let id: String
    let text: String
    let phraseIndex: Int
    let ordinalInPhrase: Int
    let isWhitespace: Bool

    static func tokenize(_ text: String, phraseIndex: Int) -> [SentenceSweepToken] {
        var tokens: [SentenceSweepToken] = []
        var latinBuffer = ""
        var latinStart = 0
        var ordinal = 0

        func flushLatinBuffer(currentOffset: Int) {
            guard !latinBuffer.isEmpty else { return }
            tokens.append(SentenceSweepToken(
                id: "\(phraseIndex)-\(latinStart)",
                text: latinBuffer,
                phraseIndex: phraseIndex,
                ordinalInPhrase: ordinal,
                isWhitespace: false
            ))
            ordinal += 1
            latinBuffer = ""
            latinStart = currentOffset
        }

        for (offset, character) in text.enumerated() {
            if character.isWhitespace {
                flushLatinBuffer(currentOffset: offset)
                tokens.append(SentenceSweepToken(
                    id: "\(phraseIndex)-\(offset)",
                    text: String(character),
                    phraseIndex: phraseIndex,
                    ordinalInPhrase: ordinal,
                    isWhitespace: true
                ))
            } else if character.isLetter || character.isNumber, character.unicodeScalars.allSatisfy({ $0.value < 128 }) {
                if latinBuffer.isEmpty {
                    latinStart = offset
                }
                latinBuffer.append(character)
            } else {
                flushLatinBuffer(currentOffset: offset)
                tokens.append(SentenceSweepToken(
                    id: "\(phraseIndex)-\(offset)",
                    text: String(character),
                    phraseIndex: phraseIndex,
                    ordinalInPhrase: ordinal,
                    isWhitespace: false
                ))
                ordinal += 1
            }
        }

        flushLatinBuffer(currentOffset: text.count)
        return tokens
    }
}

private struct SentenceTokenSweepPiece: View {
    let token: SentenceSweepToken
    let state: PhraseSweepState
    let size: CGFloat
    let emphasized: Bool
    let bodyFontName: String?

    var body: some View {
        Text(token.text)
            .font(SottoFont.bodyFont(bodyFontName, size: size))
            .lineLimit(1)
            .foregroundStyle(textColor)
            .padding(.horizontal, token.isWhitespace ? 0 : 1.5)
            .padding(.vertical, 2)
            .background {
                if state == .current && !token.isWhitespace {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.sottoPrimary.opacity(emphasized ? 0.18 : 0.12))
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(Color.sottoPrimary.opacity(0.86))
                                .frame(height: 2)
                                .offset(y: 3)
                        }
                        .shadow(color: Color.sottoGlow.opacity(0.42), radius: 8)
                }
            }
    }

    private var textColor: Color {
        if token.isWhitespace { return .clear }
        switch state {
        case .past:
            return Color.sottoPrimary.opacity(emphasized ? 1 : 0.94)
        case .current:
            return Color.sottoPrimary
        case .future:
            return Color.sottoPrimary.opacity(emphasized ? 0.70 : 0.56)
        }
    }
}


// MARK: - Window drag handle

private struct WindowDragHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        DragHandleView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class DragHandleView: NSView {
        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }
    }
}
