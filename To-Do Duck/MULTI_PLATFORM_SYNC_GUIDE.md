# 🍎 To-Do Duck 多端同步配置保姆级教程

## 前言：为什么需要这一步？
代码部分我已经帮你写好了，但因为同步功能用的是苹果的 iCloud 服务器，出于安全考虑，苹果要求**必须由账号持有者（也就是你）亲自登录开发者后台开通权限**。这就像去银行开户一样，必须本人签字。

不用担心，只需要在网页上点几下鼠标，不需要写代码。

---

## 第一阶段：在苹果开发者网站开通权限 (最关键的一步)

### 1. 登录
访问 [Apple Developer Account](https://developer.apple.com/account/) 并登录你的开发者账号。

### 2. 创建 iCloud 容器 (数据仓库)
这个“容器”就是云端存放你 App 数据的地方。

1.  进入 **"Certificates, Identifiers & Profiles"** (证书、标识符和描述文件)。
2.  在左侧菜单点击 **"Identifiers"**。
3.  点击右上角的蓝色 **`+`** 号。
4.  在列表中选择 **"iCloud Containers"**，然后点右上角的 **"Continue"**。
5.  填写表单：
    *   **Description (描述)**: 填 `To-Do Duck Sync`。
    *   **Identifier (标识符)**: **必须填** `iCloud.sdy.To-Do-Duck`
        *   ⚠️ **注意**：这个 ID 必须与 Xcode 中的 entitlements 文件一致。
6.  点击 **"Continue"**，确认信息无误后点击 **"Register"**。

### 3. 给 App 授权 (告诉苹果这个 App 可以用那个仓库)
现在仓库建好了，要告诉苹果：To-Do Duck 这个 App 有权使用这个仓库。

1.  回到 **"Identifiers"** 列表页面。
2.  在右上角下拉菜单（如果是 App IDs）或者列表中，找到你的 App ID。
    *   通常名字是 `To-Do Duck`，Identifier 是 `sdy.To-Do-Duck`。
3.  点击它进入编辑页面。
4.  向下滚动，找到 **"iCloud"** 这一行。
    *   如果没有勾选，请**打钩**。
    *   如果已经勾选，或者刚打上钩，点击这一行右侧的 **"Edit"** 按钮。
5.  在弹出的窗口中：
    *   选择 **"CloudKit"** (不要选 iCloud Documents)。
    *   在下方的 **"Containers"** 列表中，找到刚才创建的 `iCloud.sdy.To-Do-Duck`。
    *   **打钩**选中它。
6.  点击弹窗的 **"Save"**。
7.  **重要**：回到主编辑页面后，一定要点击右上角的 **"Save"** 按钮保存更改。

---

## 第二阶段：Xcode 本地确认 (检查一下)

虽然我已经帮你改了配置，但建议你快速检查一下确保万无一失。

1.  在 Xcode 左侧文件列表中，点击最顶部的蓝色图标 **`To-Do Duck`**。
2.  在右侧主界面，选择 **`TARGETS`** 下的 **`To-Do Duck`** (主 App)。
3.  点击顶部的 **`Signing & Capabilities`** 选项卡。
4.  看是否有 **`iCloud`** 这一栏：
    *   **CloudKit** 应该是被勾选的。
    *   **Containers** 列表里应该有 `iCloud.sdy.To-Do-Duck` 并且是**打钩**状态。
        *   *如果显示红色字体或感叹号，点击一下那个刷新/修复按钮即可。*
5.  看是否有 **`Background Modes`** 这一栏：
    *   **Remote notifications** 应该是被勾选的。

---

## 第三阶段：真机测试 (见证奇迹)

**⚠️ 请注意：iCloud 同步在 iOS 模拟器上经常不稳定，强烈建议用真机测试。**

1.  **准备两台设备**：
    *   比如：你的 iPhone 和你的 Mac。
    *   或者：两台 iPhone / iPad。
2.  **检查账号**：
    *   确保两台设备登录的是**同一个 Apple ID**。
    *   进入系统设置 -> 点击你的头像 -> iCloud -> **iCloud Drive** (iCloud 云盘)，确保是**开启**状态。
    *   在 iCloud Drive 的“同步此 iPhone/Mac 的 App”列表中，找到 `To-Do Duck` (如果以后上架了会有开关，开发阶段默认是开的)。
3.  **运行 App**：
    *   在 Mac 上点击 Xcode 的运行按钮 (选 My Mac)。
    *   连上 iPhone，选 iPhone 为目标运行。
4.  **测试**：
    *   在 iPhone 上新建一个任务 "手机端测试"。
    *   放下手机，看 Mac 屏幕。
    *   通常在 5-15 秒内，Mac 端会自动出现这个任务。

---

## 常见问题 (FAQ)

**Q: 为什么我添加了任务，另一端没反应？**
A:
1.  **时间问题**：CloudKit 有时不是秒传，稍微等个半分钟。
2.  **网络问题**：确保两台设备都有网。
3.  **账号问题**：必须是同个 Apple ID。
4.  **开发者后台没配置好**：请回头仔细检查第一阶段的 ID 是否填错。

**Q: 控制台打印 "CoreData: error: CoreData+CloudKit..." 红色报错？**
A: 这是开发版的常见日志，只要 App 能跑且能同步，通常可以忽略。如果同步失败，请检查上面提到的 ID 是否一致。
