# 修复构建错误：'main' attribute conflict

截图显示错误为：`'main' attribute can only apply to one type in a module`。
这意味着在同一个 Target 中，出现了两个 `@main` 入口点。

**原因分析**：
这通常是因为我在创建 Widget 文件时，没有正确区分 Target Membership，或者 Xcode 默认生成的文件与我创建的文件发生了冲突。

1.  **To_Do_DuckApp**：这是主 App 的入口，使用了 `@main`。
2.  **TodoWidget**：这是小组件的入口，也使用了 `@main`。

如果这两个文件被错误地包含在了同一个 Target 中（比如主 App Target 包含了 Widget 代码，或者 Widget Target 包含了主 App 代码），就会报这个错。

## 修复计划 (代码调整)

我将执行以下操作来修复这个问题：

1.  **检查并修正 `TodoWidget.swift` 的 Target Membership**：
    *   我会尝试读取项目结构，确认文件位置。
    *   **关键点**：由于我无法直接操作 Xcode 的 Target 勾选，我需要确认我创建的文件路径是否正确，并指导你进行检查。

2.  **检查是否有多余的入口文件**：
    *   当你创建 Widget Extension 时，Xcode 可能已经自动生成了一个 `TodoWidgetBundle.swift` 或 `TodoWidget.swift`。
    *   而我又为你创建了一个 `TodoWidget/TodoWidget.swift`。
    *   **这导致了冲突！** 两个文件都想当老大 (@main)。

## 执行步骤

1.  **删除我创建的 `TodoWidget.swift` 中的 `@main`**：
    *   如果 Xcode 自动生成了入口文件（通常是 `TodoWidgetBundle`），我们应该使用它，而不是自己再定义一个。
    *   或者，如果我想用我的 `TodoWidget.swift` 作为入口，你需要删除 Xcode 自动生成的那个文件。

**最稳妥的方案**：
我会将 `TodoWidget.swift` 改写为不包含 `@main` 的结构，或者指导你删除 Xcode 自动生成的冲突文件。

鉴于我无法看到你 Xcode 里的文件列表，**我猜测 Xcode 自动生成了一个 `TodoWidgetBundle.swift`**。

**请确认：你的 `TodoWidget` 文件夹下，是不是有一个叫 `TodoWidgetBundle.swift` 的文件？**
如果有，请告诉我。如果没有，我会尝试另一种修复方式。
