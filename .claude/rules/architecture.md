# Sotto 代码架构规则

## 当前项目类型

Sotto 是混合型项目：既有产品 / 设计 / 公开发布文档，也有可运行的 macOS App 代码。代码协作时需要遵循本文；文档、素材和验收记录仍按根目录项目规则分工。

## 分层边界

当前代码采用 SwiftPM + SwiftUI + 少量 AppKit：

- `Sources/SottoCore/`：纯业务和数据逻辑，不依赖 SwiftUI / AppKit。
- `Sources/Sotto/`：App 入口、状态编排、SwiftUI 视图、AppKit 提词窗口和本机能力适配。
- `Tests/SottoTests/`：核心逻辑、AppModel 状态、窗口行为和字体资源测试。

依赖方向保持单向：

```text
Sotto UI / App layer -> SottoCore
Tests -> Sotto + SottoCore
```

`SottoCore` 不应反向依赖 `Sotto`。

## SottoCore 边界

适合放在 `SottoCore`：

- 稿件、句子、短语、时间锚点、设置等模型。
- 切分、编辑、时间估算、文本适配等确定性逻辑。
- 文档存储、API Key 读取、AI 服务协议和具体网络实现。
- 可脱离 UI 运行的规则、转换和校验。

不放在 `SottoCore`：

- SwiftUI 视图状态。
- AppKit 窗口控制。
- NSOpenPanel / NSSavePanel 等界面交互。
- 依赖屏幕、窗口、焦点、动画的行为。

## Sotto App 层边界

`Sources/Sotto/App/AppModel.swift` 负责连接核心逻辑和界面状态，但要避免继续无限膨胀。新增能力时优先判断是否可以沉到 `SottoCore` 的 Service / Model 中；只有涉及 UI 编排、窗口生命周期、权限提示或用户操作流时才留在 AppModel。

`Sources/Sotto/Views/` 中的 View 应主要负责渲染和事件转发。复杂规则不要直接写进 View；可以放到 `SottoCore`，或在 `Sotto` 层拆成小的状态 / 展示辅助类型。

`TeleprompterWindowController` 是 AppKit 窗口边界，负责置顶、透明、屏幕共享隐藏、窗口尺寸和拖拽相关行为。不要把稿件业务规则放进这里。

## 测试要求

新增或修改以下行为时需要补测试：

- 稿件模型 Codable 兼容性。
- 切分、拆句、合句、时间分配和播放推进。
- 文档存储与旧数据兼容。
- 提词窗口尺寸、透明、屏幕共享隐藏等窗口边界。
- 设置项 clamp、快捷键映射和播放状态变化。

UI 视觉微调可不强制新增单元测试，但如果影响布局边界、文本适配或窗口行为，应优先补可自动验证的测试。

## 文档同步

重要能力变化完成后同步：

- `progress.md`：记录做了什么、验证结果和剩余风险。
- `README.md` / `README.en.md`：公开状态、功能列表、路线图或限制有变化时更新。
- `decisions.md`：只有出现新的关键取舍时更新，不把普通实现细节写成决策。
- `resources.md`：新增外部资料、素材、云端入口或参考仓库时更新。
