import SwiftUI
import SottoCore

struct EditorView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 14) {
                header

                HStack(alignment: .top, spacing: 14) {
                    recognizedSentences
                        .frame(width: 430)
                        .frame(maxHeight: .infinity)

                    VStack(spacing: 14) {
                        SegmentPanelView()
                            .frame(height: 252)

                        SpotlightPreviewView()
                            .frame(height: 350)
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 616)
            }

            if model.showRhythmReadyAnnouncement {
                rhythmReadyAnnouncement
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .padding(.top, 56)
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 34)
        .padding(.bottom, 22)
        .onChange(of: model.showRhythmReadyAnnouncement) { _, visible in
            scheduleAnnouncementDismissal(visible)
        }
        .onAppear {
            scheduleAnnouncementDismissal(model.showRhythmReadyAnnouncement)
        }
        .animation(.easeOut(duration: SottoMotionTokens.duration(0.32, reduceMotion: reduceMotion)), value: model.showRhythmReadyAnnouncement)
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
                HStack(spacing: 8) {
                    Image(systemName: "play.rectangle.fill")
                        .font(SottoFont.pixel(15))
                    Text("提词")
                        .font(SottoFont.pixel(13))
                }
                .frame(width: 78, height: 32)
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("已识别句子", systemImage: "text.alignleft")
                    .font(SottoFont.pixel(16))
                    .foregroundStyle(Color.sottoPrimary)
                Spacer()
                Text("\(model.currentDocument?.sentences.count ?? 0) 句")
                    .font(SottoFont.pixel(11))
                    .foregroundStyle(Color.sottoMuted)
            }

            if let document = model.currentDocument {
                ZStack {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 8) {
                            ForEach(Array(document.sentences.enumerated()), id: \.element.id) { index, sentence in
                                Button {
                                    model.selectSentence(sentence)
                                } label: {
                                    recognizedSentenceRow(sentence, index: index)
                                }
                                .buttonStyle(.plain)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)

                    SottoProgressiveEdgeFade(edges: [.top, .bottom], height: 34, strength: 0.72)
                }
            } else {
                Text("暂无可编辑句子。")
                    .font(SottoFont.pixel(13))
                    .foregroundStyle(Color.sottoMuted)
            }
        }
        .sottoEditorPanel(cornerRadius: 16)
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
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(selected ? Color.sottoGlow.opacity(0.18) : Color.white.opacity(0.035))
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(selected ? Color.sottoPrimary.opacity(0.18) : Color.clear, lineWidth: 1)
        )
        .shadow(color: Color.sottoGlow.opacity(selected ? 0.16 : 0), radius: 14)
        .animation(.easeOut(duration: 0.20), value: selected)
    }

    private var rhythmReadyAnnouncement: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.sottoGreen)
                .frame(width: 8, height: 8)
                .shadow(color: Color.sottoGreen.opacity(0.54), radius: 8)

            VStack(alignment: .leading, spacing: 3) {
                Text("节奏已整理好")
                    .font(SottoFont.pixel(15))
                    .tracking(1.2)
                    .foregroundStyle(Color.sottoPrimary)
                Text("可以先微调切分，再打开提词窗口。")
                    .font(SottoFont.pixel(11))
                    .foregroundStyle(Color.sottoSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.070, green: 0.066, blue: 0.056).opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.sottoPrimary.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: Color.sottoGlow.opacity(0.20), radius: 18, y: 8)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func scheduleAnnouncementDismissal(_ visible: Bool) {
        guard visible else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            if model.showRhythmReadyAnnouncement {
                model.showRhythmReadyAnnouncement = false
            }
        }
    }
}
