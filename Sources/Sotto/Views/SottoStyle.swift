import SwiftUI

extension Color {
    static let sottoInk = Color(red: 0.025, green: 0.024, blue: 0.022)
    static let sottoPanel = Color(red: 0.10, green: 0.095, blue: 0.085)
    static let sottoPrimary = Color(red: 0.96, green: 0.925, blue: 0.84)
    static let sottoSecondary = Color(red: 0.70, green: 0.67, blue: 0.60)
    static let sottoMuted = Color(red: 0.43, green: 0.41, blue: 0.36)
    static let sottoGlow = Color(red: 0.94, green: 0.86, blue: 0.62)
    static let sottoGreen = Color(red: 0.21, green: 0.95, blue: 0.64)
    static let sottoRed = Color(red: 1.0, green: 0.24, blue: 0.20)
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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

            DotField(spacing: 16, dotSize: 1.25, opacity: 0.23 * intensity, drift: 1, animated: !reduceMotion)

            StageLightRays(intensity: intensity, isAnimated: !reduceMotion)

            VStack {
                Spacer()
                SottoAmbientMotionField(intensity: 0.46 * intensity, animated: !reduceMotion)
                    .frame(height: 120)
                    .blur(radius: 0.6)
                    .padding(.horizontal, 60)
                    .padding(.bottom, 20)
            }
        }
        .ignoresSafeArea()
    }
}

struct StageLightRays: View {
    var intensity: Double = 1
    var isAnimated = true

    private struct StageRay {
        let landing: CGFloat
        let topWidth: CGFloat
        let bottomWidth: CGFloat
        let reach: CGFloat
        let opacity: Double
        let delay: Double
    }

    private let rays: [StageRay] = [
        StageRay(landing: 0.17, topWidth: 7, bottomWidth: 76, reach: 0.58, opacity: 0.98, delay: 0.0),
        StageRay(landing: 0.39, topWidth: 9, bottomWidth: 92, reach: 0.67, opacity: 1.0, delay: 1.1),
        StageRay(landing: 0.61, topWidth: 9, bottomWidth: 92, reach: 0.67, opacity: 1.0, delay: 2.2),
        StageRay(landing: 0.83, topWidth: 7, bottomWidth: 76, reach: 0.58, opacity: 0.98, delay: 3.3)
    ]

    var body: some View {
        Group {
            if isAnimated {
                TimelineView(.animation) { timeline in
                    lightBody(time: timeline.date.timeIntervalSinceReferenceDate)
                }
            } else {
                lightBody(time: 0)
            }
        }
        .allowsHitTesting(false)
    }

    private func lightBody(time: TimeInterval) -> some View {
        let breath = 0.70 + 0.30 * sin(time * .pi / 4.8)
        let originDrift = isAnimated ? CGFloat(sin(time * .pi / 7.5) * 8) : 0

        return ZStack(alignment: .top) {
            Canvas { context, size in
                let origin = CGPoint(x: size.width / 2 + originDrift, y: -24)

                for ray in rays {
                    let localBreath = 0.62 + 0.38 * sin(time * .pi / 3.9 + ray.delay)
                    let landingDrift = isAnimated ? CGFloat(sin(time * .pi / 6.4 + ray.delay) * 10) : 0
                    let landingX = size.width * ray.landing + landingDrift
                    let endY = size.height * ray.reach
                    let baseOpacity = 0.26 * intensity * breath * localBreath * ray.opacity

                    drawRay(
                        context: &context,
                        topCenter: origin,
                        bottomCenter: CGPoint(x: landingX, y: endY),
                        topWidth: ray.topWidth,
                        bottomWidth: ray.bottomWidth,
                        color: Color.sottoGlow.opacity(baseOpacity),
                        feather: 1.0
                    )

                    drawRay(
                        context: &context,
                        topCenter: CGPoint(x: origin.x, y: -18),
                        bottomCenter: CGPoint(x: landingX, y: endY * 0.94),
                        topWidth: max(5, ray.topWidth * 0.34),
                        bottomWidth: ray.bottomWidth * 0.34,
                        color: Color.white.opacity(baseOpacity * 0.72),
                        feather: 0.62
                    )

                    drawRayTexture(
                        context: &context,
                        origin: origin,
                        landingX: landingX,
                        endY: endY,
                        ray: ray,
                        baseOpacity: baseOpacity,
                        time: time
                    )
                }

                let lampGlow = max(0.06, 0.16 * intensity * breath)
                let lampRect = CGRect(x: origin.x - 5, y: 9, width: 10, height: 10)
                context.fill(Path(ellipseIn: lampRect.insetBy(dx: -18, dy: -12)), with: .color(Color.sottoGlow.opacity(lampGlow * 0.20)))
                context.fill(Path(ellipseIn: lampRect), with: .color(Color.white.opacity(lampGlow)))
            }
            .blur(radius: 2.2)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            RadialGradient(
                colors: [
                    Color.sottoGlow.opacity(0.058 * intensity * breath),
                    Color.sottoGlow.opacity(0.022 * intensity * breath),
                    .clear
                ],
                center: .top,
                startRadius: 80,
                endRadius: 620
            )
            .blendMode(.screen)

            LinearGradient(
                colors: [
                    .white.opacity(0.042 * intensity * breath),
                    .white.opacity(0.014 * intensity * breath),
                    .clear
                ],
                startPoint: .top,
                endPoint: .center
            )
            .blur(radius: 10)
        }
    }

    private func drawRayTexture(
        context: inout GraphicsContext,
        origin: CGPoint,
        landingX: CGFloat,
        endY: CGFloat,
        ray: StageRay,
        baseOpacity: Double,
        time: TimeInterval
    ) {
        for index in 0..<3 {
            let strand = CGFloat(index - 1)
            let shimmer = CGFloat(sin(time * .pi / 5.6 + Double(index) * 1.7 + ray.delay) * 5)
            let bottomOffset = strand * ray.bottomWidth * 0.18 + shimmer

            drawRay(
                context: &context,
                topCenter: CGPoint(x: origin.x + strand * 1.8, y: -16),
                bottomCenter: CGPoint(x: landingX + bottomOffset, y: endY * (0.76 + CGFloat(index) * 0.06)),
                topWidth: 2.5 + CGFloat(index),
                bottomWidth: ray.bottomWidth * (0.08 + CGFloat(index) * 0.025),
                color: Color.white.opacity(baseOpacity * (0.18 + Double(index) * 0.04)),
                feather: 0.78
            )
        }
    }

    private func drawRay(
        context: inout GraphicsContext,
        topCenter: CGPoint,
        bottomCenter: CGPoint,
        topWidth: CGFloat,
        bottomWidth: CGFloat,
        color: Color,
        feather: CGFloat
    ) {
        var path = Path()
        path.move(to: CGPoint(x: topCenter.x - topWidth / 2, y: topCenter.y))
        path.addLine(to: CGPoint(x: topCenter.x + topWidth / 2, y: topCenter.y))
        path.addLine(to: CGPoint(x: bottomCenter.x + bottomWidth / 2, y: bottomCenter.y))
        path.addLine(to: CGPoint(x: bottomCenter.x - bottomWidth / 2, y: bottomCenter.y))
        path.closeSubpath()

        context.fill(path, with: .color(color.opacity(0.92 * feather)))

        var edgePath = Path()
        edgePath.move(to: CGPoint(x: topCenter.x - topWidth * 0.95, y: topCenter.y))
        edgePath.addLine(to: CGPoint(x: topCenter.x + topWidth * 0.95, y: topCenter.y))
        edgePath.addLine(to: CGPoint(x: bottomCenter.x + bottomWidth * 0.72, y: bottomCenter.y))
        edgePath.addLine(to: CGPoint(x: bottomCenter.x - bottomWidth * 0.72, y: bottomCenter.y))
        edgePath.closeSubpath()

        context.fill(edgePath, with: .color(color.opacity(0.34 * feather)))
    }
}

struct SottoGlassPanel<Content: View>: View {
    var role: SottoPanelRole = .workbench
    @ViewBuilder var content: Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
                    DotField(
                        spacing: 14,
                        dotSize: 1.05,
                        opacity: role == .prompt ? 0.11 : 0.075,
                        drift: role == .prompt ? 0.25 : 0.55,
                        animated: !reduceMotion
                    )
                        .clipShape(RoundedRectangle(cornerRadius: role.cornerRadius, style: .continuous))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: role.cornerRadius, style: .continuous)
                    .stroke(Color.sottoPrimary.opacity(0.22), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: role.cornerRadius, style: .continuous))
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
        label
            .foregroundStyle(color)
            .overlay(label.foregroundStyle(color.opacity(0.22)).blur(radius: 0.35))
            .shadow(color: color.opacity(0.30), radius: 8)
            .accessibilityElement(children: .ignore)
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
}

struct SottoStatusBadge: View {
    let title: String
    var color: Color = .sottoGreen
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if reduceMotion {
                badge(pulse: 0.82)
            } else {
                TimelineView(.animation) { timeline in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    let pulse = 0.74 + 0.26 * sin(time * .pi / 1.45)
                    badge(pulse: pulse)
                }
            }
        }
    }

    private func badge(pulse: Double) -> some View {
        HStack(spacing: 9) {
            Circle()
                .fill(color)
                .frame(width: 9, height: 9)
                .scaleEffect(0.94 + 0.08 * pulse)
                .shadow(color: color.opacity(0.38 + 0.35 * pulse), radius: 5 + 5 * pulse)
            Text(title)
                .font(SottoFont.pixel(15))
                .tracking(2.6)
                .opacity(0.78 + 0.18 * pulse)
        }
        .foregroundStyle(color)
    }
}

struct SottoRhythmLine: View {
    var amplitude: Double = 1
    var opacity: Double = 0.35
    var animated = true

    var body: some View {
        Group {
            if animated {
                TimelineView(.animation) { timeline in
                    rhythmCanvas(time: timeline.date.timeIntervalSinceReferenceDate)
                }
            } else {
                rhythmCanvas(time: 0)
            }
        }
        .allowsHitTesting(false)
    }

    private func rhythmCanvas(time: TimeInterval) -> some View {
        Canvas { context, size in
            let midY = size.height / 2
            let step: CGFloat = 9
            let count = Int(size.width / step)
            for index in 0...count {
                let x = CGFloat(index) * step
                let phase = Double(index) * 0.43 + time * 0.82
                let wave = abs(sin(phase)) * amplitude
                let height = CGFloat(6 + wave * 34)
                let rect = CGRect(x: x, y: midY - height / 2, width: 1.2, height: height)
                context.fill(Path(roundedRect: rect, cornerRadius: 1), with: .color(.sottoPrimary.opacity(opacity)))
            }

            var baseline = Path()
            baseline.move(to: CGPoint(x: 0, y: midY))
            baseline.addLine(to: CGPoint(x: size.width, y: midY))
            context.stroke(baseline, with: .color(.sottoPrimary.opacity(opacity * 0.45)), lineWidth: 1)
        }
    }
}

struct SottoAmbientMotionField: View {
    var intensity: Double = 1
    var animated = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if animated && !reduceMotion {
                TimelineView(.animation) { timeline in
                    ambientCanvas(time: timeline.date.timeIntervalSinceReferenceDate)
                }
            } else {
                ambientCanvas(time: 0)
            }
        }
        .allowsHitTesting(false)
    }

    private func ambientCanvas(time: TimeInterval) -> some View {
        Canvas { context, size in
            for index in 0..<28 {
                let seed = Double(index)
                let baseX = CGFloat((sin(seed * 12.989) * 43758.5453).truncatingRemainder(dividingBy: 1)).magnitude
                let baseY = CGFloat((sin(seed * 78.233) * 19341.731).truncatingRemainder(dividingBy: 1)).magnitude
                let driftX = CGFloat(sin(time * 0.15 + seed * 1.7) * 14)
                let driftY = CGFloat(cos(time * 0.12 + seed * 1.1) * 7)
                let x = baseX * size.width + driftX
                let y = baseY * size.height + driftY
                let length = CGFloat(10 + (index % 5) * 7)
                let height = CGFloat(1 + (index % 3))
                let pulse = 0.54 + 0.46 * sin(time * 0.42 + seed * 0.71)
                let alpha = intensity * (0.045 + 0.055 * pulse)
                let rect = CGRect(x: x, y: y, width: length, height: height)
                context.fill(
                    Path(roundedRect: rect, cornerRadius: height / 2),
                    with: .color(.sottoPrimary.opacity(alpha))
                )
            }

            for index in 0..<18 {
                let seed = Double(index + 31)
                let x = CGFloat((sin(seed * 91.17) * 6712.131).truncatingRemainder(dividingBy: 1)).magnitude * size.width
                let y = CGFloat((sin(seed * 27.41) * 3381.917).truncatingRemainder(dividingBy: 1)).magnitude * size.height
                let pulse = 0.52 + 0.48 * sin(time * 0.34 + seed)
                let dot = CGFloat(1.4 + Double(index % 3) * 0.8)
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: dot, height: dot)),
                    with: .color(.sottoGlow.opacity(intensity * (0.08 + 0.08 * pulse)))
                )
            }
        }
    }
}

struct SottoVoiceWaveform: View {
    var level: Double
    var isListening: Bool
    var opacity: Double = 0.42
    var barCount = 44
    var animated = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if animated && !reduceMotion {
                TimelineView(.animation) { timeline in
                    waveformCanvas(time: timeline.date.timeIntervalSinceReferenceDate)
                }
            } else {
                waveformCanvas(time: 0)
            }
        }
        .allowsHitTesting(false)
    }

    private func waveformCanvas(time: TimeInterval) -> some View {
        Canvas { context, size in
            let midX = size.width / 2
            let midY = size.height / 2
            let halfCount = max(barCount / 2, 1)
            let step = max(size.width / CGFloat(barCount), 4)
            let liveLevel = isListening ? max(min(level, 1), 0.045) : 0.035

            var baseline = Path()
            baseline.move(to: CGPoint(x: 0, y: midY))
            baseline.addLine(to: CGPoint(x: size.width, y: midY))
            context.stroke(baseline, with: .color(.sottoPrimary.opacity(opacity * 0.18)), lineWidth: 1)

            for index in 0..<halfCount {
                let distance = Double(index) / Double(max(halfCount - 1, 1))
                let envelope = 1.0 - pow(distance, 1.42) * 0.72
                let voice = liveLevel * (0.66 + 0.34 * sin(Double(index) * 0.73 + time * 3.2))
                let idle = isListening ? 0 : 0.035 * sin(Double(index) * 0.82 + time * 0.7)
                let height = CGFloat(4 + max(voice + idle, 0) * Double(size.height) * 0.92 * envelope)
                let width = CGFloat(index % 4 == 0 ? 2.2 : 1.4)
                let alpha = opacity * (0.34 + liveLevel * 0.88) * (0.76 + envelope * 0.24)

                for side in [-1.0, 1.0] {
                    let x = midX + CGFloat(side) * (CGFloat(index) * step + 3)
                    let rect = CGRect(x: x - width / 2, y: midY - height / 2, width: width, height: height)
                    context.fill(
                        Path(roundedRect: rect, cornerRadius: width),
                        with: .color(.sottoPrimary.opacity(alpha))
                    )
                }
            }

            let coreWidth = CGFloat(22 + liveLevel * 44)
            let coreRect = CGRect(x: midX - coreWidth / 2, y: midY - 1.5, width: coreWidth, height: 3)
            context.fill(
                Path(roundedRect: coreRect, cornerRadius: 2),
                with: .color(.sottoGlow.opacity(opacity * (0.26 + liveLevel * 0.56)))
            )
        }
    }
}

struct SottoIconButton: View {
    let systemName: String
    var title: String?
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemName)
                if let title {
                    Text(title)
                        .font(SottoFont.pixel(13))
                        .tracking(1.4)
                }
            }
            .frame(minWidth: title == nil ? 42 : 86, minHeight: 34)
            .foregroundStyle(Color.sottoPrimary.opacity(0.86))
            .background(Color.white.opacity(hovering ? 0.088 : 0.045))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.sottoPrimary.opacity(hovering ? 0.30 : 0.16), lineWidth: 1)
            )
            .shadow(color: Color.sottoGlow.opacity(hovering ? 0.18 : 0), radius: 8)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(SottoMotionTokens.hover, value: hovering)
    }
}

struct DotField: View {
    var spacing: CGFloat = 18
    var dotSize: CGFloat = 1.2
    var opacity: Double = 0.18
    var drift: Double = 0.7
    var animated = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            if animated && !reduceMotion && drift > 0 {
                TimelineView(.animation) { timeline in
                    dotCanvas(size: proxy.size, time: timeline.date.timeIntervalSinceReferenceDate)
                }
            } else {
                dotCanvas(size: proxy.size, time: 0)
            }
        }
        .allowsHitTesting(false)
    }

    private func dotCanvas(size: CGSize, time: TimeInterval) -> some View {
        let xDrift = CGFloat(sin(time * .pi / 11) * 1.4 * drift)
        let yDrift = CGFloat(cos(time * .pi / 13) * 1.0 * drift)

        return Canvas { context, canvasSize in
            let columns = Int(canvasSize.width / spacing)
            let rows = Int(canvasSize.height / spacing)
            for row in 0...rows {
                for column in 0...columns {
                    let phase = Double((row * 11 + column * 7) % 19) * 0.37
                    let twinkle = 0.74 + 0.26 * sin(time * .pi / 6 + phase)
                    let glow = ((row + column) % 7 == 0) ? 1.65 : 1
                    let size = dotSize * glow
                    let rect = CGRect(
                        x: CGFloat(column) * spacing + xDrift,
                        y: CGFloat(row) * spacing + yDrift,
                        width: size,
                        height: size
                    )
                    context.fill(Path(ellipseIn: rect), with: .color(.sottoPrimary.opacity(opacity * twinkle / glow)))
                }
            }
        }
        .frame(width: size.width, height: size.height)
    }
}

extension View {
    func sottoPanel() -> some View {
        SottoGlassPanel(role: .workbench) {
            self
        }
    }

    func sottoEditorPanel(
        cornerRadius: CGFloat = 18,
        fillOpacity: Double = 0.72,
        borderOpacity: Double = 0.08,
        glowOpacity: Double = 0
    ) -> some View {
        self
            .padding(12)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color(red: 0.055, green: 0.052, blue: 0.046).opacity(fillOpacity))
                    DotField(spacing: 15, dotSize: 0.95, opacity: 0.07, drift: 0.35)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.sottoPrimary.opacity(borderOpacity), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.sottoGlow.opacity(glowOpacity), radius: 20, y: 6)
            .shadow(color: .black.opacity(0.34), radius: 18, y: 12)
    }

    func sottoEntrance(delay: Double = 0) -> some View {
        modifier(SottoEntranceModifier(delay: delay))
    }
}

private struct SottoEntranceModifier: ViewModifier {
    let delay: Double
    @State private var visible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: visible || reduceMotion ? 0 : 10)
            .onAppear {
                withAnimation(.easeOut(duration: reduceMotion ? 0.01 : 0.36).delay(delay)) {
                    visible = true
                }
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
