# Mac 端开发执行计划

您已经成功在 Xcode 中添加了 Mac Destination，现在我们可以开始进行代码层面的适配和开发。

## 任务目标
创建一个原生、美观且数据同步的 Mac 端应用，复用现有的 iOS 逻辑。

## 详细步骤

### 1. 解决跨平台兼容性问题 (代码清理)
由于 iOS 和 Mac 的底层框架不同（UIKit vs AppKit），我们需要对现有代码进行隔离。
*   **修改 `DesignSystem.swift`**：`Haptics` (震动反馈) 依赖 UIKit，需要用 `#if os(iOS)` 包裹，防止 Mac 版编译报错。
*   **修改 `MainView.swift`**：隐藏键盘的逻辑 `UIApplication.shared...` 是 iOS 独有的，需要在 Mac 上禁用。

### 2. 创建 Mac 专属主页 (`MacContentView.swift`)
Mac 应用需要更宽阔的布局，而不是简单的手机界面放大。
*   **布局结构**：使用 `NavigationSplitView` 实现经典的三栏式布局。
    *   **侧边栏 (Sidebar)**：导航菜单（待办事项、备忘录、设置）。
    *   **内容区 (Content)**：显示当前选中的功能模块（复用现有的 `TodoHomeView` 和 `MemoView`）。
*   **交互优化**：在 Mac 上隐藏不需要的手机端元素（如底部的 TabBar）。

### 3. 配置 App 入口 (`To_Do_DuckApp.swift`)
让 App 能够智能识别运行平台。
*   使用 `#if os(macOS)` 判断。
*   如果是 Mac，加载 `MacContentView`。
*   如果是 iOS，加载 `MainView`。

### 4. 运行与验证
*   选择 "My Mac" 作为运行设备。
*   启动 App，检查数据是否从 iCloud 同步过来（可能需要稍等片刻）。
*   验证界面布局和交互是否正常。

我将按照这个顺序依次修改代码。
