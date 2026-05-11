# 推进记录

## 2026-05-11（GitHub 公开前仓库体检）

- **完成公开前全面体检**：仓库卫生检查（`.gitignore` 覆盖完整、无 `.DS_Store`/构建产物被跟踪、公开素材大小合理）、敏感信息扫描（无 API key / token / 密码 / 邮箱 / 手机号泄露）、README 公开可读性确认（30 秒可理解、未过度承诺 AI、明确 MVP/自用/无签名/跟声限制）、构建验证（`swift test` 44 测试通过、`build_and_run.sh --verify` 成功、`CFBundleIconFile` 和 `Sotto.icns` 已就位）。
- **结论**：仓库卫生和敏感信息均无阻断项，可以准备提交并推 GitHub；仅需注意 `artifacts/reference-screenshots/` 中的 Claudio 参考截图来自公开抖音视频、`work/` 文件包含内部开发笔记但已决定公开展示过程。

## 2026-05-11（GitHub 公开素材准备）

- **补齐 GitHub 首屏素材**：新增 `artifacts/github-media/` 公开素材目录，放入当前真实运行 build 截图、README hero 图、logo PNG 和短演示 slideshow；README 首屏已引用 logo 与 hero 图，截图区已改为真实运行截图。
- **重做 README hero 构图**：将原先截图拼贴式 hero 改为产品宣传照结构：上方是 logo、标题、定位文案和能力标签，下方以编辑工作台为主视觉对象，右下叠放正式提词窗口，减少“不明所以”的信息噪音。
- **补齐 App 图标 / Logo**：新增 `Sources/Sotto/Resources/AppIcon/SottoIcon.svg`、`SottoLogo.svg` 与 `Sotto.icns`。品牌 logo 采用无边框点阵星光黑底 + 放大像素 `S`，用于 README / GitHub；macOS app icon 保留轻微圆角容器、聚光和像素 `S`，用于 `.app` 语境；`script/build_and_run.sh` 已把 `.icns` 复制进 `.app` bundle 并写入 `CFBundleIconFile`。
- **补齐公开授权**：新增根目录 `LICENSE`，Sotto 源码采用 MIT License；`decisions.md` 记录授权取舍，README 说明 Fusion Pixel Font 仍保留原始 OFL 授权。
- **补齐发布素材记录**：新增 `work/public-release-media-check-2026-05-11.md`，记录本轮素材清单、图标设计说明和验收边界；更新 `resources.md` 登记 GitHub 媒体目录与图标资源。
- **仍需真实验证**：本轮短演示是静默截图 slideshow，不替代完整 3-5 分钟真实口播；麦克风首启、具体录屏工具的屏幕共享隐藏和长稿性能仍需单独试用。

## 2026-05-11（续二）

- **修复跟声模式不跟声**：三个根因叠加——归一化公式 `(dB + 58) / 42` 把正常说话映射到 0.43-0.90 但阈值滑杆范围只覆盖 0.01-0.12（全是底噪区）；EMA 平滑 `0.72*old + 0.28*new` 延迟约 80-100ms；无迟滞导致单次静音 buffer 就冻结播放。修复：归一化改为 `(dB + 60) / 50` 拉宽动态范围；EMA 改为 `0.45*old + 0.55*new` 加快响应；`shouldAdvancePlayback` 增加迟滞（需连续 4 帧低于阈值才暂停）；滑杆范围改为 `0.08...0.50`，默认阈值改为 `0.12`；更新测试适配迟滞逻辑。
- **新增光标模式三选一**：`TokenCursorMode` 枚举（`.character` 逐字 / `.word` 逐词 / `.line` 逐行），默认逐字；`.word` 模式下当前短语所有 token 同时高亮；`.line` 模式跳过 token sweep 直接渲染整句；设置面板"阅读模式"下方新增"光标模式"三选一控件；`TeleprompterSettings` 新增 `cursorMode` 属性，`AppModel` 新增 `setCursorMode`。
- **新增快捷键提示 + 重新开始**：`AppModel` 新增 `restartSession()` 回到第 0 句、停播、清零计时；`SottoApp` 新增 Cmd+Shift+R 菜单项；提词器左侧 sidebar 新增快捷键提示区（Space 播放/暂停、⇧⌘R 从头开始、⌘←→ 上下句、Esc 退出），以像素字体 keycap 样式展示。
- **提升长稿导航**：每行左侧加句号；sidebar 的 `XX / YY` 进度文字改为可点击按钮，点击弹出 `SentencePickerView` popover（全部句子序号+首行文字列表，当前句高亮，点击跳转）；`SottoApp` 新增 Cmd+↑ 跳到开头、Cmd+↓ 跳到结尾快捷键。
- **验证**：`swift build` 无警告，`swift test` 44 测试通过，已重新构建 `dist/Sotto.app`。

## 2026-05-11（续）

- **清理提词器窗口死代码**：删除 `PhraseSweepView`、`TokenCursorView`、`ReadingToken`、`PhraseGlow` 和无用的 `Character` 扩展，共 171 行。这些是旧版短语扫光/光标组件的残留，已完全被 `CurrentSentenceSweepView` + `SentenceSweepToken` 替代。
- **提词器侧边栏计时替换为真实耗时**：移除硬编码的 "01:24"，改为基于 `tickPlayback` 累计的实际播放时长（`MM:SS` 格式），播放开始自动清零，暂停保持，返回首页/关闭提词器时重置。
- **麦克风权限首次体验优化**：`AudioLevelMonitor` 新增 `permissionStatus` 发布属性，`AppModel` 订阅权限状态并暴露 `microphonePermissionDenied`；打开提词器或切换到跟声模式时若权限被拒绝，显示红色错误 toast 提示"麦克风权限未开启"；新增 `openMicrophoneSettings()` 可跳转系统设置；设置面板在跟声模式 + 权限拒绝时显示红色警告标签。
- **确认屏幕共享隐藏已实现**：机制来自 Textream 的 `NSWindow.sharingType = .none`，已通过 `TeleprompterSettings.hidesFromScreenShare` → `TeleprompterWindowController.applyScreenSharingVisibility` 完整落地，设置面板"屏幕共享"切换可用，5 个测试覆盖。
- **验证**：`swift build` 无警告，`swift test` 44 测试通过。
- **修复提词器面板计时**：计时器从逐 tick 累加改为基于墙钟的实时计算——新增 `playbackSegmentStart` + `playbackPausedElapsed` 记录播放段起始和暂停时累计耗时，`refreshElapsedDisplay()` 每次 tick 按墙钟差值刷新 `playbackElapsedDisplay`；打开/关闭/返回首页时正确重置；删除已无用的 `playbackElapsedTime` 属性。
- **修复逐字 token 光标卡顿**：移除 `CurrentSentenceSweepView` 和 `ScrollView` 上对 `progress` 值的 `.animation(.linear(duration: 0.08))` 动画——30fps tick 每次更新 progress 都会触发 80ms 动画，下一帧（33ms 后）新的 progress 值到达便中断上一次动画重新开始，造成持续"中断-重启"式的卡顿感。去掉 progress 动画后 token 状态切换瞬时完成，帧率级更新本身已足够平滑。
- **修复提词器窗口无法拖动**：此前为修 TUNE 滑条拖动带动窗口，把 `isMovableByWindowBackground` 关掉，导致窗口完全失去拖动能力。改为保持 `false`，新增 `WindowDragHandle`（NSViewRepresentable + `performDrag(with:)`）作为顶部 36px 透明拖拽把手；TUNE 展开时自动禁用拖拽把手避免与滑条冲突。
- **验证**：`swift build` 无警告，`swift test` 44 测试通过，已重新构建 `dist/Sotto.app`。

## 2026-05-11

- **修复稿件保存失败的根因**：`PromptDocument` 新增 `isArchived` 字段后，合成 `Decodable` 要求 JSON 中存在该 key；但本地已有 12 篇旧文档（`~/Library/Application Support/Sotto/recent-documents.json`，94KB）不含此字段，导致 `loadRecentDocuments()` 解码失败 → `store.save()` 整体抛出 → 保存静默失败，用户无任何反馈。修复：为 `PromptDocument` 添加自定义 `init(from:)`，对 `isArchived` 使用 `decodeIfPresent` 并缺省 `false`。
- **修复所有错误静默失败问题**：`AppModel.errorMessage` 在 7 处被赋值但没有任何 view 读取，所有持久化错误对用户不可见。修复：移除 `errorMessage`，新增 `SottoToastMessage` 类型和 `triggerErrorToast` 方法，将 `loadRecentDocuments`、`saveCurrentDocument`、`removeRecentDocument`、`toggleArchive` 及 HomeView 文件解析的错误全部改为红色 toast 提示，3 秒后自动消失。
- 验证：`swift build` 无警告，`swift test` 44 测试通过，经验证旧 JSON 文件 12 篇文档均缺 `isArchived` 字段——修复后解码正常。

- **修复首页准备上场后稿件未存入全部稿件列表的问题**：`createDocumentFromInput()` 原先在延迟 Task 中通过 `saveCurrentDocument()` 间接保存，现改为在 Preparing 过渡动画前通过 `store.save()` 直接持久化并刷新列表；新增 `saveInputToLibrary()` 独立保存方法。
- **新增首页输入区"一键保存到全部稿件"按钮**：在输入区工具栏（清空 / 展开 / 导入文件旁）增加 `tray.and.arrow.down` 保存按钮，点击后直接分段、生成标题并存入本地稿件库，无需进入编辑流程。
- **新增保存成功提示 toast**：在 ContentView 层增加 `SottoSaveToast` 组件，以暖色胶囊 + 勾选图标 + 弹簧动效的形式提示"已保存到全部稿件"，2 秒后自动淡出；准备上场和手动保存两个路径都会触发提示。
- 验证：`swift build` 无警告，`swift test` 44 个测试全部通过，`./script/build_and_run.sh --verify` 成功启动。
- 根据 Dewens 对 TUNE 面板的反馈，修复滑条拖动会带动整个提词面板的问题：关闭 AppKit 提词窗口的 `isMovableByWindowBackground`，并在 TUNE 打开时禁用隐形 resize 命中层，避免控制面板手势被窗口拖拽 / 缩放抢走。
- 将 TUNE 面板从 5 个无解释滑条重构为更适合现场理解的组合控件：速度改为慢 / 稳 / 快档位，字号和宽度改为步进按钮，透明度改为轻 / 柔 / 清档位，亮度保留单根滑条；每个参数补充中文含义说明。
- 做了一轮公开前最小产品优化包：将首页主文案从内部准备口吻调整为更适合公开截图 / demo 开场的表达，能力标签从“短语切分 / 停顿建议”更新为更贴近当前实现的“句子拆合 / 跟声试验 / 录屏提词”。
- 调整正式提词窗口默认参数为更接近真实录屏的展示状态：默认靠近镜头位置、窗口 900 × 520、字号 36、透明度 96%、亮度 104%、速度倍率 0.72x，并新增测试锁住默认值。
- 在设置齿轮的阅读模式下增加轻量说明：定时模式作为最稳定默认排练路径，跟声模式明确是按音量推进、不是逐字识别，降低真实试用时的误解。
- 基于 `docs/github-public-readme-plan-2026-05-10.md` 将 `README.md` 从内部进度入口改为 GitHub 公开版首页初稿：首屏改为英文 personal macOS teleprompter for vibe coding demos，保留中文说明、自用背景、功能分组、本地运行、Roadmap、Known limitations、设计参考、公开发布备注、Credits 和未来协作者入口。
- 根据 Dewens 对 Sotto 下一阶段的定位补充，明确项目接下来同时服务两个目标：一是 Dewens 自用的 vibe coding / AI 产品演示提词工具，二是后续推到 GitHub 的公开 vibe coding 成果展示。
- 新增 `work/self-use-acceptance-2026-05-10.md`，把下一轮真实使用验收整理为可执行流程，覆盖 3-5 分钟真实稿件、定时 / 跟声模式、屏幕共享隐藏、长稿稳定性、现场操控和录屏安全。
- 新增 `work/public-release-readiness-review-2026-05-10.md`，完成公开仓库前第一轮审查：当前适合以 personal macOS teleprompter for vibe coding demos 的口径公开，但不应包装成成熟通用产品；README、截图 / 演示素材、License、Known limitations 和真实录屏验收仍需补齐。
- 新增 `docs/github-public-readme-plan-2026-05-10.md`，整理公开版 README 的推荐叙事、首屏文案、Features 分组、Current Status、Roadmap、Known limitations、Credits 和截图清单。
- 更新 `decisions.md`，记录公开路线采用“自用工具 + vibe coding 成果展示”的关键取舍。
- 根据 Dewens 真实试用反馈，确认此前“短语切分”实际是句内短语节奏点，不符合“选择一句后拆成两句、两句合并为一句”的句子级编辑预期；本轮将右侧面板语义改为“句子编辑 / 拆合 / 节奏”。
- 新增句子级编辑能力：当前句可直接在右侧 TextEditor 中修改，修改后自动更新 `PromptDocument.rawText`、当前提词 session 和最近稿件保存。
- 新增句子拆分 / 合并能力：点击当前句字间光标可把一句拆成两句，并支持与上一句 / 下一句合并；拆合后会重建内部短语节奏、重置播放光标并保持文档自动保存。
- 优化编辑页看板表达：左侧从“已识别句子”调整为“稿件看板”，每句显示序号、正文和内部段数；右侧面板显示自动保存状态、字数、拆句提示、合并按钮和节奏设置，降低原先“切分点”含义不清的问题。
- 根据 Dewens 对右上面板截图的进一步标注，将“句子编辑 / 拆合 / 节奏”面板改为左右列：左侧负责当前句文案编辑和可展开的句子拆分设置，展开后才显示字间拆分光标、合并上句、合并下句；右侧独立承接停顿设置、强调设置和预计耗时，减少默认态信息密度。
- 修复右上面板与下方提词预览反复重叠的问题：根因是固定高度面板内部内容继续增长，右侧节奏列的 `Spacer` 会把预计耗时推到面板底部并越界绘制；本轮移除该 `Spacer`，收紧当前句编辑框和拆分入口高度，将上方面板高度从 350 收到 300、上下间距从 22 收到 18，并给上方面板加 `clipped()` 作为越界防线。
- 补齐稿件管理能力：首页“最近稿件”新增“管理全部”入口，进入独立 `DocumentManagerView`，可以查看全部本地稿件、打开稿件、放回首页输入区或删除稿件。
- 调整本地存储语义：`PromptDocumentStore` 不再只保留最近 12 篇，而是保存全部稿件；首页仍只展示最近 3 篇，稿件管理页展示完整列表。
- 用测试锁住稿件管理行为：覆盖稿件管理状态可进入 / 返回、首页粘贴进入准备上场后会自动把稿件保存到稿件库，以及本地库可以保留超过 12 篇稿件。
- 优化正式提词窗口 resize 命中区：此前只有四角透明小热区，鼠标放到边缘或角落附近容易一晃而过；本轮将四角命中区扩大到 64 × 64，并新增顶部、底部、左侧、右侧 44px 连续透明拖拽带，支持从边缘和角落都能调整窗口大小。
- 优化正式提词窗口文字宽度适配：参考 HTML/PPT 文案适配预检的“先估算文本宽度和行数预算”思路，新增 `PromptTextFitEstimator`，根据当前提词窗口宽度、请求字号、目标行数动态估算当前句字号；同时修正当前句 token 高亮的嵌套布局，改为单层 token FlowLayout，避免内层默认按约 300px 宽度排版导致窗口变宽后仍固定换行。
- 修复正式提词窗口播放 / 暂停按钮点击不灵敏：根因是放大的底部 resize 透明拖拽带覆盖了底部控制栏，点击会被 resize 手势吃掉；本轮将底部拖拽带收窄到贴边 14px，并收窄左右边缘拖拽带，保留四角大热区但避免遮挡控制按钮。
- 优化定时模式初始速度：新增 `TeleprompterSettings.speedMultiplier`，默认 `0.75x`，播放 tick 按 `elapsed * speedMultiplier / duration` 推进；TUNE 中的 SPD 从原来的三档 timing 选择改为 0.55x-1.65x 全局倍率滑杆，支持在基础节奏上整体加速或减速。
- 优化提词进度光标：正式提词窗口当前短语从整体扫光改为 token 光标；中文按字推进，英文 / 数字按词推进，当前 token 有底线和柔光，过去 / 未来 token 用不同透明度区分。
- 优化跟声模式灵敏度：将语音激活阈值从 `0.08` 降低到 `0.035`，保留静音暂停和有声推进测试覆盖，降低真实说话时“不跟声”的概率。
- 新增测试覆盖句子拆分、无效切点、句子合并、当前句编辑自动保存、拆句后文档 / session 同步、合并后文档 / session 同步；验证结果：`swift test` 通过 35 个测试。

## 2026-05-09
- 根据 Dewens 找到的开源 Mac 提词器项目 Textream，下载源码到 `artifacts/reference-repos/textream/` 作为外部参考归档；已核对当前本地归档位于 `master` / `v1.5.2`，commit 为 `6c34baaef9fea5de30bce619b4ed34cd675d5617`。
- 新增 `work/textream-reference-analysis-2026-05-09.md`，系统拆解 Textream 的逐字语音追踪、语音激活滚动、CJK token 切分、AppKit 窗口层、屏幕共享隐藏、外接屏 / Sidecar、浏览器远程同步和 Director 模式。
- 明确本次只把 Textream 作为机制参考，不复制 Dynamic Island / Notch UI，也不直接迁入大段源码；Sotto 仍保持暗色点阵、聚光流、像素字体和 AI 演示导演气质。
- 将后续可吸收能力排序为：语音激活播放、屏幕共享隐藏、逐字追踪原型、外接屏 / Sidecar、浏览器只读同步和 Director 模式；其中语音激活播放可复用现有 `AudioLevelMonitor`，逐字追踪需要先新增 `ReadingToken` 层。
- 更新 `resources.md` 登记 Textream 本地源码归档、commit、授权说明和分析文档；更新 `.gitignore` 忽略 `artifacts/reference-repos/`，避免误把外部仓库提交进 Sotto 主仓库。
- 根据 Textream 分析优先落地两个低风险能力：新增 `PromptReadingMode`，在设置齿轮中提供 `TIME` / `VOICE` 阅读模式；语音激活模式下播放 tick 只在麦克风音量超过阈值时推进，静音时冻结当前短语进度且不累计静音时间。
- 新增屏幕共享隐藏开关：设置齿轮中可切换 `VISIBLE` / `HIDDEN`，正式提词窗口会根据 `TeleprompterSettings.hidesFromScreenShare` 设置 `NSWindow.sharingType`，用于录屏 / 会议场景中让提词窗口只给自己看。
- 新增测试覆盖语音激活静音不推进、有声推进，以及提词窗口 `sharingType` 在隐藏 / 可见两种状态下的行为。
- 根据 Dewens 反馈将设置齿轮浮层中文化：标题、窗口位置、阅读模式、屏幕共享、亮度、状态芯片和按钮文案均改为中文短文案，并收紧中文像素字距以适配小面板。

## 2026-05-07
- 根据 Dewens 第一次真实试用反馈，确认本轮重点从“动效补齐”转为“后台可操作重心 + 正式提词真实可用性”。
- 优化编辑页右侧布局：收紧上方短语切分面板高度，增加与下方提词预览之间的垂直间距，并拉开预览标题和正文，避免停顿 / 强调 / 耗时控制与提词预览挤在一起。
- 将首页和全局背景中规律的装饰波形替换为更松散的低频动态场，避免误导为功能性波形。
- 新增麦克风音量监听 `AudioLevelMonitor` 和 `SottoVoiceWaveform`，让编辑页提词预览与正式提词窗口下方声波根据用户音量从中心向两侧扩散；当前只做音量可视化，不做自动语音跟稿。
- 修复麦克风监听首次接入后的崩溃：Crash 报告显示音频 tap 回调在 Core Audio 实时队列触发 Swift `@MainActor` 隔离检查；已移除监视器的 MainActor 隔离，并只在主队列发布 UI 状态。
- 补充 `NSMicrophoneUsageDescription` 到 SwiftPM 打包脚本生成的 `Info.plist`，避免后续麦克风权限说明缺失。
- 优化正式提词窗口：AppKit 面板改为可 resize，SwiftUI 提供隐形四角拖拽命中区；窗口尺寸会同步回 `TeleprompterSettings` 并按安全范围 clamp，避免可见角标造成透明方角错觉。
- 优化正式提词交互：右上角增加轻量 `xmark` 退出按钮；播放后 `REC` 状态点和文字变红；正文区域改为可滚动歌词式列表，点击任一句可直接跳到该句并保持播放状态。
- 根据 Dewens 对正式提词窗口截图的补充反馈，进一步移除默认态退出按钮底色和描边，仅在 hover 时浮出按钮轮廓，减少“贴片 / 插件”感。
- 继续修复正式提词窗口浅色背景下的透明方角痕迹：确认问题来自无边框透明 AppKit 窗口仍使用矩形系统阴影，已关闭 `NSWindow.hasShadow`，改由 SwiftUI 圆角面板绘制自身柔光。
- 针对正式提词窗口仍可见“透明矩形角”的后续反馈，新增 `PromptWindowAppearance` 统一配置提词浮窗外观：AppKit `NSHostingView` 现在按 30px 连续圆角做 layer mask，SwiftUI 提词外壳和玻璃面板也使用同一圆角裁剪，避免只把内部卡片画圆而窗口承载层仍保留矩形边界。
- 根据 Dewens 对真实提词专注度的反馈，进入正式提词后会临时隐藏原来的大编辑窗口，只保留 `Sotto Prompt` 浮窗；关闭提词后恢复编辑窗口，避免录屏时后台界面继续占屏。
- 根据动效文档中的 React Bits `ElasticSlider` 参考，将提词窗口底部速度、字号、透明度和宽度控制从 `- / 数值 / +` 步进器改为紧凑弹性滑杆：hover / 拖动时轨道轻微变厚和微亮，边界有小幅阻尼，宽度拖动时跟手调整窗口。
- 新增 AppModel 测试覆盖点击跳句、播放状态保留、窗口拖拽尺寸同步与 clamp。
- 新增测试覆盖滑杆式字号 / 透明度 / 宽度 setter clamp、速度滑杆档位映射，以及提词窗口打开时只隐藏可见的非提词窗口。
- 验证结果：`swift test` 通过 20 个测试；`./script/build_and_run.sh --verify` 构建并启动成功；本机视觉检查确认首页动态场、后台右侧间距、正式提词窗口连续圆角、主编辑窗口在提词时隐藏、提词底部滑杆、右上角退出、REC 红色和点击跳句可用。
- 根据 Dewens 对“设置齿轮、最近稿件 ellipsis、停顿 / 强调、现场必需项、滑杆冲突”的反馈，将齿轮接入轻量设置浮层，支持位置预设与亮度调节，并在首页、准备中和编辑页保持同一入口。
- 将最近稿件的 ellipsis 从装饰图标改为小菜单，支持打开、放回首页输入区、移除；菜单采用叠堆卡片式浮层和 spring 转场，减少首页重操作感。
- 将“停顿 / 强调”从本地假状态改为写入 `SentenceSegment` 的真实节奏设置：预计耗时、播放推进、当前句强调视觉和最近稿件保存都会同步更新。
- 将正式提词窗口底部滑杆收纳进 `TUNE` 抽屉，默认只显示上一句 / 播放 / 下一句 / 调节 / 位置按钮；抽屉打开后浮在控制栏上方，降低拖动滑杆和拖动提词器窗口之间的冲突。
- 补齐提词现场基础项：设置浮层位置预设、提词窗口位置按钮、Prompt 菜单键盘快捷键、亮度调节、关闭提词时停止麦克风监听。

## 2026-05-06
- 按 AGENTS.md 重新读取 `README.md`、`context.md`、`progress.md`、`decisions.md` 以及 9 份关键动效 / UI / 页面参考文档，确认本轮不重做产品、不改技术栈，只在 SwiftPM + SwiftUI + 少量 AppKit 的 MVP 0.1+ 上补强可维护动效与真实可用性。
- 对照 `docs/sotto-interaction-motion-principles-v1.md` 梳理动效状态：顶部同源 4 束舞台光、点阵呼吸、状态点、准备步骤、切分点反馈和短语扫读已实现；控制栏 hover 浮现、低频公告卡片、短字标信号漂移、阅读边缘保护和 reduce motion 仍需补齐或加强。
- 派出动效 / UI 与架构 / 可维护性两个并行检查智能体；结论是当前 StageLightRays 方向正确但需强化真实分束感，`SottoStyle.swift` 与 `AppModel` 开始成为增长点，但本轮宜做小步边界而非大重构。
- 新增 `Sources/Sotto/Views/SottoMotion.swift`，集中轻量 motion token、短字标 `SottoSignalText`、`SottoConfirmationSpark`、`SottoProgressiveEdgeFade` 和 `SottoSemanticIcon`，作为 Motion System 的第一层边界。
- 调整首页 StageLightRays：保留单一顶部来源，收窄 4 束光、降低中央泛光、增加细光纹理，让视觉更接近“从一个顶部向四周打出三四束会呼吸的舞台顶光”，而不是圆润渐变亮斑或一排独立灯位。
- 为 `ON STAGE` 接入短促确认微光；为 `Sotto`、`SOTTO`、`SOTTO PROMPT` 等短字标接入轻微信号漂移，且在 reduce motion 下自动静态降级。
- 在从准备中进入编辑页后增加低频公告卡片“节奏已整理好”，短暂提示完成但不阻塞继续编辑。
- 在句子列表、切分面板横向短语区、提词预览和正式提词窗口加入轻量阅读边缘保护层，避免滚动边界生硬，同时不遮挡当前句和关键操作。
- 将正式提词窗口控制栏改为默认低亮、鼠标靠近后浮现；根据独立审查反馈，把控制栏拆成两行紧凑布局，避免默认 / 最小宽度下控件溢出或不可点。
- 根据独立审查反馈修复播放节奏：`tickPlayback` 改为使用当前 `session.timing.duration(for:)`，确保现场切换舒缓 / 标准 / 紧凑后实际扫读节奏同步变化。
- 根据独立审查反馈提升正式提词窗口长句可读性：当前句区域扩大到更稳定的 3 行空间，并按句长限制正式提词字号上限，降低长句或大字号下裁切风险。
- 补齐 reduce motion 覆盖：点阵、顶部光、节奏线、状态点、扫光、语义图标和切分点点击反馈均有静态或低动态路径；正式提词扫光在 reduce motion 下退化为当前短语静态微亮。
- 新增 `Tests/SottoTests/AppModelTests.swift`，覆盖播放 tick 使用当前 timing 而不是旧 phrase estimate，以及字号 / 透明度 / 窗口宽度现场控制 clamp。
- 独立中文代码审查发现 3 个必须修复项：速度控制不影响实际播放、长句当前句可能裁切、控制栏在最小宽度下有溢出风险；本轮已全部修复。剩余建议包括进一步做性能 profiling、继续拆薄 PlaybackController / PromptControlsView。
- 验证结果：`swift test` 通过 13 个测试；`./script/build_and_run.sh --verify` 构建并启动成功；本机视觉检查覆盖首页、准备中、编辑页、正式提词窗口，确认顶光同源分束更清楚，编辑页无遮挡，提词窗口正文可读，控制栏两行布局未溢出。

## 2026-05-05
- 根据 Dewens 对稿件编辑页的明确反馈，修正此前“上编辑、下预览”仍会产生上下区域重叠的问题，将编辑页重构为左侧长列独占显示“已识别句子”，右侧上下分区显示“短语切分 / 节奏调整”和“提词预览”。
- 降低编辑页区域边框感：新增并应用编辑页专用暗色面板样式，去掉明显白色描边，改用更深黑色底、低密度点阵和阴影层次做区域切分。
- 压缩右上调整面板高度、字号、间距和内部控件排列，将停顿设置、强调设置、预计耗时并排收纳，确保不需要垂直滚动即可看到全部内容。
- 调整右下提词预览为更大的区域，同时弱化预览内部卡片描边，避免“卡片套卡片”的白边割裂感。
- 根据 Dewens 对全黑区域背景的反馈，将编辑页专用面板底色从接近实心黑调整为约 86% 不透明度的暗暖底色，保留区域层次但避免纯黑块感。
- 根据 Dewens 反馈背景点阵仍不可见，继续将编辑页专用面板底色降至约 72% 不透明度，并提高面板内点阵可见度，让背景颗粒感重新透出。
- 根据 Dewens 对首页视觉一致性的反馈，将首页背景光强下调，并把首页稿件输入区和最近稿件区改为与编辑页一致的暗色半透明分区样式，弱化玻璃白边和高亮阴影。
- 核对 MVP 0.1 设计规格与正式提词窗口参考，确认当前提词窗口已覆盖暂停 / 继续、上一句 / 下一句、速度微调、退出，但缺少字号、透明度和窗口宽度的现场控制；本轮补齐字号、透明度、宽度三组控制。
- 修正编辑页右上角提词入口按钮，将容易误解为复制的 `rectangle.on.rectangle` 图标改为播放型提词入口，并增加“提词”文字标签。
- 将提词窗口播放推进从固定 1.1 秒硬切改为 30fps 播放 tick，按当前短语预计时长累计进度，并用当前短语内的逐字进度更新高亮。
- 为正式提词窗口的上一句、当前句和未来句增加淡入 / 位移过渡，减少句子切换时的闪现感。
- 移除编辑页提词预览中旧的 1.1 秒硬切 timer，避免正式提词窗口打开后被后台预览重复推进导致跳句。
- 验证结果：`swift test` 通过 11 个测试；`./script/build_and_run.sh --verify` 构建并启动成功；通过本机 App 视觉检查确认编辑页已呈现左长列 + 右上紧凑面板 + 右下预览结构，未再出现上下重叠。
- 审阅并确认 `docs/superpowers/specs/2026-05-02-spotlight-flow-teleprompter-mvp-design.md`，新增「2026-05-05 审阅确认与动效补充」章节，把 `docs/sotto-interaction-motion-principles-v1.md` 中的关键动效纳入 MVP 0.1 验收。
- 根据动效文档补齐第一批实现：将首页顶部静态渐变改为暖白慢速呼吸光束，点阵背景改为低透明度呼吸 / 微闪 / 极慢位移，状态点改为微光呼吸，节奏线改为低速波动。
- 为首页 `ON STAGE` 增加 hover 微亮、边缘呼吸和低干扰确认感；为准备中状态增加步骤依次浮现和准备点呼吸，避免普通 loading 感。
- 为编辑页已识别句子增加选中柔光和切换过渡，为切分点增加 hover 微亮与点击柔光确认。
- 将提词窗口当前短语从逐字追赶改为短语级柔光扫读，保留上 / 当前 / 未来句淡入与层级退后。
- 验证结果：`swift test` 通过 11 个测试。
- 根据 Dewens 对首页顶光「太圆润、不像真实打光」的反馈，重新对照动效文档 4.1「首页顶部灯光」，将顶部光效从共用中心点的圆润光雾改为 9 个独立顶灯灯位：每束有不同顶部位置、落点、宽度、长度和呼吸延迟，并增加窄光芯与顶部灯源微光，弱化圆形径向光晕。
- 验证结果：`swift test` 通过 11 个测试；`./script/build_and_run.sh --verify` 构建并启动成功；本机视觉检查确认首页顶部已呈现多束顶光，不再只是单个圆润渐变亮区。
- 根据 Dewens 进一步反馈，将顶光方向从「一排独立灯位」收敛为「一个顶部来源向四周打出 4 束呼吸光」：统一顶部来源，4 束分别打向左、中左、中右、右侧落点，每束保留独立呼吸相位和轻微落点摆动，恢复更明显的呼吸节奏。
- 验证结果：`swift test` 通过 11 个测试；`./script/build_and_run.sh --verify` 构建并启动成功；本机视觉检查确认首页顶光回到单一顶部来源并保留慢速呼吸。

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
