# Sotto

> [中文](README.md) | English

Personal macOS teleprompter for vibe coding demos.

<p align="center">
  <img src="artifacts/github-media/sotto-logo-1024.png" width="128" alt="Sotto logo">
</p>

Sotto is a quiet backstage for speaking well while showing code, products, and AI workflows. Paste a prepared script, shape its rhythm sentence by sentence, and keep a low-distraction prompt window floating near your stage.

![Sotto editor workbench and prompt window](artifacts/github-media/sotto-github-hero.png)

> 中文说明：Sotto 是一个为 vibe coding 和 AI 产品演示准备的 Mac 原生提词器。它优先服务 Dewens 自己的录屏、demo 和远程展示，也作为一个公开演进的 vibe coding 作品。

## Why I Built This

When recording a vibe coding session or an AI product demo, the hard part is not only building the thing. It is explaining the thinking while showing the thing.

Generic teleprompters feel too much like scrolling text boxes. Full AI director tools are too heavy for the first version. Sotto starts with the layer I need most: a calm, stage-like prompting experience for prepared scripts.

It is designed to help me:

- Speak clearly while showing code, products, and workflows.
- Keep a script nearby without covering the real demo.
- Shape rhythm before recording instead of improvising every sentence live.
- Treat the tool itself as part of the vibe coding artifact.

## Current Status

Sotto is currently an MVP 0.1 build for personal use and public learning. The core prompting loop works locally, but this is not a polished product release yet.

Recently verified locally:

- `swift test` passed 44 tests.
- `./script/build_and_run.sh --verify` built and launched `dist/Sotto.app`.
- Current app screenshots and a short silent demo slideshow were captured from the running local build.

Still being validated:

- First-run microphone permission experience.
- Voice activation threshold in real recordings.
- Screen-sharing hide behavior with actual recording tools.
- Long-script stability and performance.
- A full 3-5 minute real speaking demo.

## What It Does

### Script Preparation

- Paste a prepared script.
- Automatically split Chinese / English text into sentences and phrases.
- Edit the current sentence directly.
- Split one sentence into two, or merge it with the previous / next sentence.
- Add pause and emphasis settings that affect prompting rhythm.
- Save scripts into a local document library.

### Prompting Experience

- Open a floating AppKit prompt window above other Mac windows.
- Use timed playback or voice-activated playback.
- Read with a token-level cursor: Chinese advances by character, English / numbers advance by word.
- Click a sentence to jump during rehearsal or recording.
- Use the TUNE drawer to adjust speed, font size, opacity, width, and brightness.
- Move between position presets and use keyboard shortcuts for common controls.

### Recording Mode

- Focus mode hides the main editor while the prompt window is open.
- Optional screen-sharing hide behavior keeps the prompt window private in supported macOS capture paths.
- A low-distraction dark stage UI keeps the script readable without turning into the subject of the recording.
- Built-in Fusion Pixel Font resources keep the current visual style portable.

## Screenshots

These screenshots were captured from the current local MVP build.

![Sotto home screen](artifacts/github-media/sotto-home.png)

![Sotto editor workbench](artifacts/github-media/sotto-editor-workbench.png)

![Sotto floating prompt window](artifacts/github-media/sotto-prompt-window.png)

![Sotto prompt settings](artifacts/github-media/sotto-prompt-settings.png)

![Sotto document library](artifacts/github-media/sotto-document-library.png)

A short silent demo slideshow is available at [artifacts/github-media/sotto-demo-slideshow.mp4](artifacts/github-media/sotto-demo-slideshow.mp4).

The design direction is documented in:

- [Sotto UI Design Baseline](docs/sotto-ui-design-baseline-v1.md)
- [Homepage Reference](docs/references/homepage-reference-v1.md)
- [Prompt Window Reference](docs/references/prompt-window-reference-v1.md)
- [Script Editor Reference](docs/references/script-editor-reference-v1.md)

## Run Locally

Requirements:

- macOS 15 or later
- Swift 6 toolchain

Run tests:

```bash
swift test
```

Build and launch the local app:

```bash
./script/build_and_run.sh --verify
```

The script builds the SwiftPM package, creates `dist/Sotto.app`, launches it, and verifies that the process is running.

## Project Structure

```text
Sources/
  Sotto/                 # SwiftUI app, AppKit prompt window, visual system
  SottoCore/             # Models, segmentation, editing, storage, timing
Tests/SottoTests/        # Behavior tests for core logic and app state
script/                  # Build and run helpers
docs/                    # Stable product, design, and implementation notes
work/                    # In-progress research, reviews, and acceptance notes
artifacts/               # Local reference assets; large/raw folders are ignored
```

## Roadmap

### Before Public Demo

- Record one real 3-5 minute vibe coding demo with Sotto.
- Improve microphone permission and fallback states.
- Validate screen-sharing hide behavior with actual recording tools.

### MVP 0.2 Candidates

- Better long-script navigation.
- Adjustable voice activation threshold.
- Readable font mode for long-form scripts.
- Script import / export.
- External display or viewer mode.

### Later Ideas

- AI-assisted script rewriting.
- Demo outline to speaking script.
- Speech recognition based follow-along.
- Browser or remote companion view.

## Known Limitations

- Voice-activated playback is volume-gated, not full speech recognition.
- Screen-sharing hiding depends on macOS window behavior and must be validated with the specific recording / meeting tool.
- Sotto is built for my workflow first; general-purpose teleprompter polish is not the immediate goal.
- There is no signed release package yet.
- The current demo video is a silent screenshot slideshow, not a full narrated walkthrough.

## Design Notes

Sotto's visual direction is a dark, quiet backstage rather than a productivity dashboard. It uses warm stage light, subtle dot patterns, pixel-styled labels, and a floating prompt window to make speaking feel prepared without making the tool loud.

Key design references and decisions:

- [Product Definition V1](docs/product-definition-v1.md)
- [Sotto Interaction and Motion Principles](docs/sotto-interaction-motion-principles-v1.md)
- [MVP 0.1 Design Spec](docs/superpowers/specs/2026-05-02-spotlight-flow-teleprompter-mvp-design.md)
- [GitHub Public README Plan](work/github-public-readme-plan-2026-05-10.md)

## Public Release Notes

The current public release track is documented in:

- [Self-use Acceptance Plan](work/self-use-acceptance-2026-05-10.md)
- [Public Release Readiness Review](work/public-release-readiness-review-2026-05-10.md)
- [Public Release Media Check](work/public-release-media-check-2026-05-11.md)

This repository is intended to show both the app and the process: product judgment, visual exploration, real-use feedback, and implementation tradeoffs.

## Credits and References

- [Fusion Pixel Font](https://github.com/TakWolf/fusion-pixel-font): bundled font resource under the SIL Open Font License. See [FusionPixelFont-OFL.txt](Sources/Sotto/Resources/Fonts/FusionPixelFont-OFL.txt).
- [Textream](https://github.com/f/textream): studied as an open-source macOS teleprompter reference for mechanisms such as voice-triggered prompting and screen-sharing behavior. Sotto does not copy Textream UI or include its source as part of this app.
- Visual and interaction references are documented in [resources.md](resources.md). Raw reference videos and external repository archives are intentionally not part of the public source tree.

## License

Sotto is released under the [MIT License](LICENSE). The bundled Fusion Pixel Font keeps its original OFL license.

## For Future Collaborators

This project follows the local AI collaboration notes in [AGENTS.md](AGENTS.md). For current state, read:

- [context.md](context.md)
- [progress.md](progress.md)
- [decisions.md](decisions.md)
- [resources.md](resources.md)
