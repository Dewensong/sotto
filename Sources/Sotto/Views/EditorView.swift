import SwiftUI
import SottoCore

struct EditorView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 18) {
            header

            HStack(spacing: 18) {
                scriptEditor
                    .frame(minWidth: 520)
                SegmentPanelView()
                    .frame(width: 330)
            }

            SpotlightPreviewView()
                .frame(height: 190)
        }
        .padding(28)
    }

    private var header: some View {
        HStack {
            Button {
                model.returnHome()
            } label: {
                Label("后台", systemImage: "chevron.left")
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.sottoSecondary)

            VStack(alignment: .leading, spacing: 3) {
                Text(model.currentDocument?.title ?? "新的提词稿")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color.sottoPrimary)
                Text("稿件准备台")
                    .font(.caption)
                    .foregroundStyle(Color.sottoMuted)
            }

            Spacer()

            Picker("速度", selection: Binding(
                get: { model.timing },
                set: { model.setTiming($0) }
            )) {
                ForEach(TimingProfile.allCases) { profile in
                    Text(profile.title).tag(profile)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 210)

            Button("重新切分") {
                model.resegmentCurrentDocument()
            }
            .buttonStyle(.bordered)

            Button {
                model.openTeleprompter()
            } label: {
                Label("打开提词窗口", systemImage: "rectangle.on.rectangle")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var scriptEditor: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("主稿件")
                .font(.headline)
                .foregroundStyle(Color.sottoPrimary)

            TextEditor(text: Binding(
                get: { model.currentDocument?.rawText ?? "" },
                set: { model.updateRawText($0) }
            ))
            .font(.system(size: 17, design: .rounded))
            .scrollContentBackground(.hidden)
            .foregroundStyle(Color.sottoPrimary)
            .padding(12)
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
                                    .font(.caption)
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
