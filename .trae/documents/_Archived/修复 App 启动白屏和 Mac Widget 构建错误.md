根据项目文档，需要解决以下问题：

1. **修复 App 启动白屏问题**：
   - 增强 TodoHomeView 的 UI 容错性，确保数据为空时显示空状态页面
   - 在 To_Do_DuckApp.swift 中添加数据库路径打印和清理逻辑
   - 检查 MainView.swift 中 ConfettiView 的背景色配置

2. **修复 Mac 构建错误：Widget 嵌入冲突**：
   - 检查 TodoWidget 目录下的代码兼容性
   - 用 #if os(iOS) 隔离或适配 UIKit 代码
   - 重点检查 WidgetView.swift

立即执行这些修复。