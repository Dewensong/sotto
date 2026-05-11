# Sotto 公开发布素材检查 - 2026-05-11

## 本轮目标

为推送到 GitHub 前补齐第一批公开素材，让 README 不再只依赖文字说明或早期设计参考图。

## 已补齐素材

- 生成 `artifacts/github-media/sotto-logo-1024.png`，作为 GitHub 展示 logo，采用无边框品牌标识。
- 生成 `artifacts/github-media/sotto-app-icon-1024.png`，作为 macOS app icon 的预览图。
- 生成 `Sources/Sotto/Resources/AppIcon/SottoIcon.svg`，作为图标源文件。
- 生成 `Sources/Sotto/Resources/AppIcon/SottoLogo.svg`，作为品牌 logo 源文件。
- 生成 `Sources/Sotto/Resources/AppIcon/Sotto.icns`，作为 macOS app icon。
- 生成 `artifacts/github-media/sotto-github-hero.png`，作为 README 首屏 hero 图，包含编辑工作台和正式提词窗口。
- 截取当前真实运行界面：
  - `artifacts/github-media/sotto-home.png`
  - `artifacts/github-media/sotto-editor-workbench.png`
  - `artifacts/github-media/sotto-prompt-window.png`
  - `artifacts/github-media/sotto-prompt-settings.png`
  - `artifacts/github-media/sotto-document-library.png`
- 生成 `artifacts/github-media/sotto-demo-slideshow.mp4`，作为 40 秒静默短演示素材。

## 图标设计说明

本轮将品牌 logo 和 app icon 分层：

- GitHub / README logo：不透明点阵星光黑底，去掉圆角边框和底部进度线，只保留更大尺寸的像素 `S`、少量星点和绿色状态点。
- macOS app icon：保留轻微圆角容器、聚光和像素 `S`，用于桌面 / Dock / Finder 里的应用图标语境。

## Hero 图优化说明

新版 hero 从“截图拼贴”改为产品宣传照结构：上方保留 Sotto logo、标题、短定位文案和能力标签；下方用一张完整编辑工作台截图作为主视觉对象，右下叠放正式提词窗口，表达“准备稿件 + 悬浮提词”的核心场景。背景使用暗色舞台、星点和弱聚光，避免抢走真实产品截图的注意力。

## 验收边界

- 本轮素材来自当前本地运行 build，不是 DALL-E / 设计稿替代图。
- 短演示目前是静默截图 slideshow，不是完整真实操作录屏。
- 真实 3-5 分钟口播、麦克风首启和具体录屏工具的屏幕共享隐藏表现仍需单独验证。

## 下一步

- 用这批素材更新 README。
- 推送前再跑 `swift test` 和 `./script/build_and_run.sh --verify`。
