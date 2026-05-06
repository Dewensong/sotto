import SwiftUI

enum SottoMotionTokens {
    static let hover = Animation.easeOut(duration: 0.16)
    static let confirm = Animation.easeOut(duration: 0.24)
    static let entrance = Animation.easeOut(duration: 0.36)
    static let sourceShift = Animation.easeInOut(duration: 0.34)

    static func duration(_ seconds: Double, reduceMotion: Bool) -> Double {
        reduceMotion ? 0.01 : seconds
    }
}

struct SottoSignalText: View {
    let text: String
    var size: CGFloat
    var color: Color = .sottoPrimary
    var dot: CGFloat = 1.8
    var spacing: CGFloat = 4.6
    var tracking: CGFloat = 1.0
    var lineLimit: Int?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            baseText
        } else {
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let drift = CGFloat(sin(time * .pi / 3.8) * 0.75)
                let counterDrift = CGFloat(cos(time * .pi / 4.6) * 0.45)

                ZStack(alignment: .leading) {
                    baseText
                    baseText
                        .opacity(0.18)
                        .blur(radius: 0.55)
                        .offset(x: drift)
                        .accessibilityHidden(true)
                    baseText
                        .opacity(0.10)
                        .blur(radius: 0.8)
                        .offset(x: counterDrift)
                        .accessibilityHidden(true)
                }
            }
        }
    }

    private var baseText: some View {
        PixelText(
            text: text,
            size: size,
            color: color,
            dot: dot,
            spacing: spacing,
            tracking: tracking,
            lineLimit: lineLimit
        )
    }
}

struct SottoConfirmationSpark: View {
    var isActive: Bool
    var color: Color = .sottoGlow
    var radius: CGFloat = 18

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if !reduceMotion {
                ForEach(0..<6, id: \.self) { index in
                    Capsule()
                        .fill(color.opacity(0.74))
                        .frame(width: 2, height: 7)
                        .offset(y: isActive ? -radius : -8)
                        .rotationEffect(.degrees(Double(index) * 60))
                        .opacity(isActive ? 0.92 : 0)
                        .scaleEffect(isActive ? 1 : 0.35)
                }

                Circle()
                    .stroke(color.opacity(0.32), lineWidth: 1)
                    .frame(width: isActive ? radius * 2.2 : 4, height: isActive ? radius * 2.2 : 4)
                    .opacity(isActive ? 0.0 : 0.55)
            }
        }
        .animation(SottoMotionTokens.confirm, value: isActive)
        .allowsHitTesting(false)
    }
}

struct SottoProgressiveEdgeFade: View {
    var edges: Edge.Set = [.top, .bottom]
    var height: CGFloat = 38
    var strength: Double = 0.90

    private let panelColor = Color(red: 0.055, green: 0.052, blue: 0.046)

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if edges.contains(.top) {
                    LinearGradient(
                        colors: [panelColor.opacity(strength), panelColor.opacity(0.38 * strength), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: height)
                }

                Spacer(minLength: 0)

                if edges.contains(.bottom) {
                    LinearGradient(
                        colors: [.clear, panelColor.opacity(0.38 * strength), panelColor.opacity(strength)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: height)
                }
            }

            HStack(spacing: 0) {
                if edges.contains(.leading) {
                    LinearGradient(
                        colors: [panelColor.opacity(strength), panelColor.opacity(0.32 * strength), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: height)
                }

                Spacer(minLength: 0)

                if edges.contains(.trailing) {
                    LinearGradient(
                        colors: [.clear, panelColor.opacity(0.32 * strength), panelColor.opacity(strength)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: height)
                }
            }
        }
        .blur(radius: 2)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct SottoSemanticIcon: View {
    enum MotionKind {
        case pause
        case emphasis
        case pace
    }

    let systemName: String
    var trigger: String
    var kind: MotionKind

    @State private var pulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Image(systemName: systemName)
            .scaleEffect(pulse ? scale : 1)
            .rotationEffect(.degrees(pulse ? rotation : 0))
            .offset(y: pulse ? yOffset : 0)
            .shadow(color: Color.sottoGlow.opacity(pulse ? 0.44 : 0.12), radius: pulse ? 7 : 3)
            .onChange(of: trigger) { _, _ in
                fire()
            }
    }

    private var scale: CGFloat {
        switch kind {
        case .pause: 1.03
        case .emphasis: 1.07
        case .pace: 1.06
        }
    }

    private var rotation: Double {
        switch kind {
        case .pause: 0
        case .emphasis: -4
        case .pace: 6
        }
    }

    private var yOffset: CGFloat {
        switch kind {
        case .pause: 1
        case .emphasis: -1
        case .pace: 0
        }
    }

    private func fire() {
        guard !reduceMotion else { return }
        withAnimation(SottoMotionTokens.confirm) {
            pulse = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            withAnimation(SottoMotionTokens.confirm) {
                pulse = false
            }
        }
    }
}
