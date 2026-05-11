import SwiftUI
import SottoCore

struct DocumentManagerView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 16) {
            header
            filterTabBar
            libraryPanel
        }
        .padding(.horizontal, 28)
        .padding(.top, 42)
        .padding(.bottom, 28)
        .onAppear {
            model.loadRecentDocuments()
        }
    }

    private var header: some View {
        HStack(spacing: 18) {
            BackToHomeButton {
                model.closeDocumentManager()
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("稿件管理")
                    .font(SottoFont.pixel(24))
                    .foregroundStyle(Color.sottoPrimary)
                Text("管理所有已经准备过的提词稿")
                    .font(SottoFont.pixel(12))
                    .foregroundStyle(Color.sottoMuted)
            }

            Spacer()

            SottoStatusBadge(title: "\(model.recentDocuments.count) 篇")
                .scaleEffect(0.72, anchor: .trailing)
        }
        .frame(height: 54)
    }

    // MARK: Filter tabs

    private var filterTabBar: some View {
        HStack(spacing: 8) {
            ForEach(AppModel.DocumentFilter.allCases, id: \.rawValue) { filter in
                FilterPill(
                    title: filter.title,
                    count: filter.count(in: model),
                    isSelected: model.documentFilter == filter
                ) {
                    model.setDocumentFilter(filter)
                }
            }
            Spacer()
        }
    }

    // MARK: Document list

    private var libraryPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            if model.recentDocuments.isEmpty {
                emptyState
            } else if model.filteredDocuments.isEmpty {
                filteredEmptyState
            } else {
                ZStack {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 9) {
                            ForEach(Array(model.filteredDocuments.enumerated()), id: \.element.id) { index, document in
                                ManagedDocumentRow(document: document, index: index)
                                    .environmentObject(model)
                                    .transition(.opacity.combined(with: .blurReplace))
                            }
                        }
                        .animation(.easeOut(duration: 0.22), value: model.documentFilter)
                    }

                    SottoProgressiveEdgeFade(edges: [.top, .bottom], height: 34, strength: 0.68)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray.full")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(Color.sottoPrimary.opacity(0.78))
                .frame(width: 54, height: 58)
                .opacity(0.72)
            Text("还没有稿件")
                .font(SottoFont.pixel(16))
                .foregroundStyle(Color.sottoPrimary)
            Text("从首页粘贴稿件并进入准备上场后，会自动保存到这里。")
                .font(SottoFont.pixel(12))
                .foregroundStyle(Color.sottoMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var filteredEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: model.documentFilter == .archived ? "archivebox" : "tray.full")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(Color.sottoPrimary.opacity(0.78))
                .frame(width: 54, height: 58)
                .opacity(0.72)
            Text(model.documentFilter == .archived ? "没有已归档的稿件" : "没有未归档的稿件")
                .font(SottoFont.pixel(16))
                .foregroundStyle(Color.sottoPrimary)
            Text(model.documentFilter == .archived
                 ? "在未归档列表中点击「归档」按钮即可将稿件移到这里。"
                 : "从首页粘贴稿件并进入准备上场后，会自动保存到这里。")
                .font(SottoFont.pixel(12))
                .foregroundStyle(Color.sottoMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Filter pill

private struct FilterPill: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isSelected {
                    Circle()
                        .fill(Color.sottoGlow)
                        .frame(width: 5, height: 5)
                        .shadow(color: Color.sottoGlow.opacity(0.6), radius: 4)
                }
                Text(title)
                    .font(SottoFont.pixel(12))
                    .tracking(1.0)
                Text("\(count)")
                    .font(SottoFont.pixel(11))
                    .tracking(0.6)
                    .foregroundStyle(isSelected ? Color.sottoPrimary.opacity(0.7) : Color.sottoMuted)
            }
            .foregroundStyle(isSelected ? Color.sottoPrimary : Color.sottoMuted)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(backgroundFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(color: Color.sottoGlow.opacity(isSelected ? 0.10 : 0), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(SottoMotionTokens.hover, value: hovering)
        .animation(SottoMotionTokens.hover, value: isSelected)
    }

    private var backgroundFill: Color {
        if isSelected {
            Color.sottoGlow.opacity(0.14)
        } else if hovering {
            Color.white.opacity(0.04)
        } else {
            .clear
        }
    }

    private var borderColor: Color {
        if isSelected {
            Color.sottoPrimary.opacity(0.24)
        } else if hovering {
            Color.sottoPrimary.opacity(0.10)
        } else {
            Color.sottoPrimary.opacity(0.05)
        }
    }
}

// MARK: - Document row

private struct ManagedDocumentRow: View {
    let document: PromptDocument
    let index: Int
    @EnvironmentObject private var model: AppModel
    @State private var rowHovering = false

    var body: some View {
        HStack(spacing: 14) {
            Text(String(format: "%02d", index + 1))
                .font(SottoFont.pixel(13))
                .foregroundStyle(Color.sottoMuted)
                .frame(width: 34, alignment: .leading)

            Button {
                model.open(document)
            } label: {
                VStack(alignment: .leading, spacing: 7) {
                    Text(document.title)
                        .font(SottoFont.pixel(15))
                        .foregroundStyle(Color.sottoPrimary)
                        .lineLimit(1)
                    Text(document.rawText)
                        .font(SottoFont.pixel(11))
                        .foregroundStyle(Color.sottoSecondary.opacity(0.72))
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            VStack(alignment: .trailing, spacing: 8) {
                Text(document.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(SottoFont.pixel(10))
                    .foregroundStyle(Color.sottoMuted)

                HStack(spacing: 6) {
                    ManagedActionButton(
                        title: "打开",
                        systemImage: "arrow.up.right"
                    ) {
                        model.open(document)
                    }
                    ManagedActionButton(
                        title: "放映",
                        systemImage: "play.fill"
                    ) {
                        model.open(document)
                        model.openTeleprompter()
                    }
                    ManagedActionButton(
                        title: document.isArchived ? "取消" : "归档",
                        systemImage: document.isArchived ? "archivebox.fill" : "archivebox"
                    ) {
                        model.toggleArchive(document)
                    }
                    ManagedActionButton(
                        title: "删除",
                        systemImage: "trash",
                        color: .sottoRed
                    ) {
                        model.removeRecentDocument(document)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(Color.white.opacity(rowHovering ? 0.06 : 0.035))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(Color.sottoPrimary.opacity(rowHovering ? 0.16 : 0.07), lineWidth: 1)
        )
        .shadow(color: Color.sottoGlow.opacity(rowHovering ? 0.08 : 0), radius: 12, y: 4)
        .onHover { rowHovering = $0 }
        .animation(SottoMotionTokens.hover, value: rowHovering)
    }
}

// MARK: - Reusable subviews

private struct BackToHomeButton: View {
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                    .offset(x: hovering ? -2 : 0)
                Text("首页")
            }
            .font(SottoFont.pixel(14))
            .frame(width: 86, height: 42)
            .foregroundStyle(hovering ? Color.sottoPrimary : Color.sottoSecondary)
            .background(Color.white.opacity(hovering ? 0.08 : 0.045))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.sottoPrimary.opacity(hovering ? 0.28 : 0.14), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(SottoMotionTokens.hover, value: hovering)
    }
}

private struct ManagedActionButton: View {
    let title: String
    let systemImage: String
    var color: Color = .sottoSecondary
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .semibold))
                Text(title)
                    .font(SottoFont.pixel(10))
            }
            .foregroundStyle(hovering && color == .sottoSecondary ? Color.sottoPrimary : color)
            .padding(.horizontal, 8)
            .frame(height: 25)
            .fixedSize(horizontal: true, vertical: false)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(hovering ? color.opacity(0.12) : Color.white.opacity(0.040))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(color.opacity(hovering ? 0.30 : 0), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(SottoMotionTokens.hover, value: hovering)
    }
}

// MARK: - Filter helpers

private extension AppModel.DocumentFilter {
    var title: String {
        switch self {
        case .all: "全部"
        case .unarchived: "未归档"
        case .archived: "已归档"
        }
    }

    @MainActor func count(in model: AppModel) -> Int {
        switch self {
        case .all: model.recentDocuments.count
        case .unarchived: model.recentDocuments.filter { !$0.isArchived }.count
        case .archived: model.recentDocuments.filter { $0.isArchived }.count
        }
    }
}
