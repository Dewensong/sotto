# Sotto GitHub 公开前审查（2026-05-10）

## 审查结论
当前项目适合作为“自用工具 + vibe coding 成果展示”继续收束，但不建议立刻以完整产品姿态公开。

更合适的公开口径是：
> Sotto is a personal macOS teleprompter built for vibe coding demos: a quiet backstage for speaking well.

也就是说，它可以展示为一个有明确使用场景、设计气质和真实迭代痕迹的作品，而不是宣称已经是通用稳定发行版。

## 当前优势
- 已经有真实 Mac App 工程，而不是静态原型。
- 自用场景明确：vibe coding、AI 产品 demo、录屏讲解、远程演示。
- 产品气质已经形成：暗色点阵、暖白舞台光、像素字标、低打扰提词层。
- 核心闭环已具备：粘贴稿件、自动切分、句子编辑、拆合、节奏设置、预览、正式提词窗口。
- 真实试用反馈已经进入产品：窗口 resize、专注模式、TUNE 抽屉、REC 状态、点击跳句、稿件管理。
- 工程已有行为测试和构建脚本，便于公开后别人理解运行方式。

## 公开前必须处理

### README 需要重写为对外版本
当前 `README.md` 更像项目工作台入口，适合协作，但不适合 GitHub 首页。公开版应优先回答：
- 这是什么？
- 为什么做？
- 它现在能做什么？
- 如何运行？
- 当前限制是什么？
- 这个项目如何体现 vibe coding？

### 截图 / 演示素材缺位
公开仓库至少需要：
- 首页截图。
- 编辑页截图。
- 正式提词窗口截图。
- 可选：30-60 秒演示 GIF 或短视频链接。

没有视觉素材时，Sotto 的气质会损失很多。

### 真实录屏验收仍未完成
README 中仍有未完成项：
- 麦克风授权提示首启体验。
- 真实录屏性能观察。
- 长稿现场稳定性验证。
- 语音激活播放阈值和屏幕共享隐藏验证。

这些应进入公开 Roadmap 或 Known limitations，避免对外描述过满。

### License 需要明确
公开仓库前需要决定：
- Sotto 源码使用什么许可证。
- 内置 Fusion Pixel Font 的 OFL 授权如何在 README 中说明。
- 参考 Textream 只作为机制参考，不作为本仓库源码组成部分。

### 参考素材归属需要控制
当前 `.gitignore` 已忽略：
- `artifacts/raw/`
- `artifacts/downloads/`
- `artifacts/reference-repos/`

这对公开仓库是正确的。公开时不要把原始参考视频、字体下载包、外部仓库归档一并提交。

## 初步安全扫描
本轮用关键词扫描了仓库内非大型归档文件，未发现明显 API key、password、private key、Bearer token 等敏感内容。

需要注意：`work/textream-reference-analysis-2026-05-09.md` 中出现的 `token` 是机制分析语境，不是实际密钥。

## 建议公开结构
建议公开仓库保留：
- `Sources/`
- `Tests/`
- `script/`
- `docs/` 中稳定产品和设计文档。
- `work/` 中少量能展示迭代过程的分析文档。
- `artifacts/reference-screenshots/` 中可公开的 Sotto 界面截图。
- 字体资源和授权文件。

建议公开前清理或继续忽略：
- 原始参考视频。
- 外部仓库完整归档。
- 字体下载原包。
- 本地构建产物。
- 过于内部化、只有过程噪音的临时材料。

## README 公开口径建议
不要把 Sotto 写成“AI 已经帮你生成完美演讲稿”的产品。当前更诚实、更有辨识度的表达是：

- Personal macOS teleprompter for vibe coding demos.
- Built to help me speak clearly while showing code, products, and AI workflows.
- Focused on the performance layer: paste a script, shape the rhythm, and keep a quiet prompt window on stage.
- Experimental, personal, and evolving in public.

## 发布前工作清单
- [ ] 完成一次自用验收并记录结果。
- [ ] 截取首页、编辑页、提词窗口、TUNE / 设置、稿件管理截图。
- [ ] 重写公开版 README。
- [ ] 增加 LICENSE。
- [ ] 增加 Roadmap / Known limitations。
- [ ] 确认 `.gitignore` 覆盖大型素材和本地产物。
- [ ] 运行 `swift test`。
- [ ] 运行 `./script/build_and_run.sh --verify`。
- [ ] 用 `git status --short` 复查公开提交范围。

## 建议的第一条 GitHub 发布描述
Sotto is a personal macOS teleprompter for vibe coding demos. It turns a prepared script into a calm, stage-like prompting experience with sentence editing, rhythm controls, a floating prompt window, and a visual language inspired by quiet backstage tools.
