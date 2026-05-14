import AppKit
import SwiftUI
import SottoCore
import UniformTypeIdentifiers

struct HomeView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isInputFocused: Bool = false
    @State private var stageHovering = false
    @State private var stageSparking = false
    @State private var isEditorExpanded = false
    @State private var hoverTrash = false
    @State private var hoverExpand = false
    @State private var hoverFile = false
    @State private var hoverSave = false
    @State private var hoverAI = false
    @State private var hoverManageDocs = false
    @State private var hoverSettings = false

    var body: some View {
        VStack(spacing: 10) {
            topBar
                .sottoEntrance()
            heroCopy
                .sottoEntrance(delay: 0.04)
                .onTapGesture { tryDefocus() }
            materialStage
                .sottoEntrance(delay: 0.08)
            recentDocuments
                .sottoEntrance(delay: 0.12)
                .blur(radius: isEditorExpanded ? 6 : 0)
            Text("专注表达，聚光成句。")
                .font(SottoFont.pixel(13))
                .tracking(3)
                .foregroundStyle(Color.sottoSecondary)
                .onTapGesture { tryDefocus() }
                .blur(radius: isEditorExpanded ? 6 : 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 78)
        .padding(.bottom, 12)
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { tryDefocus() }
        )
    }

    private func tryDefocus() {
        if model.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, isInputFocused {
            isInputFocused = false
        }
    }

    private var topBar: some View {
        HStack(alignment: .top) {
            HStack(spacing: 10) {
                PixelTeleprompterIcon()
                    .frame(width: 46, height: 40)
                VStack(alignment: .leading, spacing: 3) {
                    SottoSignalText(text: "Sotto", size: 28, color: .sottoPrimary, dot: 1.7, spacing: 4.6)
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
                Button {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        model.toggleSettingsPanel()
                    }
                } label: {
                    Image(systemName: "gearshape")
                        .font(SottoFont.pixel(22))
                        .foregroundStyle(Color.sottoSecondary)
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                .rotationEffect(.degrees(model.settingsRotation))
                .scaleEffect(hoverSettings ? 1.15 : 1.0)
                .animation(.spring(response: 0.28, dampingFraction: 0.70), value: hoverSettings)
                .onHover { hoverSettings = $0 }
            }
            .padding(.top, 10)
        }
        .contentShape(Rectangle())
        .onTapGesture { tryDefocus() }
        .simultaneousGesture(TapGesture().onEnded { tryDefocus() })
    }

    private var heroCopy: some View {
        VStack(spacing: 10) {
            PixelText(
                text: "让今天的 demo 好好上场",
                size: 22,
                weight: .regular,
                color: .sottoPrimary,
                dot: 1.45,
                spacing: 4.4,
                tracking: 2
            )
            .frame(maxWidth: 360, minHeight: 34)

            Text("把已有稿件放进来，整理成适合录屏、讲解和 vibe coding 的提词节奏。")
                .font(SottoFont.pixel(12))
                .foregroundStyle(Color.sottoSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 10)
    }

    private var materialStage: some View {
        let textIsEmpty = model.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let showEditor = isInputFocused || !textIsEmpty

        return VStack(spacing: 24) {
            Group {
                if showEditor {
                    VStack(spacing: 0) {
                        HStack(spacing: 6) {
                            Button {
                                model.pushInputHistory()
                                model.inputText = ""
                                isInputFocused = true
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Color.sottoSecondary)
                                    .frame(width: 26, height: 26)
                                    .background(Color.white.opacity(0.04))
                                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .disabled(model.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .scaleEffect(hoverTrash ? 1.15 : 1.0)
                            .animation(.spring(response: 0.28, dampingFraction: 0.70), value: hoverTrash)
                            .onHover { hoverTrash = $0 }

                            if model.canUndoInput {
                                Button {
                                    model.undoInputChange()
                                } label: {
                                    Image(systemName: "arrow.uturn.backward")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(Color.sottoGlow)
                                        .frame(width: 26, height: 26)
                                        .background(Color.sottoGlow.opacity(0.08))
                                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                                }
                                .buttonStyle(.plain)
                                .help("撤销输入更改")
                            }

                            Button {
                                withAnimation(.spring(response: 0.40, dampingFraction: 0.80)) {
                                    isEditorExpanded.toggle()
                                }
                                if isEditorExpanded {
                                    isInputFocused = true
                                }
                            } label: {
                                Image(systemName: isEditorExpanded
                                    ? "arrow.down.right.and.arrow.up.left"
                                    : "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Color.sottoSecondary)
                                    .frame(width: 26, height: 26)
                                    .background(Color.white.opacity(0.04))
                                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .scaleEffect(hoverExpand ? 1.15 : 1.0)
                            .animation(.spring(response: 0.28, dampingFraction: 0.70), value: hoverExpand)
                            .onHover { hoverExpand = $0 }

                            Spacer()

                            Button {
                                model.saveInputToLibrary()
                            } label: {
                                Image(systemName: "tray.and.arrow.down")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Color.sottoSecondary)
                                    .frame(width: 26, height: 26)
                                    .background(Color.white.opacity(0.04))
                                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .disabled(model.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .scaleEffect(hoverSave ? 1.15 : 1.0)
                            .animation(.spring(response: 0.28, dampingFraction: 0.70), value: hoverSave)
                            .onHover { hoverSave = $0 }

                            Button {
                                model.exportCurrentDocument()
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Color.sottoSecondary)
                                    .frame(width: 26, height: 26)
                                    .background(Color.white.opacity(0.04))
                                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .disabled(model.currentDocument == nil && model.session?.document == nil)
                            .help("导出稿件")

                            Button {
                                model.showAiOptions.toggle()
                            } label: {
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(model.showAiOptions ? Color.sottoGlow : Color.sottoSecondary)
                                    .frame(width: 26, height: 26)
                                    .background(Color.white.opacity(model.showAiOptions ? 0.12 : 0.04))
                                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .disabled(model.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || model.isAnalyzing)
                            .scaleEffect(hoverAI ? 1.15 : 1.0)
                            .animation(.spring(response: 0.28, dampingFraction: 0.70), value: hoverAI)
                            .onHover { hoverAI = $0 }

                            Button {
                                openFilePicker()
                            } label: {
                                Image(systemName: "doc.badge.plus")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.sottoSecondary)
                                    .frame(width: 26, height: 26)
                                    .background(Color.white.opacity(0.04))
                                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .scaleEffect(hoverFile ? 1.15 : 1.0)
                            .animation(.spring(response: 0.28, dampingFraction: 0.70), value: hoverFile)
                            .onHover { hoverFile = $0 }
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 10)
                        .padding(.bottom, 2)

                        if model.showAiOptions {
                            aiOptionsPanel
                                .padding(.horizontal, 14)
                                .transition(.opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.96, anchor: .top)))
                        }

                        if model.isAnalyzing {
                            aiAnalyzingIndicator
                                .padding(.horizontal, 14)
                        }

                        PasteHandlingTextView(
                            text: $model.inputText,
                            isFocused: isInputFocused,
                            onFocusChange: { isInputFocused = $0 },
                            onFileURLsPasted: handleFileURLs
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .frame(height: isEditorExpanded ? 340 : 100)
                    }
                    .background(Color.black.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    Button {
                        isInputFocused = true
                    } label: {
                        VStack(spacing: 10) {
                            PixelDocumentIcon()
                                .frame(width: 50, height: 54)
                                .shadow(color: Color.sottoGlow.opacity(0.46), radius: 14)
                            Text("粘贴口播稿 / Notion 文稿 / AI 对话整理稿")
                                .font(SottoFont.pixel(14))
                                .foregroundStyle(Color.sottoPrimary)
                            Text("先把表达准备好，再把窗口推到舞台边上。")
                                .font(SottoFont.pixel(11))
                                .foregroundStyle(Color.sottoSecondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 112)
                    }
                    .buttonStyle(.plain)
                }
            }
            .contentShape(Rectangle())
            .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                for provider in providers {
                    provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                        guard let data = item as? Data,
                              let url = URL(dataRepresentation: data, relativeTo: nil)
                        else { return }
                        DispatchQueue.main.async {
                            handleFileURLs([url])
                        }
                    }
                }
                return true
            }
            .onTapGesture { }

            Group {
                capabilityRow

                SottoAmbientMotionField(intensity: stageHovering ? 0.92 : 0.64, animated: !reduceMotion)
                    .frame(height: 28)
                    .padding(.horizontal, 20)
                    .padding(.top, 2)

                Button {
                    confirmStageEntrance()
                } label: {
                    HStack(spacing: 14) {
                        DotField(spacing: 5, dotSize: 1.7, opacity: stageHovering ? 0.58 : 0.42, drift: stageHovering ? 1.1 : 0.55)
                            .frame(width: 42, height: 28)
                        VStack(spacing: 2) {
                            Text("ON STAGE")
                                .font(SottoFont.pixel(18))
                                .tracking(2)
                            Text("准备上场")
                                .font(SottoFont.pixel(11))
                                .tracking(4)
                        }
                        DotField(spacing: 5, dotSize: 1.7, opacity: stageHovering ? 0.58 : 0.42, drift: stageHovering ? 1.1 : 0.55)
                            .frame(width: 42, height: 28)
                    }
                    .foregroundStyle(Color.sottoPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.sottoGlow.opacity(0.09))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.sottoPrimary.opacity(stageHovering ? 0.54 : 0.34), lineWidth: 1)
                    )
                    .shadow(color: Color.sottoGlow.opacity(stageHovering ? 0.38 : 0.26), radius: stageHovering ? 20 : 16)
                }
                .background(
                    Capsule()
                        .fill(Color.white.opacity(stageHovering ? 0.08 : 0))
                        .blur(radius: 16)
                        .scaleEffect(stageHovering ? 1.10 : 0.96)
                )
                .overlay(SottoConfirmationSpark(isActive: stageSparking, radius: 20))
                .buttonStyle(.plain)
                .scaleEffect(stageHovering ? 1.025 : 1)
                .animation(SottoMotionTokens.hover, value: stageHovering)
                .onHover { stageHovering = $0 }
                .disabled(textIsEmpty)
                .opacity(isEditorExpanded ? 0.55 : (textIsEmpty ? 0.45 : 1))
                .padding(.top, 4)
            }
            .blur(radius: isEditorExpanded ? 8 : 0)
        }
        .frame(maxWidth: .infinity)
        .sottoEditorPanel(cornerRadius: 18)
    }

    private var capabilityRow: some View {
        HStack(spacing: 12) {
            CapabilityItem(icon: "square.grid.3x3", title: "段落识别")
            CapabilityItem(icon: "scissors", title: "句子拆合")
            CapabilityItem(icon: "waveform", title: "跟声试验")
            CapabilityItem(icon: "sun.max", title: "录屏提词")
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
                Button {
                    model.openDocumentManager()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "tray.full")
                            .font(.system(size: 10, weight: .semibold))
                        Text("管理全部")
                            .font(SottoFont.pixel(11))
                    }
                    .foregroundStyle(Color.sottoSecondary)
                    .padding(.horizontal, 10)
                    .frame(height: 26)
                    .background(Color.white.opacity(0.040))
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .stroke(Color.sottoPrimary.opacity(0.10), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .scaleEffect(hoverManageDocs ? 1.10 : 1.0)
                .animation(.spring(response: 0.28, dampingFraction: 0.70), value: hoverManageDocs)
                .onHover { hoverManageDocs = $0 }
            }

            VStack(spacing: 0) {
                if model.recentDocuments.isEmpty {
                    Text("最近准备过的提词稿会出现在这里。")
                        .font(SottoFont.pixel(12))
                        .foregroundStyle(Color.sottoMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 22)
                } else {
                    ForEach(Array(model.recentDocuments.prefix(3).enumerated()), id: \.element.id) { index, document in
                        RecentDocumentRow(document: document, index: index) {
                            model.open(document)
                        }
                    }
                }
            }
            .sottoEditorPanel(cornerRadius: 18)
        }
        .contentShape(Rectangle())
        .onTapGesture { tryDefocus() }
        .simultaneousGesture(TapGesture().onEnded { tryDefocus() })
    }

    private func confirmStageEntrance() {
        guard !model.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !stageSparking else { return }
        guard !reduceMotion else {
            model.createDocumentFromInput()
            return
        }

        stageSparking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            model.createDocumentFromInput()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            stageSparking = false
        }
    }

    private func handleFileURLs(_ urls: [URL]) {
        var newText = model.inputText
        for url in urls {
            do {
                let extracted = try FileTextExtractor.extractText(from: url)
                if !newText.isEmpty, !newText.hasSuffix("\n") {
                    newText += "\n"
                }
                newText += extracted
                if !newText.hasSuffix("\n") {
                    newText += "\n"
                }
            } catch {
                model.showError("\(url.lastPathComponent): \(error.localizedDescription)")
            }
        }
        model.inputText = newText
        if !newText.isEmpty {
            isInputFocused = true
        }
    }

    private var aiOptionsPanel: some View {
        VStack(spacing: 10) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.sottoGlow)
                Text("AI 智能分析")
                    .font(SottoFont.pixel(11))
                    .foregroundStyle(Color.sottoPrimary)
                Spacer()
            }

            // Speed tier picker
            VStack(alignment: .leading, spacing: 4) {
                Text("语速")
                    .font(SottoFont.pixel(9))
                    .foregroundStyle(Color.sottoMuted)
                HStack(spacing: 6) {
                    ForEach(ScriptSpeedTier.allCases, id: \.self) { tier in
                        Button {
                            model.pipelineSpeedTier = tier
                        } label: {
                            Text(tier.shortLabel)
                                .font(SottoFont.pixel(10))
                                .foregroundStyle(model.pipelineSpeedTier == tier ? Color.sottoPrimary : Color.sottoSecondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 26)
                                .background(Color.sottoGlow.opacity(model.pipelineSpeedTier == tier ? 0.16 : 0.04))
                                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                                        .stroke(Color.sottoPrimary.opacity(model.pipelineSpeedTier == tier ? 0.28 : 0.08), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Main pipeline button
            Button {
                model.processScriptWithAiPipeline()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                        .font(.system(size: 10, weight: .medium))
                    Text("开始智能分析")
                        .font(SottoFont.pixel(11))
                }
                .foregroundStyle(Color.sottoPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(Color.sottoGlow.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.sottoGlow.opacity(0.22), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            // Legacy options (collapsible)
            DisclosureGroup {
                HStack(spacing: 6) {
                    Button {
                        model.analyzeScript(mode: .timeOnly)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 8, weight: .medium))
                            Text("仅解析时间")
                                .font(SottoFont.pixel(9))
                        }
                        .foregroundStyle(Color.sottoSecondary)
                        .padding(.horizontal, 8)
                        .frame(height: 22)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        model.analyzeScript(mode: .optimizeContent)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 8, weight: .medium))
                            Text("优化内容")
                                .font(SottoFont.pixel(9))
                        }
                        .foregroundStyle(Color.sottoSecondary)
                        .padding(.horizontal, 8)
                        .frame(height: 22)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            } label: {
                Text("更多选项")
                    .font(SottoFont.pixel(9))
                    .foregroundStyle(Color.sottoMuted)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.sottoGlow.opacity(0.18), lineWidth: 1)
        )
    }

    private var aiAnalyzingIndicator: some View {
        HStack(spacing: 10) {
            ProgressView()
                .scaleEffect(0.6)
                .frame(width: 16, height: 16)
            Text(model.pipelineProgressLabel.isEmpty ? "AI 正在分析稿件..." : model.pipelineProgressLabel)
                .font(SottoFont.pixel(11))
                .foregroundStyle(Color.sottoSecondary)
            Spacer()
            Button {
                if !model.pipelineProgressLabel.isEmpty {
                    model.cancelPipeline()
                } else {
                    model.cancelAnalysis()
                }
            } label: {
                Text("取消")
                    .font(SottoFont.pixel(10))
                    .foregroundStyle(Color.sottoSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            UTType(filenameExtension: "md"),
            UTType(filenameExtension: "txt"),
            UTType(filenameExtension: "doc"),
            UTType(filenameExtension: "docx"),
        ].compactMap { $0 }
        panel.allowsMultipleSelection = true
        panel.message = "选择文稿文件（.md / .txt / .doc / .docx）"
        panel.begin { response in
            guard response == .OK else { return }
            handleFileURLs(panel.urls)
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
    @EnvironmentObject private var model: AppModel
    @State private var menuOpen = false
    @State private var isHovering = false

    private var initials: String {
        let letters = ["T", "N", "C"]
        return letters[index % letters.count]
    }

    private var status: (String, Color) {
        document.isArchived ? ("已归档", Color.sottoMuted) : ("可上场", .sottoGreen)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 16) {
                Button(action: action) {
                    HStack(spacing: 16) {
                        PixelText(text: initials, size: 24, color: .sottoPrimary, dot: 1.8, spacing: 4)
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
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .scaleEffect(isHovering ? 1.02 : 1.0)
                .animation(.spring(response: 0.28, dampingFraction: 0.70), value: isHovering)
                .onHover { isHovering = $0 }

                Button {
                    menuOpen.toggle()
                } label: {
                    Image(systemName: "ellipsis")
                        .font(SottoFont.pixel(16))
                        .foregroundStyle(Color.sottoSecondary)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(menuOpen ? 0.08 : 0.025))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)

            if menuOpen {
                RecentDocumentStackMenu(
                    open: {
                        menuOpen = false
                        action()
                    },
                    copyToInput: {
                        menuOpen = false
                        model.copyRecentDocumentToInput(document)
                    },
                    remove: {
                        menuOpen = false
                        model.removeRecentDocument(document)
                    }
                )
                .offset(x: -4, y: 44)
                .transition(.opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.94, anchor: .topTrailing)))
                .zIndex(5)
            }
        }
        .animation(.spring(response: 0.30, dampingFraction: 0.78), value: menuOpen)
    }
}

private struct RecentDocumentStackMenu: View {
    let open: () -> Void
    let copyToInput: () -> Void
    let remove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.sottoGlow.opacity(0.11))
                .frame(width: 154, height: 96)
                .offset(x: -10, y: 12)
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.sottoPrimary.opacity(0.045))
                .frame(width: 162, height: 104)
                .offset(x: -5, y: 6)

            VStack(spacing: 4) {
                menuButton("打开", systemName: "arrow.up.right", action: open)
                menuButton("放回入口", systemName: "text.append", action: copyToInput)
                menuButton("移除", systemName: "xmark", action: remove, color: .sottoRed)
            }
            .padding(8)
            .frame(width: 170)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(red: 0.060, green: 0.056, blue: 0.050).opacity(0.97))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.sottoPrimary.opacity(0.16), lineWidth: 1)
            )
            .shadow(color: Color.sottoGlow.opacity(0.18), radius: 18, y: 8)
        }
    }

    private func menuButton(_ title: String, systemName: String, action: @escaping () -> Void, color: Color = .sottoPrimary) -> some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: systemName)
                    .font(SottoFont.pixel(11))
                    .frame(width: 16)
                Text(title)
                    .font(SottoFont.pixel(12))
                Spacer()
            }
            .foregroundStyle(color.opacity(0.90))
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .background(Color.white.opacity(0.035))
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
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
