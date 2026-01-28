# 修复 SwiftData 云同步初始化错误的方案

通过分析错误日志 `SwiftData.SwiftDataError Code: 1` 和项目代码，确定问题主要源于**本地数据库文件与 CloudKit Schema 之间的不一致**，或者**关联关系定义的潜在歧义**。

该错误通常发生在 Model 定义发生变化但本地数据库未正确迁移，或 CloudKit 远端存在不兼容的旧 Schema 时。

## 计划执行步骤

1.  **优化 Model 定义 (`TodoItem.swift`)**
    *   在 `TodoItem` 类的 `card` 属性上显式添加 `@Relationship` 宏。
    *   虽然 SwiftData 可以推断反向关系，但在 CloudKit 同步场景下，显式声明能减少元数据生成的歧义，提高稳定性。

2.  **强制重置数据库容器 (`To_Do_DuckApp.swift`)**
    *   将 `ModelConfiguration` 的存储名称从 `TodoDuckShared` 升级为 `TodoDuckShared_v3`。
    *   将 Sandbox 模式的名称升级为 `TodoDuck_Sandbox_v3`。
    *   **目的**：这将强制 App 创建全新的本地数据库文件，绕过已损坏的旧文件或不匹配的 Schema 缓存，触发全新的 CloudKit 初始化流程。

## 预期结果
*   App 启动时将重新初始化数据库。
*   `SwiftDataError Code: 1` 消失。
*   CloudKit 同步功能恢复正常。
*   **注意**：此操作会重置本地未同步的数据（因为使用了新的数据库文件），但会从 iCloud 拉取已有的云端数据。