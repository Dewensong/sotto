import SwiftUI

extension Color {
    static let sottoPrimary = Color(red: 0.94, green: 0.91, blue: 0.84)
    static let sottoSecondary = Color(red: 0.73, green: 0.70, blue: 0.64)
    static let sottoMuted = Color(red: 0.48, green: 0.47, blue: 0.43)
    static let sottoGlow = Color(red: 0.83, green: 0.78, blue: 0.58)
}

struct SottoBackground: View {
    var isSubtle = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.035, green: 0.034, blue: 0.032),
                    Color(red: 0.075, green: 0.067, blue: 0.055),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            DotPattern(opacity: isSubtle ? 0.10 : 0.18)
            RadialGradient(
                colors: [Color.sottoGlow.opacity(isSubtle ? 0.12 : 0.20), .clear],
                center: .top,
                startRadius: 20,
                endRadius: 520
            )
        }
        .ignoresSafeArea()
    }
}

private struct DotPattern: View {
    let opacity: Double

    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                let spacing: CGFloat = 18
                let columns = Int(size.width / spacing)
                let rows = Int(size.height / spacing)
                for row in 0...rows {
                    for column in 0...columns {
                        let rect = CGRect(x: CGFloat(column) * spacing, y: CGFloat(row) * spacing, width: 1.4, height: 1.4)
                        context.fill(Path(ellipseIn: rect), with: .color(.sottoPrimary.opacity(opacity)))
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .allowsHitTesting(false)
    }
}

extension View {
    func sottoPanel() -> some View {
        self
            .padding(20)
            .background(.white.opacity(0.055))
            .background(.ultraThinMaterial.opacity(0.28))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.10), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.24), radius: 22, y: 12)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 300
        var origin = CGPoint.zero
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if origin.x + size.width > width {
                origin.x = 0
                origin.y += rowHeight + spacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            origin.x += size.width + spacing
        }

        return CGSize(width: width, height: origin.y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var origin = bounds.origin
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if origin.x + size.width > bounds.maxX {
                origin.x = bounds.minX
                origin.y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: origin, proposal: ProposedViewSize(size))
            rowHeight = max(rowHeight, size.height)
            origin.x += size.width + spacing
        }
    }
}
