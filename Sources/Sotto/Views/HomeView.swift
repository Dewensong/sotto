import SwiftUI
import SottoCore

struct HomeView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        HStack(spacing: 28) {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sotto")
                        .font(.system(size: 72, weight: .semibold, design: .serif))
                        .foregroundStyle(Color.sottoPrimary)
                    Text("a quiet backstage for speaking well")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.sottoSecondary)
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("今天想让哪段想法上场？")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Color.sottoPrimary)
                    Text("把已经写好的稿子放进来，我会帮你整理成适合提词的节奏。")
                        .foregroundStyle(Color.sottoSecondary)

                    TextEditor(text: $model.inputText)
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .scrollContentBackground(.hidden)
                        .foregroundStyle(Color.sottoPrimary)
                        .padding(14)
                        .frame(minHeight: 300)
                        .background(.black.opacity(0.22))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(.white.opacity(0.10), lineWidth: 1)
                        )
                }
                .sottoPanel()

                HStack(spacing: 12) {
                    Button {
                        model.createDocumentFromInput()
                    } label: {
                        Label("ON STAGE", systemImage: "play.fill")
                            .font(.system(size: 15, weight: .bold))
                            .padding(.horizontal, 22)
                            .padding(.vertical, 13)
                    }
                    .buttonStyle(.plain)
                    .background(Color.sottoGlow.opacity(0.22))
                    .foregroundStyle(Color.sottoPrimary)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.sottoGlow.opacity(0.42), lineWidth: 1))
                    .disabled(model.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Text("READY.")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.sottoGlow)
                }
            }
            .frame(maxWidth: 680)

            RecentDocumentsView()
                .frame(width: 320)
        }
        .padding(42)
    }
}

private struct RecentDocumentsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("最近稿件")
                .font(.headline)
                .foregroundStyle(Color.sottoPrimary)

            if model.recentDocuments.isEmpty {
                Text("这里会保留最近准备过的提词稿。")
                    .foregroundStyle(Color.sottoMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 24)
            } else {
                ForEach(model.recentDocuments) { document in
                    Button {
                        model.open(document)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(document.title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.sottoPrimary)
                                .lineLimit(1)
                            Text("\(document.sentences.count) 句 · \(document.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(Color.sottoMuted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(.white.opacity(0.045))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sottoPanel()
    }
}
