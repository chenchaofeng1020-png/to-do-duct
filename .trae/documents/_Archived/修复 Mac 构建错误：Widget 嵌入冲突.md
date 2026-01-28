# 修复 Mac 构建错误：Widget 嵌入冲突

**报错分析**：
`Your target is built for macOS but contains embedded content built for the iOS platform (TodoWidgetExtension.appex)`。
这个错误的意思是：你的 Mac App 试图嵌入一个只为 iOS 编译的 Widget Extension。因为我们之前创建 Widget 时，它是针对 iOS 的，没有勾选 Mac 支持。

## 修复方案

我们需要让 `TodoWidgetExtension` 也支持 Mac 平台。

## 执行步骤

1.  **修改 Widget Target 的支持平台**：
    *   这是一个需要在 Xcode 界面上进行的操作。
    *   请在 Xcode 左侧选择项目根目录 -> 选择 `TodoWidgetExtension` Target -> General -> Supported Destinations。
    *   点击 `+` 号，添加 **macOS**。
    *   *(确保选择 "Mac" 或 "Mac Catalyst"，通常选择与主 App 一致的)*。

2.  **验证 Widget 代码兼容性**：
    *   虽然我们刚才修复了主 App 的代码，但 Widget Extension 里的代码也可能包含 UIKit (如 `UIColor`, `UIImage`)。
    *   我们需要检查 `TodoWidget` 目录下的文件，同样用 `#if os(iOS)` 进行隔离或适配。
    *   重点检查：`WidgetView.swift` (如果有用到 UIKit 的话)。

**由于我无法操作 Xcode 界面，请你按照以下步骤手动操作：**

1.  点击 Xcode 左侧最顶部的蓝色项目图标 `To-Do Duck`。
2.  在中间的 TARGETS 列表中，选中 **`TodoWidgetExtension`** (注意选下面的那个，不是主 App)。
3.  点击顶部的 **General** 标签。
4.  在 **Supported Destinations** 里，点击 **+** 号。
5.  选择 **macOS** 并点击 Add。
    *   *如果弹出提示询问是否启用 Mac 支持，点击 Enable。*
    *   *如果让你选 "Designed for iPad" 还是 "Native Mac"，请尽量选择与主 App 一致的（如果是 Native Mac 就选 Mac，如果是 Catalyst 就选 Mac Catalyst）。通常选 **Mac** 即可。*

**操作完成后，请告诉我“已添加”，我会继续检查 Widget 代码的兼容性。**
