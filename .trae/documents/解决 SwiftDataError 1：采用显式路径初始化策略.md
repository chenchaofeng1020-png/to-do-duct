## 1. 深度分析与诊断
**现状**：
- APP 构建成功，但在启动时崩溃，报错 `SwiftDataError Code: 1`。
- 只有在开启 CloudKit 同步模式（`.private`）时才会崩溃，关闭同步时（`.none`）能正常运行。
- 所有的 V2 模型引用已清理完毕，项目已完全迁移至 V3。

**根本原因**：
`SwiftDataError Code: 1` 是一个极度宽泛的错误，但在 CloudKit + App Group 的组合场景下，它通常由 **路径解析歧义** 引起。
当您在 `ModelConfiguration` 中同时指定 `name` ("TodoDuckShared_v7") 和 `groupContainer` 时，SwiftData 内部尝试自动拼接路径。但在某些复杂的签名或沙盒环境下（特别是开发环境与 CloudKit 容器交互时），这种自动解析可能会失败，导致底层 CoreData 无法定位或创建数据库文件。

## 2. 解决方案：显式 URL 初始化
为了彻底消除路径歧义，我们将放弃让 SwiftData "猜" 路径，改为 **显式指定数据库文件的完整绝对路径**。

### 核心步骤
1.  **主应用修复** (`To_Do_DuckApp.swift`)：
    - 手动构建 App Group 的完整 URL：`.../group.sdy.tododuck/TodoDuckShared_v7.store`。
    - 使用 `ModelConfiguration(url: ...)` 初始化，明确告诉 SwiftData 文件在哪里，不再依赖 `groupContainer` 参数的隐式推断。

2.  **小组件修复** (`Provider.swift`)：
    - 同步应用相同的显式 URL 初始化逻辑，确保主应用和小组件读写同一个具体的数据库文件。

这种“显式路径”策略是解决 SwiftData App Group 错误的“核武器”，能绕过绝大多数内部路径解析 Bug。

## 3. 验证计划
- 修改后，SwiftData 将直接操作指定路径的文件。
- 如果 CloudKit 依然有问题，错误信息可能会变化（不再是 generic error 1），从而暴露真正的根因。
- 启动后，请观察 CloudKit Dashboard 是否出现 `CD_DailyCardV3` 等新表。
