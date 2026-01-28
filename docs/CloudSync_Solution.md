# To-Do Duck 数据云同步解决方案

## 1. 问题背景
当前 App 使用本地存储（Local Storage），且数据库文件位于 App Group 容器中。这种方式在用户删除 App 后，本地文件会被系统清除，导致数据丢失。

## 2. 解决方案概述
利用 **SwiftData + CloudKit** 实现原生的 iCloud 云同步。
*   **优势**：无需搭建自有服务器，用户使用自己的 iCloud 账号同步，隐私性好，且对开发者免费（在一定限额内）。
*   **效果**：数据自动备份到 iCloud。重装 App 后，登录相同 Apple ID 即可自动拉取历史数据。

## 3. 实施步骤

### 第一步：配置 iCloud 能力 (Capabilities)
1.  在 Xcode 中选择项目工程文件（Project）。
2.  选择 `To-Do Duck` (Main App) Target。
3.  进入 **Signing & Capabilities** 选项卡。
4.  点击 **+ Capability**，搜索并添加 **iCloud**。
5.  在 iCloud 配置中：
    *   勾选 **CloudKit**。
    *   在 Containers 列表中，点击 `+` 添加一个新的容器，通常命名为 `iCloud.com.yourname.tododuck`（或者使用默认生成的）。

### 第二步：开启后台同步 (Background Modes)
1.  在 **Signing & Capabilities** 中。
2.  点击 **+ Capability**，添加 **Background Modes**。
3.  勾选 **Remote notifications**。
    *   *原因：CloudKit 使用静默推送通知设备有数据更新，以便及时同步。*

### 第三步：修改代码配置
修改 `To_Do_DuckApp.swift` 中的 `ModelContainer` 配置，启用 CloudKit。

**修改前：**
```swift
modelConfiguration = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)
```

**修改后：**
```swift
// 将 cloudKitDatabase 设置为 .automatic
modelConfiguration = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .automatic)
```

### 第四步：检查数据模型兼容性
CloudKit 对 SwiftData 模型有一定限制，请检查 `Models` 文件夹下的所有类（`DailyCard`, `TodoItem`, `MemoCard`）：
1.  **属性默认值**：确保所有非 Optional 的属性都有默认值，或者在 `init` 中初始化（CloudKit 实际上要求字段可空或有默认行为，SwiftData 会自动处理大部分情况，但建议尽量使用 Optional 或提供默认值）。
2.  **唯一性约束**：如果使用了 `@Attribute(.unique)`，需确保逻辑在多设备冲突时能正确处理（通常 SwiftData 会处理）。
3.  **关系 (Relationships)**：所有关系属性（`@Relationship`）必须是 Optional 的（例如 `var items: [TodoItem]?` 或在数组情况下为空数组），防止死循环引用。

## 4. 关于 App Group 与 Widget
由于我们使用了 App Group (`group.sdy.tododuck`) 来让 Widget 读取数据：
*   只要主 App 成功将数据同步到 App Group 下的数据库文件，并且该文件被 CloudKit 托管，数据就能同步。
*   **注意**：Widget 自身**不要**开启 CloudKit 写入权限，建议仅主 App 负责同步写入，Widget 保持只读或通过主 App 刷新。
*   当前代码中使用了自定义 URL (`containerURL.appendingPathComponent("To-Do-Duck.sqlite")`)。SwiftData 允许在自定义 URL 上启用 CloudKit，但必须确保该 URL 所在目录是 CloudKit 允许访问的（App Group 容器是支持的）。

## 5. 验证测试
1.  在模拟器或真机 A 上运行 App，添加几条数据。
2.  删除 App（模拟数据丢失）。
3.  重新安装 App。
4.  等待片刻（网络同步），数据应自动出现。
5.  *进阶测试*：在真机 A 和真机 B 上同时登录同一 iCloud 账号，在一端修改，另一端应在几秒到几分钟内同步更新。

## 6. 潜在风险与回滚
*   **Schema 不匹配**：如果现有数据模型与 CloudKit 要求严重冲突，可能导致同步失败。建议先在开发环境（Development Container）测试。
*   **迁移**：对于已有的本地数据，开启 CloudKit 后，SwiftData 通常会自动尝试将本地数据上传到 iCloud。

---
**建议**：先在一个单独的分支上实施此变更，验证无误后再合并。
