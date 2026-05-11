import SwiftUI
import SottoCore

struct SegmentPanelView: View {
    @EnvironmentObject private var model: AppModel
    @State private var sentenceToolsExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header

            if let sentence = model.selectedSentence {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        selectedSentenceEditor(sentence)
                        sentenceTools(sentence)
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                    VStack(alignment: .leading, spacing: 10) {
                        pauseControl
                        emphasisControl
                        duration(sentence)
                    }
                    .frame(width: 330, alignment: .topLeading)
                    .padding(10)
                    .background(Color.black.opacity(0.20))
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .stroke(Color.sottoPrimary.opacity(0.08), lineWidth: 1)
                    )
                }
            } else {
                Text("选择一句稿件后，可以直接改文案、拆成两句，或和上下句合并。")
                    .font(SottoFont.pixel(13))
                    .foregroundStyle(Color.sottoMuted)
            }
        }
        .sottoEditorPanel(cornerRadius: 16, fillOpacity: 0.86, borderOpacity: 0.18, glowOpacity: 0.06)
    }

    private var header: some View {
        HStack {
            Image(systemName: "waveform")
                .font(SottoFont.pixel(18))
                .foregroundStyle(Color.sottoPrimary)
            VStack(alignment: .leading, spacing: 2) {
                Text("句子编辑 / 拆合 / 节奏")
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

    private func selectedSentenceEditor(_ sentence: SentenceSegment) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("当前句文案")
                    .font(SottoFont.pixel(10))
                    .foregroundStyle(Color.sottoMuted)
                Spacer()
                Text("自动保存")
                    .font(SottoFont.pixel(10))
                    .foregroundStyle(Color.sottoGreen.opacity(0.82))
            }
            TextEditor(text: selectedSentenceTextBinding)
                .font(SottoFont.pixel(10))
                .foregroundStyle(Color.sottoPrimary.opacity(0.94))
                .scrollContentBackground(.hidden)
                .textEditorStyle(.plain)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.28))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 52, alignment: .leading)
        }
    }

    private func sentenceTools(_ sentence: SentenceSegment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                    sentenceToolsExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: sentenceToolsExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .frame(width: 14)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("句子拆分")
                            .font(SottoFont.pixel(12))
                            .foregroundStyle(Color.sottoPrimary)
                        Text(sentenceToolsExpanded ? "点击字间光标拆句，也可以合并相邻句" : "展开后处理拆分 / 合并")
                            .font(SottoFont.pixel(10))
                            .foregroundStyle(Color.sottoMuted)
                    }
                    Spacer()
                    Text("\(sentence.text.count) 字")
                        .font(SottoFont.pixel(10))
                        .foregroundStyle(Color.sottoMuted)
                }
                .padding(.horizontal, 10)
                .frame(height: 42)
                .background(Color.white.opacity(0.040))
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(Color.sottoPrimary.opacity(sentenceToolsExpanded ? 0.16 : 0.08), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            if sentenceToolsExpanded {
                VStack(alignment: .leading, spacing: 9) {
                    HStack(spacing: 8) {
                        compactActionButton("合并上句", systemImage: "arrow.up.to.line.compact") {
                            model.mergeSelectedSentenceWithPrevious()
                        }
                        .opacity(model.selectedSentenceIndex == 0 ? 0.38 : 1)
                        .disabled(model.selectedSentenceIndex == 0)

                        compactActionButton("合并下句", systemImage: "arrow.down.to.line.compact") {
                            model.mergeSelectedSentenceWithNext()
                        }
                        .opacity(model.selectedSentenceIndex == (model.currentDocument?.sentences.count ?? 0) - 1 ? 0.38 : 1)
                        .disabled(model.selectedSentenceIndex == (model.currentDocument?.sentences.count ?? 0) - 1)

                        Spacer()
                    }

                    sentenceSplitter(sentence)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func sentenceSplitter(_ sentence: SentenceSegment) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("点击字间光标，把一句拆成两句")
                    .font(SottoFont.pixel(10))
                    .foregroundStyle(Color.sottoMuted)
            }

            ZStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        let characters = Array(sentence.text)
                        ForEach(Array(characters.enumerated()), id: \.offset) { index, character in
                            Text(String(character))
                                .font(SottoFont.pixel(11))
                                .foregroundStyle(Color.sottoPrimary)
                                .padding(.horizontal, 3)
                                .padding(.vertical, 7)
                                .frame(minHeight: 32)

                            if index < characters.count - 1 {
                                splitNode(offset: index + 1)
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

    private func splitNode(offset: Int) -> some View {
        SplitNodeView {
            model.splitSelectedSentence(at: offset)
        }
    }

    private func compactActionButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .semibold))
                Text(title)
                    .font(SottoFont.pixel(10))
            }
            .foregroundStyle(Color.sottoSecondary)
            .padding(.horizontal, 9)
            .frame(height: 26)
            .background(Color.white.opacity(0.045))
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(Color.sottoPrimary.opacity(0.10), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var pauseControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                SottoSemanticIcon(systemName: "timer", trigger: selectedPause.rawValue, kind: .pause)
                Text("停顿设置")
            }
            .font(SottoFont.pixel(11))
            .foregroundStyle(Color.sottoPrimary)
            Picker("停顿设置", selection: pauseBinding) {
                ForEach(PauseLevel.allCases, id: \.rawValue) { pause in
                    Text(pause.title).tag(pause)
                }
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
                SottoSemanticIcon(systemName: "target", trigger: selectedEmphasis.rawValue, kind: .emphasis)
                Text("强调设置")
            }
            .font(SottoFont.pixel(11))
            .foregroundStyle(Color.sottoPrimary)
            Picker("强调设置", selection: emphasisBinding) {
                ForEach(EmphasisLevel.allCases, id: \.rawValue) { emphasis in
                    Text(emphasis.title).tag(emphasis)
                }
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
        model.timing.duration(for: sentence)
    }

    private var selectedPause: PauseLevel {
        model.selectedSentence?.pause ?? .normal
    }

    private var selectedEmphasis: EmphasisLevel {
        model.selectedSentence?.emphasis ?? .normal
    }

    private var pauseBinding: Binding<PauseLevel> {
        Binding(
            get: { selectedPause },
            set: { model.setSelectedSentencePause($0) }
        )
    }

    private var emphasisBinding: Binding<EmphasisLevel> {
        Binding(
            get: { selectedEmphasis },
            set: { model.setSelectedSentenceEmphasis($0) }
        )
    }

    private var selectedSentenceTextBinding: Binding<String> {
        Binding(
            get: { model.selectedSentence?.text ?? "" },
            set: { model.updateSelectedSentenceText($0) }
        )
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
