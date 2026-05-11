# Sotto GitHub 公开版 README 方案

## 目标
公开版 README 要同时服务两类读者：
- 对 vibe coding 感兴趣的人：快速理解这个项目为什么存在、有什么产品想法。
- 对代码和实现感兴趣的人：能 clone、运行、看懂工程结构和当前限制。

它不应该只是开发记录，也不应该包装成一个已经商业化成熟的产品。

## 推荐叙事

### 核心定位
Sotto is a personal macOS teleprompter for vibe coding demos.

中文可以对应为：
> Sotto 是一个为 vibe coding 和 AI 产品演示准备的 Mac 原生提词器：一个安静的表达后台。

### 项目故事
Dewens 需要在录屏、demo、远程展示中一边操作产品 / 代码，一边把思路讲清楚。普通滚动提词器太工具化，完整 AI 导演又过重。Sotto 先把最核心的一层做好：让已有稿件以低打扰、可调整、有舞台感的方式陪在屏幕上。

### 公开态度
这是一个自用优先、公开演进的 vibe coding 作品。它展示的不只是最终 App，也展示了产品判断、视觉气质、真实试用反馈和代码实现如何被逐步收束。

## README 建议结构

```markdown
# Sotto

Personal macOS teleprompter for vibe coding demos.

![Sotto hero screenshot](...)

## Why I built this

## What it does

## Current status

## Screenshots

## Features

## How it works

## Run locally

## Project structure

## Roadmap

## Known limitations

## Design notes

## Credits and references

## License
```

## 首屏建议
首屏要短，最好有截图。

推荐文案：
```markdown
# Sotto

Personal macOS teleprompter for vibe coding demos.

Sotto is a quiet backstage for speaking well while showing code, products, and AI workflows. Paste a prepared script, shape its rhythm sentence by sentence, and keep a low-distraction prompt window floating near your stage.
```

中文辅助可以放在后面，不要让首屏同时承担太多解释。

## Features 建议分组

### Script preparation
- Paste a prepared script.
- Deterministic Chinese / English sentence segmentation.
- Sentence-level editing, split, and merge.
- Pause and emphasis controls.
- Local document library.

### Prompting experience
- Floating AppKit prompt window.
- Timed playback and voice-activated playback.
- Token-level reading cursor.
- Click-to-jump sentence navigation.
- TUNE drawer for speed, size, opacity, width, and brightness.
- Position presets and keyboard shortcuts.

### Recording mode
- Focus mode hides the editor while prompting.
- Optional screen-sharing hide behavior.
- Low-distraction dark stage UI.
- Built-in pixel font resources.

## Current Status 建议
```markdown
Sotto is currently an MVP 0.1 build for personal use and public learning. The core prompting loop works locally, but it is not a polished product release yet.

Recently verified:
- Unit tests pass.
- Local build-and-run verification passes.

Still being validated:
- First-run microphone permission UX.
- Long-script stability.
- Real recording performance.
- Voice activation threshold in live demos.
```

## Roadmap 建议

### Before public demo
- Record one real 3-5 minute vibe coding demo with Sotto.
- Capture screenshots and a short demo clip.
- Improve microphone permission and fallback states.
- Validate screen-sharing hide behavior.

### MVP 0.2 candidates
- Better long-script navigation.
- Adjustable voice activation threshold.
- Readable font mode for long-form scripts.
- Export / import script files.
- External display or viewer mode.

### Later ideas
- AI-assisted script rewriting.
- Demo outline to speaking script.
- Speech recognition based follow-along.
- Browser / remote companion view.

## Known Limitations 建议
这一节要坦诚：
- Voice-activated playback is volume-gated, not full speech recognition.
- Screen-sharing hiding depends on macOS window behavior and needs real-tool verification.
- The app is built for the author’s workflow first.
- No signed release package yet.

## Credits 建议
需要明确：
- Fusion Pixel Font and OFL license.
- Textream as a reference project, not copied source.
- Visual references inspired the design direction but are not included as public assets.

## 截图清单
- `artifacts/reference-screenshots/sotto-homepage-v1.png` 可作为设计方向图，不一定是当前真实 App 截图。
- 公开版最好重新截当前 App 的真实运行图：
  - 首页。
  - 编辑工作台。
  - 正式提词窗口。
  - 设置 / TUNE。
  - 稿件管理。

## README 改版原则
- 用英文为主，中文补充可以放在项目背景或 notes 中。
- 不写过满的 AI 能力。
- 不把内部协作记录堆在首屏。
- 保留“personal tool”和“vibe coding artifact”的诚实感。
- 让读者能在 30 秒内知道它是什么，在 5 分钟内跑起来。
