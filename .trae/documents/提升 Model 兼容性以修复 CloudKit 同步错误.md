# 解决 CloudKit 旧数据兼容性导致的同步错误

您的直觉非常敏锐，这确实是“手机端（旧版本/线上版）与 Mac 端（新版本/开发版）数据定义不一致”导致的问题。
CloudKit 中存储的旧数据可能缺少新版本中必须的字段（如 `orderIndex`）。当 Mac 端尝试下载这些旧数据时，SwiftData 发现必填字段为空，直接抛出 `Error 1` 并崩溃。

**关于 UI 的特别说明**：
本次修复**仅涉及底层数据模型（Model）的兼容性增强**，完全**不涉及任何 UI 界面代码**，确保手机端和 Mac 端的视觉样式保持原样。

## 修复方案

1.  **提升 Model 兼容性（纯逻辑修改）**
    *   为 `TodoItem` 的 `isDone` 和 `orderIndex` 添加默认值。
    *   为 `MemoCard` 的 `pinned` 和 `archived` 添加默认值。
    *   **原理**：这样即使 CloudKit 中的旧数据缺少这些字段，SwiftData 也能自动填入默认值（如 `false` 或 `0`），从而避免崩溃。

2.  **强制重置本地环境 (v4)**
    *   将数据库版本号升级到 `v4`，确保使用新的兼容性 Model 启动。

## 执行步骤
1.  修改 `TodoItem.swift` (Model)。
2.  修改 `MemoCard.swift` (Model)。
3.  更新 `To_Do_DuckApp.swift` (App Config)。