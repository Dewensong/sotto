# 资源索引

## 云端文档
- 暂无

## 外部链接
- [Mootch](https://getmootch.com/)：Mac AI teleprompter 参考，强调本地 Whisper、刘海/悬浮模式、屏幕共享不可见。
- [CueNotch](https://cuenotch.com/)：Mac 提词器参考，强调 Ghost Mode、AI humanize、会议/录制场景。
- [Textream](https://textream.fka.dev/)：开源/产品参考，包含语音跟踪、经典滚动、语音触发滚动、远程控制等功能。
- [Textream GitHub](https://github.com/f/textream)：可查看 macOS 提词器实现方向和功能范围。
- [VoicePrompter](https://voiceprompter.app/)：Web + Mac 提词器参考，强调语音命令、录制、多语言。
- [Telepront](https://www.telepront.com/)：Mac 提词器参考，强调平滑滚动和 Apple 本地语音识别。
- [Unicorn Studio Embed Docs](https://www.unicorn.studio/docs/embed/)：外部 WebGL 场景嵌入参考；当前候选项目 ID 为 `xbdYsuMp0mSR01MXofEj`，SDK 版本为 `2.1.11`。
- [unicornstudio-react](https://www.npmjs.com/package/unicornstudio-react)：React / Next.js 嵌入 Unicorn Studio 场景的包，后续实现首页沉浸背景时可评估。
- [Magic UI Progressive Blur](https://magicui.design/docs/components/progressive-blur)：滚动内容边缘渐进模糊参考，可用于稿件编辑区、最近稿件列表、切分面板和提词预览的边界提示。
- [Magic UI Dot Pattern](https://magicui.design/docs/components/dot-pattern)：SVG 点阵背景参考，可作为 Sotto 默认低成本背景底座，必要时开启轻量 glow。
- [Magic UI Animated Theme Toggler](https://magicui.design/docs/components/animated-theme-toggler)：明亮 / 黑暗模式切换参考，基于 View Transitions API 做 clip-path reveal；本期只登记为未来主题切换候选。
- [Fusion Pixel Font](https://github.com/TakWolf/fusion-pixel-font)：泛中日韩像素字体资源；当前 App 内置 `12px proportional zh_hans` OTF，用于 Sotto 像素标题和提词关键文字。
- [Free Chinese Font - Pixel](https://www.freechinesefont.com/category/pixel/)：中文像素字体索引，后续可继续寻找更接近参考图标题气质的替代字体。

## 素材与数据
- `artifacts/github-media/`：GitHub 公开前素材目录，包含当前真实运行截图、README hero 图、Sotto logo PNG 和短演示 slideshow 视频；详见 `artifacts/github-media/README.md`。
- `Sources/Sotto/Resources/AppIcon/SottoLogo.svg`：Sotto GitHub / README 品牌 logo 的源文件，视觉关键词为无边框黑底星光、放大像素 `S`、绿色状态点。
- `Sources/Sotto/Resources/AppIcon/SottoIcon.svg`：Sotto macOS app icon 的源文件，视觉关键词为暗色舞台、聚光、点阵、像素 `S`。
- `Sources/Sotto/Resources/AppIcon/Sotto.icns`：本地 `.app` 打包使用的 macOS 图标文件。
- `artifacts/reference-repos/textream/`：Textream 开源 macOS 提词器源码本地参考归档；当前 commit `6c34baaef9fea5de30bce619b4ed34cd675d5617`，tag `v1.5.2`，README 声明 MIT；用于研究逐字语音追踪、语音激活滚动、窗口层、外接屏和远程控制机制，不作为 Sotto 主源码的一部分提交。
- `work/textream-reference-analysis-2026-05-09.md`：Textream 参考分析，记录功能地图、技术架构、逐字追踪机制、窗口/显示机制、远程控制机制和 Sotto 可吸收路线。
- `artifacts/raw/reference-videos/douyin-mmguo-ai-radio-vibe-coding-reference-2026-05-02.mp4`：抖音 AI 电台 vibe coding 参考视频，用于分析产品思想与 UI 设计语言。
- `artifacts/reference-screenshots/`：从参考视频抽取的关键截图，用于后续 UI/交互讨论。
- Unicorn Studio 场景 `xbdYsuMp0mSR01MXofEj`：Sotto 首页 / 准备中状态的外部 WebGL 背景候选；使用时需懒加载、控制 `scale` / `dpi` / `fps`，并提供静态降级背景。
- Magic UI `AnimatedThemeToggler`：未来明亮 / 黑暗模式切换的交互候选；本期不进入 MVP 0.1 实现范围。
- `Sources/Sotto/Resources/Fonts/fusion-pixel-12px-proportional.otf`：Fusion Pixel Font 简体中文像素字体，随 App 打包。
- `Sources/Sotto/Resources/Fonts/FusionPixelFont-OFL.txt`：Fusion Pixel Font 字体授权文件。

## 账号与权限提醒
不要在这里保存密码、Token、密钥。只记录资源位置和权限说明。
