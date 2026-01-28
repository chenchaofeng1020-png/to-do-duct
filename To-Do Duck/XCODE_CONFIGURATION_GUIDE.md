# Xcode 详细配置指南 (桌面小组件篇)

这篇文档将手把手教你如何在 Xcode 中完成桌面小组件的所有配置。即便你是第一次操作，只要跟着步骤走，一定能成功！

---

## 第一部分：配置 App Groups (数据共享)

为了让**主 App** (手机里打开的那个) 和 **小组件** (桌面上显示的那个) 能读取同一份数据，我们需要开启 "App Groups" 功能。

### 步骤 1：为主 App 开启 App Groups
1.  在 Xcode 左侧的**文件导航栏 (Project Navigator)**（最左边那个文件夹图标），点击最顶部的蓝色图标 **To-Do Duck**。
2.  现在看中间的编辑区域，你应该能看到 **TARGETS** 列表。
3.  点击列表中的第一个：**To-Do Duck** (图标是个小应用)。
4.  点击顶部的 **Signing & Capabilities** (签名与能力) 选项卡。
5.  在 "App Groups" 区域（如果没找到，看下一步）：
    *   *如果你还没添加过*：点击左上角的 **+ Capability** 小按钮，搜索 "App Groups"，双击添加。
6.  在 App Groups 列表中，你应该能看到 `group.com.6757746591.tododuck`。
7.  **关键操作**：确保这个 ID 前面的复选框是 **✅ 勾选状态**。
    *   *如果显示红色报错*：这是网络问题，稍后会教你修复。只要勾选上了就行。

### 步骤 2：为小组件开启 App Groups
1.  回到 **TARGETS** 列表，这次点击下面的 **TodoWidgetExtension** (图标像个乐高积木)。
2.  同样点击顶部的 **Signing & Capabilities**。
3.  同样确保这里也有 "App Groups" 区域。如果没有，点击 **+ Capability** 添加。
4.  **关键操作**：这里也会显示 `group.com.6757746591.tododuck`。**必须勾选同一个 ID！**
    *   *注意*：主 App 和小组件必须勾选一模一样的 ID，哪怕差一个字母都不行。

---

## 第二部分：共享代码文件 (Target Membership)

为了让小组件能用我们在主 App 里写的代码（比如数据模型、颜色定义），我们需要告诉 Xcode：“这几个文件，小组件也要用！”

### 需要共享的文件列表：
*   `Models/DailyCard.swift`
*   `Models/TodoItem.swift`
*   `Models/MemoCard.swift` (如果有引用)
*   `Design/DesignSystem.swift`

### 操作步骤：
1.  在左侧**文件导航栏**中，找到 `Models` 文件夹。
2.  单击选中 `DailyCard.swift` 文件。
3.  看 Xcode **最右侧的属性面板 (Inspectors)**（如果没有显示，点击 Xcode 右上角那个像“设置/滑块”的图标）。
4.  找到 **Target Membership** 区域。
5.  你会看到两个选项：
    *   `To-Do Duck` (主 App)
    *   `TodoWidgetExtension` (小组件)
6.  **关键操作**：**确保这两个选项都被勾选！** (✅ To-Do Duck, ✅ TodoWidgetExtension)。
7.  **重复上述操作**：对 `TodoItem.swift` 和 `DesignSystem.swift` 也做同样的操作。

---

## 第三部分：解决“红色报错” (Signing Error)

如果你在配置 App Groups 时看到红色的 "The request timed out" 或 "Provisioning profile..." 错误：

1.  **这是什么原因？**
    *   这是因为 Xcode 需要连接 Apple 的服务器来登记你刚刚勾选的 App Group ID，但你的网络连接 Apple 服务器超时了。

2.  **如何解决？**
    *   **方法 A (推荐)**：保持那个页面不动，去喝杯水。Xcode 会在后台自动重试。
    *   **方法 B (手动刷新)**：
        1.  在 **Signing & Capabilities** 页面。
        2.  取消勾选 **Automatically manage signing**。
        3.  等待 2 秒。
        4.  重新勾选 **Automatically manage signing**。
        5.  点击出现的 **Try Again** 按钮。
    *   **方法 C (重启)**：完全退出 Xcode，重新打开项目。

---

## 第四部分：运行测试

配置完成后，我们来验证一下：

1.  在 Xcode 左上角，点击现在的 Target（可能是 `To-Do Duck`），在下拉菜单中选择 **TodoWidgetExtension**。
2.  选择模拟器：比如 **iPhone 16 Pro**。
3.  点击 ▶️ **运行按钮** (或按 `Cmd + R`)。
4.  如果一切正常，模拟器会启动，并且桌面上应该会出现你的小组件！
