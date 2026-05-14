import SwiftUI
import SottoCore

struct SottoSettingsPanel: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ZStack {
            stackedBackplate

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 10) {
                    header
                    positionPresets
                    readingModeControl
                    cursorModeControl
                    apiKeyControl
                    fontControl
                    privacyControl
                    mirrorControl
                    Divider().background(Color.sottoPrimary.opacity(0.10))
                    HStack(spacing: 12) {
                        fontSizeControl
                        speedControl
                    }
                    HStack(spacing: 12) {
                        lineSpacingControl
                        trackingControl
                    }
                    HStack(spacing: 12) {
                        opacityControl
                        brightnessControl
                    }
                    widthControl
                    if model.settings.readingMode == .voiceActivated {
                        voiceSensitivityControl
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    shortcutsHint
                }
                .padding(16)
            }
            .frame(width: 330)
            .frame(maxHeight: 520)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThickMaterial)
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(red: 0.060, green: 0.056, blue: 0.050).opacity(0.86))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.sottoPrimary.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: Color.sottoGlow.opacity(0.22), radius: 24, y: 12)
        }
        .frame(width: 362)
    }

    private var header: some View {
        HStack {
            Text("提词设置")
                .font(SottoFont.pixel(15))
                .tracking(1.2)
                .foregroundStyle(Color.sottoPrimary)
            Spacer()
            Button {
                model.restoreDefaultSettings()
            } label: {
                Text("恢复默认")
                    .font(SottoFont.pixel(10))
                    .tracking(0.6)
                    .foregroundStyle(Color.sottoMuted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.sottoPrimary.opacity(0.10), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var positionPresets: some View {
        VStack(alignment: .leading, spacing: 6) {
            settingLabel("窗口位置")
            HStack(spacing: 8) {
                SettingsPresetButton(title: "上方", systemName: "rectangle.topthird.inset.filled", selected: model.settings.position == .upperCenter) {
                    model.setPromptPosition(.upperCenter)
                }
                SettingsPresetButton(title: "镜头", systemName: "web.camera", selected: model.settings.position == .cameraNear) {
                    model.setPromptPosition(.cameraNear)
                }
                SettingsPresetButton(title: "自由", systemName: "arrow.up.left.and.arrow.down.right", selected: model.settings.position == .custom) {
                    model.setPromptPosition(.custom)
                }
            }
        }
    }

    private var readingModeControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            settingLabel("阅读模式")
            HStack(spacing: 8) {
                SettingsPresetButton(title: "定时", systemName: "timer", selected: model.settings.readingMode == .timed) {
                    model.setReadingMode(.timed)
                }
                SettingsPresetButton(title: "跟声", systemName: "waveform", selected: model.settings.readingMode == .voiceActivated) {
                    model.setReadingMode(.voiceActivated)
                }
            }
            if model.settings.readingMode == .voiceActivated, model.microphonePermissionDenied {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(Color.sottoRed)
                    Text("麦克风权限未开启")
                        .font(SottoFont.pixel(9))
                        .tracking(0.8)
                        .foregroundStyle(Color.sottoRed)
                }
            }
            SettingsHintText(
                text: model.settings.readingMode == .voiceActivated
                    ? "跟声模式按音量推进，不是逐字识别。"
                    : "定时模式最稳定，适合正式录屏前默认排练。"
            )
        }
    }

    private var cursorModeControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            settingLabel("光标模式")
            HStack(spacing: 8) {
                SettingsPresetButton(title: "逐字", systemName: "textformat.abc", selected: model.settings.cursorMode == .character) {
                    model.setCursorMode(.character)
                }
                SettingsPresetButton(title: "逐词", systemName: "text.word.spacing", selected: model.settings.cursorMode == .word) {
                    model.setCursorMode(.word)
                }
                SettingsPresetButton(title: "逐行", systemName: "text.justify", selected: model.settings.cursorMode == .line) {
                    model.setCursorMode(.line)
                }
            }
        }
    }

    private var apiKeyControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                settingLabel("DeepSeek API Key")
                apiStatusDot
            }

            HStack(spacing: 6) {
                SecureField("sk-...", text: $model.apiKeyInput)
                    .font(SottoFont.pixel(10))
                    .foregroundStyle(Color.sottoPrimary)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 8)
                    .frame(height: 28)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(Color.sottoPrimary.opacity(0.12), lineWidth: 1)
                    )

                Button {
                    model.saveApiKey()
                } label: {
                    Text("保存")
                        .font(SottoFont.pixel(9))
                        .foregroundStyle(Color.sottoPrimary)
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(model.apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button {
                    model.testApiConnection()
                } label: {
                    HStack(spacing: 3) {
                        if model.apiTestState == .testing {
                            ProgressView()
                                .scaleEffect(0.45)
                                .frame(width: 10, height: 10)
                        } else {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 7))
                        }
                        Text("测试")
                            .font(SottoFont.pixel(9))
                    }
                    .foregroundStyle(model.apiTestState == .testing ? Color.sottoMuted : Color.sottoPrimary)
                    .padding(.horizontal, 8)
                    .frame(height: 28)
                    .background(Color.white.opacity(model.apiTestState == .testing ? 0.03 : 0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!model.hasApiKey || model.apiTestState == .testing)
            }

            apiTestStatusLine

            SettingsHintText(text: "在 DeepSeek 控制台获取 Key。保存后通过测试按钮验证连通性。")
        }
    }

    @ViewBuilder
    private var apiStatusDot: some View {
        switch model.apiTestState {
        case .success:
            Circle()
                .fill(Color.sottoGreen)
                .frame(width: 6, height: 6)
                .shadow(color: Color.sottoGreen.opacity(0.6), radius: 6)
            Text("已连通")
                .font(SottoFont.pixel(9))
                .foregroundStyle(Color.sottoGreen)
        case .testing:
            ProgressView()
                .scaleEffect(0.5)
                .frame(width: 6, height: 6)
            Text("检测中...")
                .font(SottoFont.pixel(9))
                .foregroundStyle(Color.sottoMuted)
        case .failed:
            Circle()
                .fill(Color.sottoRed)
                .frame(width: 6, height: 6)
                .shadow(color: Color.sottoRed.opacity(0.5), radius: 6)
            Text("未连通")
                .font(SottoFont.pixel(9))
                .foregroundStyle(Color.sottoRed)
        case .idle:
            Circle()
                .fill(model.hasApiKey ? Color.sottoGlow : Color.sottoMuted)
                .frame(width: 6, height: 6)
            if model.hasApiKey {
                Text("已配置")
                    .font(SottoFont.pixel(9))
                    .foregroundStyle(Color.sottoGreen)
            }
        }
    }

    @ViewBuilder
    private var apiTestStatusLine: some View {
        if case .failed(let message) = model.apiTestState {
            HStack(spacing: 5) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 7))
                    .foregroundStyle(Color.sottoRed)
                Text(message)
                    .font(SottoFont.pixel(9))
                    .foregroundStyle(Color.sottoRed)
                    .lineLimit(2)
            }
        }
    }

    private var fontControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            settingLabel("正文字体")
            HStack(spacing: 8) {
                SettingsPresetButton(title: "像素", systemName: "square.grid.3x3.square", selected: model.settings.usesPixelFont) {
                    model.setBodyFont(nil)
                }
                SettingsPresetButton(title: "系统", systemName: "textformat", selected: !model.settings.usesPixelFont) {
                    let fonts = SottoFont.availableSystemFonts
                    model.setBodyFont(fonts.first?.name)
                }
            }
            if !model.settings.usesPixelFont {
                systemFontPicker
            }
        }
    }

    private var systemFontPicker: some View {
        let fonts = SottoFont.availableSystemFonts
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(fonts, id: \.name) { font in
                    Button {
                        model.setBodyFont(font.name)
                    } label: {
                        Text(font.label)
                            .font(.custom(font.name, size: 12))
                            .lineLimit(1)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .foregroundStyle(model.settings.bodyFontName == font.name ? Color.sottoPrimary : Color.sottoSecondary)
                            .background(Color.sottoGlow.opacity(model.settings.bodyFontName == font.name ? 0.16 : 0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var privacyControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            settingLabel("屏幕共享")
            SettingsToggleRow(
                title: model.settings.hidesFromScreenShare ? "共享隐藏" : "共享可见",
                systemName: model.settings.hidesFromScreenShare ? "eye.slash" : "eye",
                enabled: model.settings.hidesFromScreenShare
            ) {
                model.setHidePromptFromScreenShare(!model.settings.hidesFromScreenShare)
            }
        }
    }

    private var mirrorControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            settingLabel("镜像翻转")
            SettingsToggleRow(
                title: model.settings.mirrored ? "已翻转" : "正常",
                systemName: model.settings.mirrored ? "arrow.left.and.right.righttriangle.left.righttriangle.right" : "rectangle",
                enabled: model.settings.mirrored
            ) {
                model.setMirrored(!model.settings.mirrored)
            }
            SettingsHintText(text: "用于物理反射板场景，将提词窗水平翻转。")
        }
    }

    private var fontSizeControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            settingLabel("默认字号")
            SottoElasticSlider(
                value: model.settings.fontSize,
                range: 24...48,
                valueText: "\(Int(model.settings.fontSize))pt",
                leftIcon: "textformat.size.smaller",
                rightIcon: "textformat.size.larger"
            ) { value in
                model.setPromptFontSize(value)
            }
        }
    }

    private var lineSpacingControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            settingLabel("行间距")
            SottoElasticSlider(
                value: model.settings.lineSpacing,
                range: 0.06...0.42,
                valueText: "\(Int(model.settings.lineSpacing * 100))%",
                leftIcon: "arrow.down.and.line.horizontal.and.arrow.up",
                rightIcon: "arrow.up.and.line.horizontal.and.arrow.down"
            ) { value in
                model.setLineSpacing(value)
            }
        }
    }

    private var trackingControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            settingLabel("字间距")
            SottoElasticSlider(
                value: model.settings.tracking,
                range: 0...6,
                valueText: String(format: "%.1fpt", model.settings.tracking),
                leftIcon: "textformat.size.smaller",
                rightIcon: "textformat.size.larger"
            ) { value in
                model.setTracking(value)
            }
        }
    }

    private var speedControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            settingLabel("默认速度")
            SottoElasticSlider(
                value: model.settings.speedMultiplier,
                range: 0.55...1.65,
                valueText: String(format: "%.2fx", model.settings.speedMultiplier),
                leftIcon: "tortoise",
                rightIcon: "hare"
            ) { value in
                model.setPromptSpeedMultiplier(value)
            }
        }
    }

    private var brightnessControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            settingLabel("提词窗亮度")
            SottoElasticSlider(
                value: model.settings.brightness,
                range: 0.65...1.2,
                valueText: "\(Int(model.settings.brightness * 100))%",
                leftIcon: "sun.min",
                rightIcon: "sun.max"
            ) { value in
                model.setPromptBrightness(value)
            }
        }
    }

    private var widthControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            settingLabel("提词窗宽度")
            SottoElasticSlider(
                value: model.settings.width,
                range: 620...1180,
                valueText: "\(Int(model.settings.width))px",
                leftIcon: "arrow.left.and.right",
                rightIcon: "arrow.left.and.right"
            ) { value in
                model.setPromptWidth(value)
            }
        }
    }

    private var opacityControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            settingLabel("提词窗透明度")
            SottoElasticSlider(
                value: model.settings.opacity,
                range: 0.55...1,
                valueText: "\(Int(model.settings.opacity * 100))%",
                leftIcon: "circle.lefthalf.filled",
                rightIcon: "circle.fill"
            ) { value in
                model.setPromptOpacity(value)
            }
        }
    }

    private var voiceSensitivityControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            settingLabel("跟声灵敏度")
            SottoElasticSlider(
                value: model.settings.voiceActivationThreshold,
                range: 0.01...0.12,
                valueText: String(format: "%.3f", model.settings.voiceActivationThreshold),
                leftIcon: "mic",
                rightIcon: "mic.fill"
            ) { value in
                model.setVoiceActivationThreshold(value)
            }
            SettingsHintText(text: "阈值越低，越容易被声音触发推进。")
        }
    }

    private var shortcutsHint: some View {
        HStack(spacing: 6) {
            Image(systemName: "command")
                .font(.system(size: 9, weight: .medium))
            Text("⌘⌥P 提词")
                .font(SottoFont.pixel(10))
            Spacer()
            Text("Space 播放")
                .font(SottoFont.pixel(10))
            Text("← → 跳句")
                .font(SottoFont.pixel(10))
        }
        .foregroundStyle(Color.sottoMuted)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var stackedBackplate: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.sottoGlow.opacity(0.10))
                .frame(width: 310, height: 160)
                .offset(x: -14, y: 18)
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.sottoPrimary.opacity(0.045))
                .frame(width: 320, height: 178)
                .offset(x: -7, y: 9)
        }
        .allowsHitTesting(false)
    }

    private func settingLabel(_ text: String) -> some View {
        Text(text)
            .font(SottoFont.pixel(10))
            .tracking(1.0)
            .foregroundStyle(Color.sottoMuted)
    }
}

private struct SettingsPresetButton: View {
    let title: String
    let systemName: String
    let selected: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemName)
                    .font(SottoFont.pixel(14))
                Text(title)
                    .font(SottoFont.pixel(11))
                    .tracking(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .foregroundStyle(selected ? Color.sottoPrimary : Color.sottoSecondary)
            .background(Color.sottoGlow.opacity(selected ? 0.16 : (hovering ? 0.08 : 0.035)))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.sottoPrimary.opacity(selected ? 0.34 : 0.10), lineWidth: 1)
            )
            .shadow(color: Color.sottoGlow.opacity(selected ? 0.22 : 0), radius: 12)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(SottoMotionTokens.hover, value: hovering)
        .animation(SottoMotionTokens.confirm, value: selected)
    }
}


private struct SettingsStatusChip: View {
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .shadow(color: color.opacity(0.55), radius: 6)
            Text(title)
                .font(SottoFont.pixel(10))
                .tracking(1.0)
        }
        .foregroundStyle(color)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.035))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct SettingsHintText: View {
    let text: String

    var body: some View {
        Text(text)
            .font(SottoFont.pixel(10))
            .tracking(0.6)
            .foregroundStyle(Color.sottoMuted)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.black.opacity(0.16))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct SettingsToggleRow: View {
    let title: String
    let systemName: String
    let enabled: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemName)
                    .font(SottoFont.pixel(13))
                Text(title)
                    .font(SottoFont.pixel(11))
                    .tracking(0.8)
                Spacer()
                Circle()
                    .fill(enabled ? Color.sottoGreen : Color.sottoSecondary.opacity(0.5))
                    .frame(width: 8, height: 8)
                    .shadow(color: (enabled ? Color.sottoGreen : Color.clear).opacity(0.5), radius: 8)
            }
            .foregroundStyle(enabled ? Color.sottoPrimary : Color.sottoSecondary)
            .padding(.horizontal, 12)
            .frame(height: 42)
            .background(Color.sottoGlow.opacity(enabled ? 0.14 : (hovering ? 0.08 : 0.035)))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.sottoPrimary.opacity(enabled ? 0.30 : 0.10), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(SottoMotionTokens.hover, value: hovering)
        .animation(SottoMotionTokens.confirm, value: enabled)
    }
}