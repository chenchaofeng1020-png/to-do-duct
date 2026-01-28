# 解决 CloudKit 初始化错误 (SwiftDataError 1)

**问题分析：**
错误 `SwiftData.SwiftDataError 错误1` 表示 SwiftData 无法加载数据容器。结合您的情况，这是因为 **App 尝试以 CloudKit 模式打开一个“脏”的本地数据库时失败了**。
虽然您之前点击过重置，但可能因为文件锁或重启不彻底，旧的数据库文件并没有被彻底清除。当 App 再次启动时，它又尝试去读取那个旧的、不兼容 CloudKit 的文件，导致再次失败并回退到本地模式。

**解决方案：**
我们需要彻底清理所有相关的数据库文件，确保 SwiftData 能在一个全新的、干净的环境下初始化 CloudKit 容器。

## 计划执行步骤：

1.  **增强重置逻辑 (`MacProfileView.swift`)**
    *   修改 `resetLocalData()` 方法，确保它不仅删除 `.sqlite` 主文件，还强制删除 `.sqlite-shm` 和 `.sqlite-wal` 临时文件。
    *   增加错误捕获和日志打印，确保文件删除操作真正执行成功。

2.  **验证 Entitlements 配置 (`To-Do Duck.entitlements`)**
    *   再次确认 iCloud 容器 ID (`iCloud.sdy.To-Do-Duck`) 和 App Group ID (`group.sdy.tododuck`) 配置无误。（已确认为正确，但需确保 Xcode 签名能力中已勾选）。

3.  **用户操作指引**
    *   更新代码后，您需要再次点击那个“重置”按钮。
    *   **关键点**：这次重置将更加彻底。重置后 App 会退出或提示重启，请务必**等待几秒钟**再重新打开 App，给系统一点时间释放文件句柄。

4.  **构建与测试**
    *   应用更改。
    *   您需要重新运行 App。
    *   验证“Advanced Debug Info”中的状态是否变为正常。

这个方案的核心是**“彻底的全新开始”**，这是解决 SwiftData 本地/云端模式切换冲突最有效的方法。