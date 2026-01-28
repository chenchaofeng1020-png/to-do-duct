# App Store 上架指南

恭喜你完成了 App 的开发！以下是将 "To-Do Duck" 上架到 App Store 的详细步骤。

## 1. 准备工作

### 1.1 Apple Developer 账号
确保你拥有一个有效的 Apple Developer Program 账号（个人版年费 $99）。
- 登录 [Apple Developer 网站](https://developer.apple.com/)。

### 1.2 证书与标识符
Xcode 通常可以自动管理这些，但了解原理很有帮助：
- **Certificates**: 用于签名的证书（开发证书和发布证书）。
- **Identifiers (App ID)**: 你的 App 的唯一标识符（Bundle ID）。
- **Profiles**: 描述文件，结合了证书、App ID 和设备信息。

## 2. Xcode 项目配置

### 2.1 检查 Bundle Identifier
在 Xcode 中点击项目根节点 -> Targets -> General -> Identity。
确保 `Bundle Identifier` 是唯一的（例如 `com.yourname.tododuck`）。

### 2.2 设置版本号
- **Version**: 市场显示的版本（例如 `1.0.0`）。
- **Build**: 内部构建版本，每次上传必须递增（例如 `1`，下次是 `2`）。

### 2.3 检查 App Icon
我已经检查过你的 `Assets.xcassets`，你使用了 Single Size (1024x1024) 的图标配置，这是符合现代 iOS 标准的。确保 `AppIcon.png` 是一张高质量的 1024x1024 图片。

### 2.4 隐私清单 (Privacy Manifest)
**重要**：由于你的代码使用了 `@AppStorage` (UserDefaults)，根据 Apple 最新政策，必须包含隐私清单文件。
✅ **我已经为你创建了 `PrivacyInfo.xcprivacy` 文件**，并声明了对 UserDefaults 的使用（理由代码 `CA92.1`：用于 App 自身功能）。你不需要额外做什么，只要确保该文件包含在 Target 中即可。

## 3. App Store Connect 设置

1. 登录 [App Store Connect](https://appstoreconnect.apple.com/)。
2. 点击 **My Apps** -> **+** -> **New App**。
3. 填写 App 信息：
   - **Platforms**: iOS
   - **Name**: To-Do Duck (或你想展示的名字)
   - **Primary Language**: Simplified Chinese (简体中文)
   - **Bundle ID**: 选择在 Xcode 中设置的那个
   - **SKU**: 自定义一个唯一字符串（例如 `tododuck_001`）
   - **User Access**: Full Access (除非你有登录系统)

## 4. 准备元数据 (Metadata)

在提交前，你需要准备好以下内容：

- **App 截图**：
  - 需要 iPhone 6.5" (iPhone 11 Pro Max 等) 和 iPhone 5.5" (iPhone 8 Plus) 的截图。
  - 或者直接使用 iPhone 16 Pro Max / 15 Pro Max 的截图（6.9" / 6.7"），Apple 现在允许使用最新设备的截图自适应旧设备。
  - **建议**：使用模拟器运行 App，按下 `Cmd + S` 截图。
- **描述 (Description)**：简要介绍 App 的功能（待办事项、每日卡片、备忘录等）。
- **关键词 (Keywords)**：例如 `待办,清单,效率,日程,todo,task,duck`。
- **支持 URL (Support URL)**：一个简单的网页或微博/Twitter 链接，用户可以在那里联系你。
- **隐私政策 URL (Privacy Policy URL)**：由于你没有收集用户数据（仅本地存储），可以使用免费的隐私政策生成器生成一个链接。

## 5. 打包与上传 (Archive & Upload)

1. **选择设备**：在 Xcode 顶部设备栏选择 **Any iOS Device (arm64)**。
2. **归档**：点击菜单栏 `Product` -> `Archive`。这可能需要几分钟。
3. **Organizer**：归档完成后，Xcode 会自动打开 Organizer 窗口（或通过 `Window` -> `Organizer` 打开）。
4. **验证与分发**：
   - 选中最新的归档，点击 **Distribute App**。
   - 选择 **App Store Connect** -> **Upload**。
   - 保持默认勾选（Upload your app's symbols 等）。
   - 选择 **Automatically manage signing**。
   - 最后点击 **Upload**。

## 6. 提交审核

1. 回到 App Store Connect 网页。
2. 进入你创建的 App 页面。
3. 在 **Build** 部分，点击 `Add Build`（上传成功后可能需要等待 10-20 分钟处理时间才会显示）。
4. 选中你刚刚上传的版本。
5. 填写剩余的 App 信息（版权、评级等）。
   - **App Privacy**: 编辑隐私信息，声明你没有收集数据（"Data Not Collected"），除非你接入了第三方统计 SDK。虽然我们添加了 `PrivacyInfo.xcprivacy` 用于声明 API 使用，但在 App Store 填写隐私标签时，如果数据只存在本地，通常选 "Data Not Collected"。
6. 点击右上角的 **Add for Review**。
7. 最后点击 **Submit to App Review**。

## 7. 等待审核

审核通常需要 24-48 小时。如果被拒（Rejected），不要灰心，查看 Apple 的反馈，修复后重新提交即可。

---

### 祝你好运！🚀
如果上架过程中遇到具体的报错，随时可以把错误信息发给我。
