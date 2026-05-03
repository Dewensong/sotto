import SwiftUI

extension Color {
    static let sottoInk = Color(red: 0.025, green: 0.024, blue: 0.022)
    static let sottoPanel = Color(red: 0.10, green: 0.095, blue: 0.085)
    static let sottoPrimary = Color(red: 0.96, green: 0.925, blue: 0.84)
    static let sottoSecondary = Color(red: 0.70, green: 0.67, blue: 0.60)
    static let sottoMuted = Color(red: 0.43, green: 0.41, blue: 0.36)
    static let sottoGlow = Color(red: 0.94, green: 0.86, blue: 0.62)
    static let sottoGreen = Color(red: 0.21, green: 0.95, blue: 0.64)
}

enum SottoPanelRole {
    case hero
    case workbench
    case prompt
    case utility

    var cornerRadius: CGFloat {
        switch self {
        case .hero: 22
        case .workbench: 18
        case .prompt: 30
        case .utility: 16
        }
    }

    var glow: Double {
        switch self {
        case .hero: 0.34
        case .workbench: 0.16
        case .prompt: 0.42
        case .utility: 0.12
        }
    }
}

struct SottoStageBackground: View {
    var intensity: Double = 1

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.055, green: 0.050, blue: 0.043),
                    Color.sottoInk
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            DotField(spacing: 16, dotSize: 1.25, opacity: 0.23 * intensity)

            RadialGradient(
                colors: [
                    Color.sottoGlow.opacity(0.42 * intensity),
                    Color.sottoGlow.opacity(0.12 * intensity),
                    .clear
                ],
                center: .top,
                startRadius: 18,
                endRadius: 560
            )
            .blendMode(.screen)

            LinearGradient(
                colors: [
                    .white.opacity(0.30 * intensity),
                    .white.opacity(0.05 * intensity),
                    .clear
                ],
                startPoint: .top,
                endPoint: .center
            )
            .frame(maxHeight: .infinity, alignment: .top)
            .blur(radius: 18)

            VStack {
                Spacer()
                SottoRhythmLine(amplitude: 0.55, opacity: 0.20 * intensity)
                    .frame(height: 120)
                    .blur(radius: 0.6)
                    .padding(.horizontal, 60)
                    .padding(.bottom, 20)
            }
        }
        .ignoresSafeArea()
    }
}

struct SottoGlassPanel<Content: View>: View {
    var role: SottoPanelRole = .workbench
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(panelPadding)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: role.cornerRadius, style: .continuous)
                        .fill(panelFill)
                    if role != .prompt {
                        RoundedRectangle(cornerRadius: role.cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial.opacity(0.16))
                    }
                    DotField(spacing: 14, dotSize: 1.05, opacity: role == .prompt ? 0.11 : 0.075)
                        .clipShape(RoundedRectangle(cornerRadius: role.cornerRadius, style: .continuous))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: role.cornerRadius, style: .continuous)
                    .stroke(Color.sottoPrimary.opacity(0.22), lineWidth: 1)
            )
            .shadow(color: Color.sottoGlow.opacity(role.glow), radius: role == .prompt ? 28 : 18)
            .shadow(color: .black.opacity(0.35), radius: 24, y: 14)
    }

    private var panelPadding: CGFloat {
        switch role {
        case .hero: 16
        case .workbench: 14
        case .prompt: 22
        case .utility: 12
        }
    }

    private var panelFill: Color {
        switch role {
        case .hero:
            Color.sottoPanel.opacity(0.56)
        case .prompt:
            Color(red: 0.055, green: 0.052, blue: 0.046).opacity(0.96)
        case .workbench, .utility:
            Color.sottoPanel.opacity(0.48)
        }
    }
}

struct PixelText: View {
    let text: String
    var size: CGFloat
    var weight: Font.Weight = .regular
    var color: Color = .sottoPrimary
    var dot: CGFloat = 2
    var spacing: CGFloat = 6
    var tracking: CGFloat = 1
    var lineLimit: Int?

    var body: some View {
        dotFill
            .mask(label.foregroundStyle(.white))
            .overlay(label.foregroundStyle(color.opacity(0.18)).blur(radius: 0.15))
            .shadow(color: color.opacity(0.30), radius: 8)
            .accessibilityLabel(Text(text))
    }

    private var label: some View {
        Text(text)
            .font(SottoFont.pixel(size))
            .tracking(tracking)
            .lineSpacing(size * 0.18)
            .lineLimit(lineLimit)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var dotFill: some View {
        GeometryReader { proxy in
            Canvas { context, canvasSize in
                let columns = Int(canvasSize.width / spacing) + 2
                let rows = Int(canvasSize.height / spacing) + 2
                for row in 0...rows {
                    for column in 0...columns {
                        let rect = CGRect(
                            x: CGFloat(column) * spacing,
                            y: CGFloat(row) * spacing,
                            width: dot,
                            height: dot
                        )
                        context.fill(Path(ellipseIn: rect), with: .color(color))
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

struct SottoStatusBadge: View {
    let title: String
    var color: Color = .sottoGreen

    var body: some View {
        HStack(spacing: 9) {
            Circle()
                .fill(color)
                .frame(width: 9, height: 9)
                .shadow(color: color.opacity(0.75), radius: 8)
            Text(title)
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .tracking(2.6)
        }
        .foregroundStyle(color)
    }
}

struct SottoRhythmLine: View {
    var amplitude: Double = 1
    var opacity: Double = 0.35

    var body: some View {
        Canvas { context, size in
            let midY = size.height / 2
            let step: CGFloat = 9
            let count = Int(size.width / step)
            for index in 0...count {
                let x = CGFloat(index) * step
                let wave = abs(sin(Double(index) * 0.43)) * amplitude
                let height = CGFloat(6 + wave * 34)
                let rect = CGRect(x: x, y: midY - height / 2, width: 1.2, height: height)
                context.fill(Path(roundedRect: rect, cornerRadius: 1), with: .color(.sottoPrimary.opacity(opacity)))
            }

            var baseline = Path()
            baseline.move(to: CGPoint(x: 0, y: midY))
            baseline.addLine(to: CGPoint(x: size.width, y: midY))
            context.stroke(baseline, with: .color(.sottoPrimary.opacity(opacity * 0.45)), lineWidth: 1)
        }
        .allowsHitTesting(false)
    }
}

struct SottoIconButton: View {
    let systemName: String
    var title: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemName)
                if let title {
                    Text(title)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .tracking(1.4)
                }
            }
            .frame(minWidth: title == nil ? 42 : 86, minHeight: 34)
            .foregroundStyle(Color.sottoPrimary.opacity(0.86))
            .background(Color.white.opacity(0.045))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.sottoPrimary.opacity(0.16), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct DotField: View {
    var spacing: CGFloat = 18
    var dotSize: CGFloat = 1.2
    var opacity: Double = 0.18

    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                let columns = Int(size.width / spacing)
                let rows = Int(size.height / spacing)
                for row in 0...rows {
                    for column in 0...columns {
                        let pulse = ((row + column) % 7 == 0) ? 1.8 : 1
                        let rect = CGRect(
                            x: CGFloat(column) * spacing,
                            y: CGFloat(row) * spacing,
                            width: dotSize * pulse,
                            height: dotSize * pulse
                        )
                        context.fill(Path(ellipseIn: rect), with: .color(.sottoPrimary.opacity(opacity / pulse)))
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
        SottoGlassPanel(role: .workbench) {
            self
        }
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
