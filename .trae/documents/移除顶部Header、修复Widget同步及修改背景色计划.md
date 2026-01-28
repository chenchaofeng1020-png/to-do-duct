收到，我明白了。您希望保留页面内容区域的大标题（HeaderBar），只移除系统顶部导航栏上的“汉堡菜单”按钮和居中的“To-Do Duck”文字。

以下是修正后的实施计划：

### 1. 移除顶部导航栏元素
*   **修改文件**: `To-Do Duck/MainView.swift`
*   **操作**: 
    *   移除 `.toolbar` 代码块，去掉左上角的汉堡菜单按钮（三条横线图标）。
    *   将 `.navigationTitle("To-Do Duck")` 修改为 `.toolbar(.hidden)` 或隐藏导航栏，从而移除顶部的居中标题和整个导航条背景，让页面内容更沉浸。

### 2. 修复小组件同步问题
*   **修改文件**: `To-Do Duck/MainView.swift`
*   **操作**: 
    *   在删除卡片（Delete Card）的操作中，添加 `try? modelContext.save()` 和 `WidgetCenter.shared.reloadAllTimelines()`，确保删除操作能实时同步到小组件。

### 3. 修改小组件背景色
*   **修改文件**: `TodoWidget/TodoWidget.swift`
*   **操作**: 
    *   将 `.containerBackground(.background, for: .widget)` 修改为 `.containerBackground(DesignSystem.warmBackground, for: .widget)`。
    *   这将使小组件的背景色变为统一的米色，与 App 内部风格保持一致。

确认后，我将立即执行这些修改。