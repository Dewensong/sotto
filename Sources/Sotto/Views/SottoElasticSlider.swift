import SwiftUI

private let maxOverflow: CGFloat = 50

// MARK: - Elastic slider

struct SottoElasticSlider: View {
    let value: Double
    let range: ClosedRange<Double>
    let valueText: String
    var label: String = ""
    var step: Double? = nil
    var width: CGFloat? = nil
    var leftIcon: String? = nil
    var rightIcon: String? = nil
    let onChange: (Double) -> Void

    var body: some View {
        if leftIcon != nil || rightIcon != nil {
            iconLayout
        } else {
            tuneLayout
        }
    }

    // MARK: –  Settings layout (icons + centred value)

    private var iconLayout: some View {
        ElasticIconLayout(
            value: value,
            range: range,
            valueText: valueText,
            onChange: onChange,
            leftIcon: leftIcon ?? "minus",
            rightIcon: rightIcon ?? "plus"
        )
    }

    // MARK: –  TUNE-drawer layout (label + track + trailing value)

    private var tuneLayout: some View {
        ElasticTuneLayout(
            value: value,
            range: range,
            valueText: valueText,
            onChange: onChange,
            label: label,
            step: step,
            width: width
        )
    }
}

// MARK: - Shared elastic core

private struct ElasticCore: View {
    let value: Double
    let range: ClosedRange<Double>
    let onChange: (Double) -> Void
    let step: Double?

    @Binding var overflow: CGFloat
    @Binding var region: SliderEdge
    @Binding var clientX: CGFloat

    enum SliderEdge { case left, middle, right }

    var body: some View {
        GeometryReader { proxy in
            let trackWidth = max(proxy.size.width, 1)
            let progress = clampedProgress

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 6)
                Capsule()
                    .fill(Color.sottoGlow.opacity(0.52))
                    .frame(width: trackWidth * progress, height: 6)
                Circle()
                    .fill(Color.sottoPrimary.opacity(0.92))
                    .frame(width: 10, height: 10)
                    .offset(x: trackWidth * progress - 5)
                    .shadow(color: Color.sottoGlow.opacity(0.16), radius: 8)
            }
            .frame(maxHeight: .infinity)
            .scaleEffect(
                x: 1 + overflow / trackWidth,
                y: 1 - (overflow / maxOverflow) * 0.2,
                anchor: transformOrigin(for: trackWidth)
            )
            .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.7), value: overflow)
            .contentShape(Rectangle())
            .gesture(dragGesture(in: proxy, trackWidth: trackWidth))
        }
        .frame(height: 24)
    }

    private var clampedProgress: CGFloat {
        CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
    }

    private func transformOrigin(for trackWidth: CGFloat) -> UnitPoint {
        clientX < trackWidth / 2 ? .trailing : .leading
    }

    private func dragGesture(in proxy: GeometryProxy, trackWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { gesture in
                let frame = proxy.frame(in: .global)
                clientX = gesture.location.x

                if gesture.location.x < frame.minX {
                    region = .left
                    overflow = decay(frame.minX - gesture.location.x, max: maxOverflow)
                } else if gesture.location.x > frame.maxX {
                    region = .right
                    overflow = decay(gesture.location.x - frame.maxX, max: maxOverflow)
                } else {
                    region = .middle
                    overflow = 0
                }

                let ratio = min(max((gesture.location.x - frame.minX) / frame.width, 0), 1)
                let raw = range.lowerBound + Double(ratio) * (range.upperBound - range.lowerBound)
                onChange(snapped(clamped(raw)))
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    overflow = 0
                    region = .middle
                }
            }
    }

    private func clamped(_ v: Double) -> Double {
        min(max(v, range.lowerBound), range.upperBound)
    }

    private func snapped(_ v: Double) -> Double {
        guard let step, step > 0 else { return v }
        return (v / step).rounded() * step
    }
}

// MARK: – Settings (icon) layout

private struct ElasticIconLayout: View {
    let value: Double
    let range: ClosedRange<Double>
    let valueText: String
    let onChange: (Double) -> Void
    let leftIcon: String
    let rightIcon: String

    @State private var overflow: CGFloat = 0
    @State private var region: ElasticCore.SliderEdge = .middle
    @State private var clientX: CGFloat = 0
    @State private var isHovering = false
    @State private var wrapperScale: CGFloat = 1

    private enum Side { case left, right }

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                iconView(name: leftIcon, side: .left)
                ElasticCore(
                    value: value,
                    range: range,
                    onChange: onChange,
                    step: nil,
                    overflow: $overflow,
                    region: $region,
                    clientX: $clientX
                )
                iconView(name: rightIcon, side: .right)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.20))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .scaleEffect(wrapperScale)
            .opacity(isHovering ? 1 : 0.7)
            .onHover { hovering in
                isHovering = hovering
                withAnimation(.easeOut(duration: 0.16)) {
                    wrapperScale = hovering ? 1.05 : 1
                }
            }

            Text(valueText)
                .font(SottoFont.pixel(10))
                .foregroundStyle(Color.sottoMuted)
        }
    }

    private func iconView(name: String, side: Side) -> some View {
        Image(systemName: name)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(Color.sottoMuted)
            .scaleEffect(bounceScale(for: side))
            .offset(x: offset(for: side))
            .animation(.spring(response: 0.25, dampingFraction: 0.5), value: region)
    }

    private func bounceScale(for side: Side) -> CGFloat {
        switch (side, region) {
        case (.left, .left), (.right, .right): return 1.4
        default: return 1
        }
    }

    private func offset(for side: Side) -> CGFloat {
        switch (side, region) {
        case (.left, .left): return -overflow / wrapperScale
        case (.right, .right): return overflow / wrapperScale
        default: return 0
        }
    }
}

// MARK: – TUNE (label) layout

private struct ElasticTuneLayout: View {
    let value: Double
    let range: ClosedRange<Double>
    let valueText: String
    let onChange: (Double) -> Void
    let label: String
    let step: Double?
    let width: CGFloat?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovering = false
    @State private var isDragging = false
    @State private var overflow: CGFloat = 0
    @State private var region: ElasticCore.SliderEdge = .middle
    @State private var clientX: CGFloat = 0

    var body: some View {
        HStack(spacing: 8) {
            if !label.isEmpty {
                Text(label)
                    .font(SottoFont.pixel(12))
                    .tracking(1.2)
                    .foregroundStyle(Color.sottoSecondary.opacity(isActive ? 0.92 : 0.64))
                    .frame(width: label == "α" ? 16 : 28, alignment: .trailing)
            }

            ElasticCore(
                value: value,
                range: range,
                onChange: onChange,
                step: step,
                overflow: $overflow,
                region: $region,
                clientX: $clientX
            )
            .frame(width: effectiveWidth)

            Text(valueText)
                .font(SottoFont.pixel(12))
                .tracking(1.1)
                .foregroundStyle(Color.sottoPrimary.opacity(isActive ? 0.86 : 0.58))
                .frame(width: valueTextWidth, alignment: .leading)
        }
        .scaleEffect(isActive ? 1.035 : 1, anchor: .center)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.14), value: isHovering)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.10), value: isDragging)
        .onHover { isHovering = $0 }
        .onChange(of: overflow) { _, newValue in
            isDragging = newValue != 0
        }
    }

    private var isActive: Bool { isHovering || isDragging }

    private var effectiveWidth: CGFloat? {
        width
    }

    private var valueTextWidth: CGFloat {
        if valueText.contains("%") { return 42 }
        return valueText.count > 3 ? 44 : 38
    }
}

// MARK: - Helpers

private func decay(_ value: CGFloat, max: CGFloat) -> CGFloat {
    if max == 0 { return 0 }
    let entry = Double(value / max)
    let sigmoid = 2 * (1 / (1 + exp(-entry)) - 0.5)
    return CGFloat(sigmoid) * max
}
