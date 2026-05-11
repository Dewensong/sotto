# Textream 参考分析

日期：2026-05-09

## 结论摘要

Textream 是一个原生 macOS 开源提词器，技术栈为 SwiftUI + AppKit + Speech / AVFoundation / Network。它和 Sotto 当前 SwiftPM + SwiftUI + 少量 AppKit 的路线接近，最值得吸收的不是 UI 皮肤，而是三类机制：

1. 逐字语音追踪：用 `SFSpeechRecognizer` 获取实时转写，再把转写结果和原稿做字符级、词级 fuzzy match。
2. 语音激活滚动：不理解语义，只用音量状态决定是否推进滚动，是完整语音跟稿之前的低风险过渡方案。
3. 提词输出层：置顶窗口、外接屏 / Sidecar、屏幕共享隐藏、浏览器远程同步和 Director 控制。

Sotto 不应该复刻 Textream 的 Dynamic Island 风格，也不应该直接把 Textream 的大段代码迁进来。更稳妥的方式是把它拆成若干能力设计参考，继续服务 Sotto 的暗色点阵、聚光流、像素字体和 AI 演示导演气质。

## 本地归档

- 本地路径：`artifacts/reference-repos/textream`
- GitHub：`https://github.com/f/textream`
- 当前分支：`master`
- 当前 commit：`6c34baaef9fea5de30bce619b4ed34cd675d5617`
- 当前 tag：`v1.5.2`
- 最新提交：`Bump version to 1.5.2`
- 授权：README 声明 MIT；当前仓库根目录未见独立 `LICENSE` 文件
- 体积：约 10M

## 功能地图

### 提词模式

Textream 把提词分成三种模式：

- Word Tracking：麦克风 + 系统语音识别，实时高亮用户说到的词。
- Classic：不需要麦克风，按固定 words/s 自动滚动。
- Voice-Activated：需要麦克风，有声音时滚动，静音时暂停。

对 Sotto 的启发：Sotto 现在已有确定性短语播放和麦克风音量反馈，可以自然演进为三层提词模式：

- 固定节奏：当前已有能力，继续保留为稳定基线。
- 语音激活：只用音量门限控制 `tickPlayback`，优先级最高。
- 逐字追踪：用语音识别和 fuzzy match 校准阅读位置，作为 0.2+ 原型。

### 显示模式

Textream 支持：

- Pinned to Notch：贴近 MacBook 刘海的 Dynamic Island 样式窗口。
- Floating Window：可拖拽置顶浮窗。
- Fullscreen：指定屏幕全屏提词。
- External Display / Sidecar：外接屏或 iPad 输出，可镜像翻转。
- Remote Browser：局域网浏览器同步提词。
- Director Mode：远程浏览器编辑和推送稿件。

对 Sotto 的启发：Sotto 当前已经有正式提词浮窗和专注模式，本阶段只应吸收窗口层机制，例如屏幕共享隐藏、Esc 退出和外接屏设计，不吸收 Textream 的刘海视觉表达。

### 文件和素材

Textream 支持：

- `.textream` 文件保存多页稿件。
- `.pptx` 演讲者备注导入。
- 多页稿件和自动翻页。

对 Sotto 的启发：Sotto 当前以最近稿件和单篇口播稿为主。后续如果进入“演示导演”方向，PPT 备注导入和多页段落可以作为产品化能力，但不应进入当前 Textream 分析任务。

## 技术架构

核心文件：

- `Textream/Textream/SpeechRecognizer.swift`：语音识别、音量采样、识别重启、fuzzy matching。
- `Textream/Textream/MarqueeTextView.swift`：CJK-aware token 切分、词级布局、高亮、滚动定位、tap-to-jump。
- `Textream/Textream/NotchOverlayController.swift`：AppKit `NSPanel` 展示、置顶窗口、刘海 / 悬浮 / 全屏模式、屏幕共享隐藏。
- `Textream/Textream/ExternalDisplayController.swift`：外接屏 / Sidecar 输出和镜像。
- `Textream/Textream/BrowserServer.swift`：本机 HTTP + WebSocket 远程预览。
- `Textream/Textream/DirectorServer.swift`：远程导演模式、认证 token、远程 set / update / stop 命令。
- `Textream/Textream/PresentationNotesExtractor.swift`：PPTX 解包和备注 XML 解析。

整体架构偏单体，但能力边界比较清楚：语音识别独立、显示控制独立、浏览器同步独立。Sotto 如果吸收，应避免复制它的全局 singleton 形态，而是保持当前 `AppModel` + Core model + AppKit controller 的分层。

## 逐字追踪机制

Textream 的逐字追踪关键点：

1. 先用 `splitTextIntoWords` 把原稿规整成显示 token。
2. 中文、日文、韩文按单字符拆分，英文按词拆分。
3. 识别结果来自 `SFSpeechRecognizer` 的 `bestTranscription.formattedString`。
4. 匹配时从 `matchStartOffset` 之后的剩余文本开始，避免每次从头匹配。
5. 同时跑字符级 match 和词级 match。
6. 两种结果接近时取平均；差异过大时取保守的较小位置。
7. 用最近 3 次候选位置做 confidence gating，至少 2 次接近才允许大跳。
8. 小步前进直接允许，保证高亮反馈不会显得迟钝。
9. 识别任务每 55 秒预防性重启，兼容系统语音识别的持续时长限制。
10. 手动点击词后会 jump 到对应 char offset，并重启识别。

对 Sotto 的迁移判断：

- 可吸收：fuzzy match 思路、`matchStartOffset`、2-of-3 gating、小步直接推进、55 秒重启。
- 需重写：token 模型。Sotto 当前是 `SentenceSegment` / `PhraseSegment`，不能直接变成全局 words 数组，否则会破坏聚光流。
- 建议新增：只服务提词态的 `ReadingToken` 层，包含 token text、sentenceIndex、phraseIndex、localOffset、globalCharOffset。
- 中文注意：逐字追踪对中文天然更像“逐字”，但实际语音识别输出可能没有稳定空格，需用字符级匹配优先，词级匹配只作辅助。

## 语音激活滚动机制

Textream 用音频 RMS 生成 `audioLevels`，并用最近 10 个 level 的平均值判断 `isSpeaking`，阈值约为 `0.08`。Classic 模式按固定速度推进；Voice-Activated 模式只有 `isSpeaking == true` 时才推进。

对 Sotto 的迁移判断：

- 这是最适合优先试的能力，因为 Sotto 已经有 `AudioLevelMonitor` 和 `microphoneLevel`。
- 不需要引入 Speech framework，不涉及语音识别权限，只需要麦克风权限。
- 可在 `tickPlayback` 前增加阅读模式判断：固定节奏始终推进，语音激活只在音量超过阈值时推进。
- 阈值应做成内部常量或轻量设置，先不暴露复杂调参。
- UI 上可以先放进 TUNE 抽屉或全局设置齿轮，不要加重正式提词默认控制栏。

## 窗口和显示机制

Textream 的窗口层主要使用 `NSPanel`：

- `.borderless` + `.nonactivatingPanel` 做低干扰置顶窗口。
- `panel.level = .screenSaver` 保证覆盖其他 App。
- `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]` 支持全屏空间。
- `panel.sharingType = .none` 实现隐藏于屏幕共享或录屏。
- 全屏模式直接把 panel frame 设成目标屏幕 frame。
- 外接屏输出和主屏浮窗共享同一个 `SpeechRecognizer` 状态。

对 Sotto 的迁移判断：

- Sotto 已经有 AppKit 提词浮窗，不需要重做窗口控制。
- `sharingType = .none` 是高价值小能力，适合尽快做成设置项，满足“录屏/会议里只自己可见”的场景。
- 外接屏 / Sidecar 输出可以作为 0.2+，但需要先定义 Sotto 是否要支持“给自己看第二屏”还是“镜像给提词器硬件看”。
- Esc 退出、屏幕选择、外接屏断开恢复都应进入后续测试清单。

## 远程控制机制

Textream 有两套本机网络能力：

- BrowserServer：HTTP 提供网页，WebSocket 每 100ms 广播提词状态。
- DirectorServer：远程浏览器可 setText、updateText、stop，并通过随机 token 鉴权。

广播字段包括：

- `words`
- `highlightedCharCount`
- `totalCharCount`
- `audioLevels`
- `isListening`
- `isDone`
- `fontColor`
- `lastSpokenText`

对 Sotto 的迁移判断：

- 远程浏览器提词适合 Sotto 的 iPad / 手机副屏方向。
- Director 模式适合“有人帮我控稿”或直播团队场景，不适合当前个人 vibe coding MVP。
- 如果后续实现，优先只做只读远程显示，不先开放远程编辑，降低安全和产品复杂度。

## 可迁移点

按优先级排序：

1. 语音激活播放：最小改动，直接改善自然口播节奏。
2. 屏幕共享隐藏：小改动，高价值，符合录屏/会议场景。
3. 逐字追踪原型：高价值但复杂，应单独做技术 spike。
4. CJK-aware `ReadingToken`：逐字追踪的前置结构，不应直接改现有稿件模型。
5. Tap-to-jump 到 token：当前 Sotto 已支持点击句子跳转，后续可细化到短语或 token。
6. 外接屏 / Sidecar：适合真实演示成熟后做。
7. 浏览器只读同步：适合 iPad/手机提词。
8. PPTX 备注导入：适合演示导演方向，但和当前提词体验不是同一优先级。

## 暂不迁移点

- Dynamic Island / Notch UI：Textream 的品牌视觉，不符合 Sotto 的演出后台和聚光流方向。
- Director 远程编辑：能力强但产品复杂度高，当前会稀释 MVP。
- 多页文件系统：Sotto 当前还在验证单篇口播稿体验，先不引入文件格式。
- 全量 SpeechRecognizer 代码复制：它和 Textream 的全局 words 模型绑定较深，直接复制会和 Sotto 的句子/短语模型冲突。
- 浏览器服务：需要网络权限、安全提示、端口管理和二维码，不适合这次吸收。

## Sotto 落地建议

### 近期，0.1+

1. 加一个“语音激活推进”阅读模式。
   - 复用 `AudioLevelMonitor`。
   - 在 `AppModel.tickPlayback` 或更薄的 playback controller 中判断音量。
   - 静音时保留当前句/短语位置，不重置 `phraseProgress`。
   - 单元测试覆盖静音不推进、有声推进、恢复后继续。

2. 加一个“隐藏于屏幕共享 / 录屏”的设置项。
   - 在 `TeleprompterSettings` 增加布尔值，默认可讨论：若默认隐藏，录屏时用户可能以为没录进去；若默认不隐藏，更符合当前可见验证。
   - `TeleprompterWindowController` 配置窗口时设置 `window.sharingType`。
   - 设置入口放在齿轮浮层或 TUNE 抽屉，不放进正文区域。

### 中期，0.2

1. 做逐字追踪 spike。
   - 新增 `ReadingToken` 生成器。
   - 先用本地测试覆盖中文、英文、中英混排、标点、空白。
   - 再接入 `SFSpeechRecognizer`，只在正式提词窗口里作为实验模式。
   - UI 仍保持“当前短语柔光扫读”，逐字追踪只负责校准位置，不让界面变成普通歌词高亮器。

2. 做外接屏 / Sidecar 设计稿和技术验证。
   - 明确主屏是否仍显示 Sotto Prompt。
   - 明确第二屏是正向文本还是镜像文本。
   - 明确 Screen Studio / Zoom / Meet 里的可见性策略。

### 长期

1. 浏览器只读同步：让手机/iPad 作为副提词屏。
2. Director 模式：允许远程协作者控稿，但需要安全模型和真实团队场景。
3. PPTX 备注导入：把产品从“口播稿提词器”扩展到“演示导演”。

## 后续验证清单

- 下载验证：本地 clone 路径存在，commit 为 `6c34baaef9fea5de30bce619b4ed34cd675d5617`。
- 文档验证：`resources.md`、本分析文档、`progress.md` 均能指向本地归档和关键结论。
- 代码实现前验证：先新增 token / playback 单元测试，再改实现。
- 体验验证：真实录屏里分别验证固定节奏、语音激活、屏幕共享隐藏是否符合预期。
