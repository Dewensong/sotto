import SwiftUI
import SottoCore

struct EditorView: View {
    @EnvironmentObject private var model: AppModel
    @State private var lowerPanel = "节奏"

    var body: some View {
        VStack(spacing: 10) {
            header

            scriptEditor
                .frame(height: 265)

            Picker("面板", selection: $lowerPanel) {
                Text("节奏").tag("节奏")
                Text("预览").tag("预览")
            }
            .pickerStyle(.segmented)
            .font(SottoFont.pixel(12))
            .tint(Color.sottoPrimary)

            if lowerPanel == "节奏" {
                SegmentPanelView()
                    .frame(height: 390)
            } else {
                SpotlightPreviewView()
                    .frame(height: 390)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 24)
        .padding(.bottom, 14)
    }

    private var header: some View {
        HStack {
            Button {
                model.returnHome()
            } label: {
                Label("后台", systemImage: "chevron.left")
                    .font(SottoFont.pixel(13))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.sottoSecondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(model.currentDocument?.title ?? "新的提词稿")
                    .font(SottoFont.pixel(16))
                    .foregroundStyle(Color.sottoPrimary)
                Text("稿件准备台")
                    .font(SottoFont.pixel(10))
                    .foregroundStyle(Color.sottoMuted)
            }

            Spacer()

            Button {
                model.openTeleprompter()
            } label: {
                Image(systemName: "rectangle.on.rectangle")
                    .font(SottoFont.pixel(16))
                    .frame(width: 44, height: 32)
                    .foregroundStyle(Color.sottoPrimary)
                    .background(Color.sottoPrimary.opacity(0.09))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.sottoPrimary.opacity(0.16), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(height: 42)
    }

    private var scriptEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("主稿件")
                .font(SottoFont.pixel(14))
                .foregroundStyle(Color.sottoPrimary)

            TextEditor(text: Binding(
                get: { model.currentDocument?.rawText ?? "" },
                set: { model.updateRawText($0) }
            ))
            .font(SottoFont.pixel(14))
            .scrollContentBackground(.hidden)
            .foregroundStyle(Color.sottoPrimary)
            .padding(12)
            .frame(minHeight: 142)
            .background(.black.opacity(0.20))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.09), lineWidth: 1)
            )

            if let document = model.currentDocument {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(document.sentences) { sentence in
                            Button {
                                model.selectSentence(sentence)
                            } label: {
                                Text(sentence.text)
                                    .lineLimit(1)
                                    .font(SottoFont.pixel(10))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(sentence.id == model.selectedSentenceID ? Color.sottoGlow.opacity(0.22) : .white.opacity(0.05))
                                    .foregroundStyle(sentence.id == model.selectedSentenceID ? Color.sottoPrimary : Color.sottoSecondary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .sottoPanel()
    }
}
