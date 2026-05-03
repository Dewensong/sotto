# vibe-coding-teleprompter

## 一句话说明
面向 vibe coding 和 AI 产品演示的 Mac 原生 AI 智能提词器：把零散材料整理成自然口播稿，并在演示时用精致、低打扰的提词层辅助表达。

## 当前状态
- 阶段：MVP 0.1 Mac 原生可运行版已实现
- 最近更新时间：2026-05-03
- 当前进展：已基于 SwiftPM + SwiftUI 搭建 Sotto Mac App，实现稿件粘贴、确定性切分、手动切分点、聚光流预览、本地最近稿件保存和 AppKit 提词浮窗。
- 当前阻塞：暂无

## 下一步
- [x] 补充 `context.md`
- [x] 整理第一批资料到 `resources.md`
- [x] 明确本阶段目标和验收标准
- [x] 基于真实需求讨论收敛 MVP 0.1 范围
- [x] 产出聚光流提词器 MVP 0.1 设计规格
- [ ] 审阅并确认 `docs/superpowers/specs/2026-05-02-spotlight-flow-teleprompter-mvp-design.md`
- [x] 基于 MVP 0.1 规格实现第一版 Mac 原生可运行闭环
- [x] 选择一段已有口播稿作为聚光流提词测试样本
- [ ] 真实录屏场景试用 Sotto 提词浮窗，记录可读性、遮挡和节奏问题
- [ ] 根据真实试用结果调整提词窗口字号、位置、透明度和扫读节奏

## 项目索引
- `AGENTS.md`：Codex / 通用 AI 协作规则
- `CLAUDE.md`：Claude Code 协作规则
- `context.md`：项目背景、目标、约束
- `progress.md`：推进记录
- `decisions.md`：关键决策
- `resources.md`：云端资源、外部链接、素材索引
- `docs/`：稳定文档
- `work/`：推进中的草稿、实验、笔记
- `artifacts/`：过程资产
- `deliverables/`：阶段性交付物
- `archive/`：旧版本、废弃方案、历史备份

## 当前关键文档
- `docs/superpowers/plans/2026-05-03-sotto-mvp-0.1-macos-app.md`：MVP 0.1 Mac 原生可运行版实施计划
- `docs/product-definition-v1.md`：产品定义 V1，包含定位、核心需求、MVP、UI 方向和验收标准
- `docs/superpowers/specs/2026-05-02-spotlight-flow-teleprompter-mvp-design.md`：MVP 0.1 设计规格，聚焦 Mac 本机聚光流提词器
- `docs/sotto-ui-design-baseline-v1.md`：Sotto UI 设计基准 V1，沉淀 5 张参考图中的统一视觉语言和实现原则
- `docs/sotto-interaction-motion-principles-v1.md`：Sotto 交互与动效原则 V1，沉淀参考视频和 5 张 UI 图中的微交互、状态流转与生命感规则
- `docs/page-descriptions-mvp-0.1-reference.md`：MVP 0.1 页面描述参考，用于后续视觉风格探索，可随时调整
- `docs/homepage-reference-v1.md`：Sotto 首页参考 V1，记录已采纳的首页视觉方向和内容结构
- `docs/prompt-window-reference-v1.md`：Sotto 正式提词窗口参考 V1，记录已采纳的聚光流提词窗口方向
- `docs/script-editor-reference-v1.md`：Sotto 稿件编辑页参考 V1，记录已采纳的稿件准备台方向
- `docs/segmentation-panel-reference-v1.md`：Sotto 短语切分 / 节奏调整面板参考 V1，记录已采纳的切分交互细节
- `docs/preparing-state-reference-v1.md`：Sotto 自动切分处理中状态参考 V1，记录已采纳的准备上场等待状态
- `work/reference-analysis.md`：Claudio / AI 电台参考视频分析
- `artifacts/raw/reference-videos/`：原始参考视频
- `artifacts/reference-screenshots/`：参考视频关键截图

## 本地运行
- `swift test`：运行 SottoCore 行为测试
- `./script/build_and_run.sh --verify`：构建并启动 `dist/Sotto.app`，验证 Sotto 进程存在
- Codex App 的 Run 按钮已通过 `.codex/environments/environment.toml` 指向 `./script/build_and_run.sh`

## AI 协作提示
开始前请先读取 `AGENTS.md`，再结合 `README.md`、`context.md`、`progress.md`、`decisions.md` 进入项目状态。
