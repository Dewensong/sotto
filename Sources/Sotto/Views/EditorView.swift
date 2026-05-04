import SwiftUI
import SottoCore

struct EditorView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 18) {
                header

                HStack(alignment: .top, spacing: 18) {
                    recognizedSentences
                        .frame(width: 510, height: 340)
                    SegmentPanelView()
                        .frame(width: 734, height: 340)
                }

                SpotlightPreviewView()
                    .frame(height: 360)
            }
            .padding(.horizontal, 28)
            .padding(.top, 56)
            .padding(.bottom, 24)
        }
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

    private var recognizedSentences: some View {
        SottoGlassPanel(role: .workbench) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("已识别句子", systemImage: "text.alignleft")
                        .font(SottoFont.pixel(18))
                        .foregroundStyle(Color.sottoPrimary)
                    Spacer()
                    Text("\(model.currentDocument?.sentences.count ?? 0) 句")
                        .font(SottoFont.pixel(11))
                        .foregroundStyle(Color.sottoMuted)
                }

                if let document = model.currentDocument {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 10) {
                            ForEach(Array(document.sentences.enumerated()), id: \.element.id) { index, sentence in
                                Button {
                                    model.selectSentence(sentence)
                                } label: {
                                    recognizedSentenceRow(sentence, index: index)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    Text("暂无可编辑句子。")
                        .font(SottoFont.pixel(13))
                        .foregroundStyle(Color.sottoMuted)
                }
            }
        }
    }

    private func recognizedSentenceRow(_ sentence: SentenceSegment, index: Int) -> some View {
        let selected = sentence.id == model.selectedSentenceID

        return HStack(alignment: .top, spacing: 14) {
            Text(String(format: "%02d", index + 1))
                .font(SottoFont.pixel(13))
                .foregroundStyle(selected ? Color.sottoPrimary : Color.sottoMuted)
                .frame(width: 34, alignment: .leading)

            Text(sentence.text)
                .lineLimit(3)
                .font(SottoFont.pixel(selected ? 15 : 13))
                .foregroundStyle(selected ? Color.sottoPrimary : Color.sottoSecondary.opacity(0.78))
                .frame(maxWidth: .infinity, alignment: .leading)

            Circle()
                .fill(selected ? Color.sottoPrimary : Color.sottoMuted.opacity(0.36))
                .frame(width: selected ? 9 : 6, height: selected ? 9 : 6)
                .padding(.top, 6)
                .shadow(color: Color.sottoGlow.opacity(selected ? 0.6 : 0), radius: 10)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(selected ? Color.sottoGlow.opacity(0.20) : Color.white.opacity(0.045))
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(selected ? Color.sottoPrimary.opacity(0.34) : Color.white.opacity(0.04), lineWidth: 1)
        )
    }
}
