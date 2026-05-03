# 推进记录

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
