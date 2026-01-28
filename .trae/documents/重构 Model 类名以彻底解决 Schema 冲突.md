# 重构 Model 类名以彻底解决 Schema 冲突

既然您愿意“放弃旧数据”并希望“做成一样的数据库”，最彻底的解决方案是**重命名核心数据模型类**。
这将强制 CloudKit 在远端创建全新的 Record Types（表），完全避开旧的 Schema 冲突，就像是重新发布了一个新 App 一样。

## 计划执行步骤

1.  **重构 Model 类名**
    *   `DailyCard` -> `DailyCardV2`
    *   `TodoItem` -> `TodoItemV2`
    *   `MemoCard` -> `MemoCardV2`
    *   **原理**：SwiftData 默认使用类名作为 CloudKit 的 Record Type。修改类名等于创建新表。

2.  **全局替换代码引用**
    *   使用 `grep` 搜索到的所有文件中的引用都将被更新。
    *   包括 View、Widget Provider、Services 等。

3.  **更新 App Schema 配置**
    *   更新 `To_Do_DuckApp.swift` 中的 `Schema` 定义。
    *   更新 `ModelConfiguration` 名称到 `_v5`（为了本地也是全新的）。

## 预期结果
*   **旧数据丢失**：CloudKit 中的旧数据将被遗留在旧表中（`TodoItem`），新 App 将只读取新表（`TodoItemV2`），这符合您“不用管旧数据”的预期。
*   **同步恢复**：由于是全新的表，不存在 Schema 历史包袱，同步应该立即正常工作。
*   **两端一致**：只要手机端后续也更新到此版本，两端将共享这个全新的数据库结构。

**请确认**：这涉及大量代码的搜索替换，虽然我已经仔细检查了引用，但仍属于“大手术”。鉴于您“修了几百遍都不行”的现状，这是最合理的终极手段。