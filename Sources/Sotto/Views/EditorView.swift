import SwiftUI
import SottoCore

struct EditorView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 18) {
            header

            HStack(alignment: .top, spacing: 18) {
                scriptEditor
                    .frame(width: 420, height: 625)
                SegmentPanelView()
                    .frame(width: 350, height: 625)
                SpotlightPreviewView()
                    .frame(width: 430, height: 625)
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 78)
        .padding(.bottom, 20)
    }

    private var header: some View {
        HStack(spacing: 18) {
            Button {
                model.returnHome()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                    Text("后台")
                }
                .font(SottoFont.pixel(14))
                .frame(width: 86, height: 42)
                .background(Color.white.opacity(0.045))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.sottoPrimary.opacity(0.14), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.sottoSecondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(model.currentDocument?.title ?? "新的提词稿")
                    .font(SottoFont.pixel(22))
                    .foregroundStyle(Color.sottoPrimary)
                    .lineLimit(1)
                Text("稿件准备台")
                    .font(SottoFont.pixel(12))
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
        .frame(height: 54)
    }

    private var scriptEditor: some View {
        SottoGlassPanel(role: .workbench) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("主稿件", systemImage: "doc.text")
                        .font(SottoFont.pixel(18))
                        .foregroundStyle(Color.sottoPrimary)
                    Spacer()
                    Text("句子切分")
                        .font(SottoFont.pixel(11))
                        .foregroundStyle(Color.sottoMuted)
                }

                TextEditor(text: Binding(
                    get: { model.currentDocument?.rawText ?? "" },
                    set: { model.updateRawText($0) }
                ))
                .font(SottoFont.pixel(16))
                .scrollContentBackground(.hidden)
                .foregroundStyle(Color.sottoPrimary)
                .padding(18)
                .frame(height: 330)
                .background(.black.opacity(0.20))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.09), lineWidth: 1)
                )

                if let document = model.currentDocument {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("已识别句子")
                            .font(SottoFont.pixel(13))
                            .foregroundStyle(Color.sottoSecondary)

                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 9) {
                                ForEach(document.sentences) { sentence in
                                    Button {
                                        model.selectSentence(sentence)
                                    } label: {
                                        Text(sentence.text)
                                            .lineLimit(2)
                                            .font(SottoFont.pixel(13))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(sentence.id == model.selectedSentenceID ? Color.sottoGlow.opacity(0.24) : .white.opacity(0.05))
                                            .foregroundStyle(sentence.id == model.selectedSentenceID ? Color.sottoPrimary : Color.sottoSecondary)
                                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .frame(maxHeight: .infinity)
                    }
                }
            }
        }
    }
}
