# 修复 Widget 嵌入签名问题

## 问题分析
Widget 无法加载 (Error 5) 的主要原因是 `project.pbxproj` 中 `TodoWidgetExtension.appex` 在嵌入主应用时缺少了 **`CodeSignOnCopy`** 属性。这导致系统在加载 Widget 时无法验证其代码签名，从而拒绝加载。

## 解决方案
我们需要修改 `project.pbxproj` 文件，为 Widget 扩展的嵌入操作添加签名属性。

## 实施步骤
1.  **编辑 `To-Do Duck.xcodeproj/project.pbxproj`**
    *   查找 `BA5C46F62F1BF3F600414201` (TodoWidgetExtension.appex 的构建文件引用)。
    *   将 `settings = {ATTRIBUTES = (RemoveHeadersOnCopy, ); };` 修改为 `settings = {ATTRIBUTES = (RemoveHeadersOnCopy, CodeSignOnCopy, ); };`。

此修复将确保 Widget 在被复制到主 App 包中时会被正确签名，从而解决加载错误。

## 后续验证
修复后，我们将需要重新构建并运行项目，以验证 Widget 是否能正常显示（此时应显示我们之前硬编码的“测试任务”数据）。
