# 推进记录

## 2026-05-04
- 根据 Dewens 对全局字体范围的确认，将 Sotto 的系统 UI 文案、状态文案、控制文案、首页标题、副标题、步骤提示、分段控制和提词窗口控制层统一改为内置 Fusion Pixel Font 像素字体。
- 根据 Dewens 最新要求，取消此前对稿件输入、用户稿件、聚光预览正文和正式提词正文的字体豁免，将所有可见文字内容统一改为内置 Fusion Pixel Font 像素字体。
- 重新核对 `Sources/Sotto/Views` 中的字体引用，确认视图层已不再直接使用系统正文字体；系统字体仅保留在 `SottoFont` 的字体加载失败回退逻辑中。
- 根据 Dewens 对两张截图的布局反馈，修正首页根视图垂直对齐和窗口比例，去掉上方过多留白，并给首页“准备上场”区域留出更稳定的上下呼吸。
- 将编辑页从竖向挤压布局改为 1320 × 760 横向三栏工作台：左侧主稿件与句子列表，中间短语切分 / 节奏调整，右侧提词预览，移除原先会重叠的“面板 / 节奏 / 预览”分段切换。
- 验证结果：`swift test` 通过 11 个测试；`./script/build_and_run.sh --verify` 构建并启动成功；手动视觉验收确认首页上方留白减少、最近稿件层级清晰、编辑页三栏不再互相重叠。
- 根据 Dewens 对编辑页结构的新反馈，移除左侧原稿输入框，改为只展示已识别句子；编辑页重构为上半区左右双栏、下半区整宽提词预览：左上是句子列表，右上是短语切分 / 节奏调整，底部是完整横向预览。

## 2026-05-03
- 根据 Dewens 红框反馈定位首页像素字体未生效问题：SwiftPM 资源被平铺到 bundle 根目录，原实现只在 `Fonts/` 子目录查找，导致 `Sotto` 和首页标题回退为系统字体。
- 修复 `SottoFont` 字体资源查找逻辑，优先从 `Bundle.module` 根目录加载 `fusion-pixel-12px-proportional.otf`，并保留 `Fonts/` 子目录兼容；新增 `SottoFontTests`，验证 Fusion Pixel Font 能在进程内注册并创建 `NSFont`。
- 验证结果：`swift test` 通过 11 个测试；`./script/build_and_run.sh --verify` 构建并启动成功；手动视觉验收确认首页 `Sotto` 和「今天想让哪段想法上场？」已变为真实像素字体。
- 根据 Dewens 对字体使用的进一步反馈，修正像素字体实现方式：`PixelText` 不再叠加 Canvas 点阵 mask，而是直接使用内置 Fusion Pixel Font 渲染连续笔画；首页 `Sotto` 和「今天想让哪段想法上场？」继续使用真实像素字体。
- 修正提词正文可读性：切分面板当前句、提词预览和正式提词窗口中的句子改回普通系统正文，不再使用像素 / 点阵字体；品牌字标和状态字标保留像素字体。
- 验证结果：`swift test` 通过 10 个测试；`./script/build_and_run.sh --verify` 构建并启动成功；手动视觉验收确认首页标题不再是点阵 mask，预览和正式提词窗口句子已恢复普通可读文字。
- 根据 Dewens 反馈“当前 UI / 交互与预期相差甚远”，重新对照 5 张已采纳 Sotto 参考图进行差距评审，新增 `docs/sotto-ui-interaction-gap-review-v2.md`，明确当前实现只是技术底座，V2 需要围绕首页、准备中状态、编辑页、切分面板、提词浮窗和视觉组件底座做体验重构。
- 根据 Dewens 对参考图复刻、像素标题字体、主窗口尺寸和正式提词窗口形态的反馈，重构 Sotto UI：主窗口调整为稍大但无需纵向下滑的固定工作台；首页、准备中、编辑页、切分面板和预览统一为暗色点阵、暖白柔光、像素字标风格；正式提词窗口改为横向较大展示。
- 内置 Fusion Pixel Font 简体中文像素字体资源与 OFL 授权文件，新增运行时字体注册逻辑，避免依赖本机手动安装字体。
- 调整 AppKit 提词浮窗默认尺寸、面板底色、正文层级和未来句弱化方式，解决此前正式提词窗口过小、过雾、文字叠压的问题。
- 验证结果：`swift test` 通过 10 个测试；`./script/build_and_run.sh --verify` 构建并启动成功；手动视觉验收确认主窗口无需外层下滑，正式提词窗口横向展示且中文像素字体生效。
- 先将 2026-05-02 已沉淀的需求文档、视觉参考图、资源索引和项目记录提交为规格基线：`docs: establish Sotto MVP 0.1 baseline`。
- 创建实现分支 `codex/sotto-mvp-0.1`，从规格基线开始实现。
- 新增 `docs/superpowers/plans/2026-05-03-sotto-mvp-0.1-macos-app.md`，记录 Sotto MVP 0.1 Mac 原生可运行版的实施计划。
- 新增 SwiftPM 工程：`Package.swift`、`Sources/SottoCore/`、`Sources/Sotto/`、`Tests/SottoTests/`。
- 实现 SottoCore 核心模型：`PromptDocument`、`SentenceSegment`、`PhraseSegment`、`TimingProfile`、`PromptSession`、`TeleprompterSettings`。
- 实现确定性切分：支持中文 / 英文分句、换行段落、逗号 / 顿号 / 转折词短语切分、长句 2-4 段拆分和短句保留。
- 实现手动切分点：在选中句子的字间位置插入 / 取消短语切分点，非法位置忽略。
- 实现本地最近稿件保存：使用应用支持目录下的 JSON 文件保存最近 12 篇稿件。
- 实现 SwiftUI 主窗口：Sotto 首页、最近稿件、稿件编辑页、切分面板、速度分段控制、聚光流预览。
- 实现 AppKit 提词浮窗：置顶、半透明、无边框、可拖动的 `Sotto Prompt` 浮窗，显示上 1 句、当前 1 句、下 3 句，并支持播放 / 暂停、上一句 / 下一句、速度切换和关闭。
- 新增 `script/build_and_run.sh` 和 `.codex/environments/environment.toml`，支持 Codex Run 按钮与 `--verify` 构建启动验证。
- 验证结果：`swift test` 通过 10 个测试；`./script/build_and_run.sh --verify` 构建并启动成功；手动验收确认首页、最近稿件恢复、编辑页、切分面板、聚光流预览、提词浮窗和播放状态切换可用。

## 2026-05-02
- 创建项目骨架
- 初始化 AI 协作文件与目录结构
- 对齐产品方向：面向 Dewens 自己的 vibe coding / AI 产品演示场景，做 Mac 原生 AI 智能提词器。
- 确认第一版核心：材料转自然口播稿 + 精致提词界面 + 演示仪式感。
- 确认 UI 方向：参考 Claudio / AI 电台视频的暗色、微光、状态感和 AI 伙伴身份，落到“暗色精致工作台”。
- 整理竞品参考到 `resources.md`，包括 Mootch、CueNotch、Textream、VoicePrompter、Telepront。
- 将抖音参考视频登记为素材，并抽取 6 张关键截图到 `artifacts/reference-screenshots/`。
- 新增 `work/reference-analysis.md`，拆解参考视频的产品思想、UI 语言和可迁移原则。
- 新增 `docs/product-definition-v1.md`，沉淀 V1 产品定位、MVP 能力、UI 设计语言和验收标准。
- 更新 `context.md`、`decisions.md`、`README.md`，让项目从初始化进入需求定义阶段。
- 进一步按产品经理访谈方式细化需求，确认第一版先不做 AI 生成稿件，聚焦「已有稿件 -> 聚光流提词」。
- 新增 `docs/superpowers/specs/2026-05-02-spotlight-flow-teleprompter-mvp-design.md`，沉淀 MVP 0.1 设计规格。
- 确认 MVP 0.1 范围：Mac 本机提词窗口、稿件粘贴、自动/手动切分、速度滑杆、提词预览、聚光流提词。
- 确认暂缓范围：语音识别、要点模式、创作蓝图、风格模板、Side Cue、Screen Studio 隐藏、第二屏提词。
- 根据反馈删除 `docs/wireframes-mvp-0.1.md` 线框图，改为 `docs/page-descriptions-mvp-0.1-reference.md` 页面描述参考，并明确这些内容只是阶段性参考、可随时调整。
- 采纳产品名 `Sotto`，气质句为 `a quiet backstage for speaking well`。
- 采纳 GPT 网页端 DALL-E 3 生成的首页方向，并新增 `docs/homepage-reference-v1.md` 记录首页结构、文案、视觉元素和设计原则。
- 归档第二张 GPT 网页端 DALL-E 3 生成图为 `artifacts/reference-screenshots/sotto-prompt-window-v1.png`。
- 新增 `docs/prompt-window-reference-v1.md`，记录正式提词窗口 V1 的画面结构、视觉元素和设计原则。
- 归档第三张 GPT 网页端 DALL-E 3 生成图为 `artifacts/reference-screenshots/sotto-script-editor-v1.png`。
- 新增 `docs/script-editor-reference-v1.md`，记录稿件编辑页 V1 的画面结构、视觉元素和设计原则。
- 归档第四张 GPT 网页端 DALL-E 3 生成图为 `artifacts/reference-screenshots/sotto-segmentation-panel-v1.png`。
- 新增 `docs/segmentation-panel-reference-v1.md`，记录短语切分 / 节奏调整面板 V1 的画面结构、交互含义和设计原则。
- 归档第五张 GPT 网页端 DALL-E 3 生成图为 `artifacts/reference-screenshots/sotto-preparing-state-v1.png`。
- 新增 `docs/preparing-state-reference-v1.md`，记录自动切分处理中状态 V1 的画面结构、交互含义和设计原则。
- 新增 `docs/sotto-ui-design-baseline-v1.md`，基于 5 张已采纳参考图沉淀 Sotto 的品牌气质、视觉语言、组件规则、动效状态、文案语气和实现注意事项。
- 重新观察抖音 Claudio / AI 电台参考视频的状态流转、波形、状态点、聚光高亮与页面推进方式，并对照 5 张 Sotto UI 参考图，新增 `docs/sotto-interaction-motion-principles-v1.md`，沉淀首页灯光呼吸、背景点阵生命感、状态点、按钮、卡片、hover、页面流转和提词扫读的交互动效原则。
- 融入 React Bits `ElasticSlider` 参考：将其作为 Sotto 速度 / 节奏滑杆的交互灵感，保留轻微弹性、边界阻尼和拖动确认感，同时明确收敛 hover 放大、边界弹性和正式提词窗口中的复杂度。
- 融入 React Bits `FuzzyText` 参考：将其作为 `Sotto` 产品名和状态字标的轻微信号漂移动效灵感，明确只用于短字标，不用于正文稿件，并收敛 fuzzy 强度、范围、帧率和 glitch / click burst。
- 融入 React Bits `LightRays` 参考：将其作为 Sotto 首页顶部舞台光的实现灵感，明确采用 `top-center`、暖白低饱和、慢速呼吸、弱噪声、弱鼠标影响，并补充 WebGL 可见区域运行与减少动态效果降级规则。
- 融入 React Bits `PixelBlast` 参考：将其作为星光点阵之外的「像素颗粒幕布」背景选项，适用于首页、准备中和空状态，并明确低密度、低速度、低饱和、默认关闭 ripple / liquid、提词窗口弱化或关闭的使用边界。
- 融入 React Bits `ClickSpark` 参考：将其作为 `ON STAGE`、切分点插入、准备步骤完成等关键确认动作的短促微光反馈，明确不做全局点击火花，并收敛火花尺寸、半径、数量、时长和颜色。
- 融入 React Bits `ReflectiveCard` 参考：将其作为 Sotto 暗色玻璃卡片材质灵感，吸收轻反光、边缘高光、磨砂噪声和玻璃层次，同时明确不默认调用摄像头、不采用身份卡 / 安防视觉，并收敛金属感、模糊、位移和扭曲强度。
- 融入 Design Spells / Luma 活动打开与关闭转场参考：将其转译为 Sotto 的「来源连续转场」原则，用于最近稿件 -> 编辑页、当前句 -> 切分面板、提词预览 -> 正式提词窗口等场景，强调打开与关闭都要保留来源位置和空间连续性。
- 融入 Design Spells / Things 窗口最小尺寸 rubberbanding 参考：将其转译为 Sotto 的「窗口边界橡皮筋」原则，用于提词窗口 resize、拖拽到屏幕边缘、切分面板宽度边界等场景，明确只让外壳和边缘轻微回弹，不让正文变形。
- 融入 Design Spells / Linear 新 UI 动态公告卡片参考：将其转译为 Sotto 的「场合型公告卡片」原则，用于首次进入、新版本提示、稿件切分完成、成功导出等低频重要场合，强调精致但不营销、不频繁、不在提词中打断。
- 融入 Design Spells / AllTrails 选择筛选项时图标微动效参考：将其转译为 Sotto 的「选中时语义化 icon 微动效」原则，用于停顿、强调、速度模式和侧边步骤节点，强调只在选中变化时短促触发，不循环、不抢正文。
- 融入 Design Spells / Typefully 平滑侧边栏参考：将其转译为 Sotto 的「侧边面板滑动」原则，用于稿件编辑页右侧短语切分、状态调整、节奏控制面板，强调侧栏是工作台的一部分，打开、关闭和内容切换都要顺滑且不让主稿件丢失定位。
- 融入 Unicorn Studio 场景嵌入参考：登记项目 `xbdYsuMp0mSR01MXofEj` 与 SDK `2.1.11`，将其作为 Sotto 首页 / 准备中状态的外部 WebGL 背景候选，并明确懒加载、性能上限、静态降级、不用于正式提词窗口等边界。
- 融入 Magic UI `ProgressiveBlur` 参考：将其转译为 Sotto 的「滚动边缘渐进模糊」原则，用于稿件编辑区、最近稿件列表、切分面板、提词预览和提词窗口边缘弱化，强调它是阅读保护层，不遮挡当前句、当前短语和关键操作。
- 融入 Magic UI `DotPattern` 参考：将其确认为 Sotto 默认低成本 SVG 点阵背景底座，适用于首页、编辑页、切分面板和提词窗口，并根据反馈明确点阵背景默认也要有非常缓慢的呼吸感；`glow` 按场景分级，首页 / 准备中更明显，编辑区 / 提词窗口更弱、更慢，作为 PixelBlast 和 Unicorn Studio 的可靠降级层。
- 记录 Magic UI `AnimatedThemeToggler` 参考：作为后续明亮 / 黑暗模式切换的交互候选，转译为「全局换光」原则，明确本期不实现，只登记 View Transitions API、clip-path reveal、低干扰形状和直接切换降级规则。

## 记录规则
- 每次重要推进追加一条日期记录
- 记录做了什么、产出了什么、下一步是什么
- 不记录无实质价值的临时闲聊
