# 修复 Control Widget 版本兼容性问题

## 问题分析
构建失败的原因是 `TodoWidgetControl.swift` 中使用了 iOS 18.0 / macOS 15.0 (Sequoia) 引入的新特性（Control Widget），但项目的 Deployment Target 已被设置为 iOS 17.6 / macOS 14.6。这导致编译器在处理这些新 API 时报错。

## 解决方案
由于目前主应用并不依赖这些 Control Widget 功能（在 `TodoWidgetBundle` 中未被引用），我们可以通过添加版本可用性检查 (`@available`) 来解决编译错误。这将告诉编译器仅在支持的系统版本上编译这些代码。

## 实施计划
1.  **修改 `TodoWidget/TodoWidgetControl.swift`**
    *   为 `TodoWidgetControl` 结构体添加 `@available(iOS 18.0, macOS 15.0, *)` 属性。
    *   为 `TodoWidgetControl` 的扩展（包含 `Provider`）添加相同的可用性属性。
    *   为 `StartTimerIntent` 结构体添加相同的可用性属性。

这样既能保留代码供未来使用，又能立即解决当前的构建错误。

## 代码变更预览
```swift
// TodoWidgetControl.swift

@available(iOS 18.0, macOS 15.0, *)
struct TodoWidgetControl: ControlWidget { ... }

@available(iOS 18.0, macOS 15.0, *)
extension TodoWidgetControl { ... }

@available(iOS 18.0, macOS 15.0, *)
struct StartTimerIntent: SetValueIntent { ... }
```