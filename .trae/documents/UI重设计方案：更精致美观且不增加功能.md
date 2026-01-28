## 设计目标
- 风格参考截图：温暖奶油底色、霓虹青柠点缀、极简圆角与柔和阴影、胶囊标签与大标题。
- 保持现有交互与信息架构，不新增功能，仅优化视觉样式与观感。

## 风格基调
- 背景：延续 #f2f2ebff 奶油底色，整体更干净柔和。
- 主色：霓虹青柠（近似 #F3FF57）和紫色（近似 #7C6BF2）。
- 文字：高对比黑色主文字，低对比次要文字（灰）。
- 形状：更大圆角（卡片 20）、胶囊按钮与标签。
- 阴影：柔和扩散阴影（黑 8% 不透明度，半径 12，y: 8）。
- 字体：系统圆体设计 .rounded，高权重用于标题和金额式日期。

## 设计系统调整（不增功能，仅 tokens）
文件： [DesignSystem.swift](file:///Users/mycode/To-Do%20Duck/To-Do%20Duck/Design/DesignSystem.swift)
- 新增/调整：
  - textPrimary = Color(red: 0.07, green: 0.07, blue: 0.07)
  - textSecondary = Color(red: 0.45, green: 0.45, blue: 0.45)
  - cardBackground = .white
  - cardBorder = Color(red: 0.95, green: 0.95, blue: 0.92)
  - cardCorner = 20（由 18 调整）
  - shadowColor = Color.black.opacity(0.08)
  - shadowRadius = 12（由 10 调整）
  - spacingScale：8, 12, 16, 20（统一页内间距）

## 组件重设计
- HeaderBar（不改内容，仅样式）
  文件： [MainView.swift](file:///Users/mycode/To-Do%20Duck/To-Do%20Duck/MainView.swift)
  - 标题使用 .system(.rounded) + .black 权重，字距略紧缩（tracking），主文字 color 使用 textPrimary。
  - 与按钮的垂直间距统一为 spacingScale 中的 12–16。

- “新的一天”按钮（保持功能不变）
  文件： [MainView.swift](file:///Users/mycode/To-Do%20Duck/To-Do%20Duck/MainView.swift)
  - 采用 Label("新的一天", systemImage: "calendar.badge.plus")。
  - 胶囊样式：背景 neonLime，文字与图标黑色；左右内边距 14–18，高度 36–40，圆角 999。
  - 轻阴影，悬停/按压轻微缩放动画（SwiftUI 默认按压反馈即可）。

- 每日卡片 DayCardViewNew（不改数据结构与交互）
  文件： [MainView.swift](file:///Users/mycode/To-Do%20Duck/To-Do%20Duck/MainView.swift)
  - 容器：cardBackground + 1px cardBorder，corner = 20，阴影为 shadowColor/shadowRadius。
  - 标题日期：采用 .system(.rounded) 的 headline/semibold，主文字 textPrimary，格式保持现状 yyyy-MM-dd（已实现）。
  - 内部间距统一为 spacingScale：外框 16，行距 10。

- 待办行 TodoItemRowNew（功能不变）
  文件： [MainView.swift](file:///Users/mycode/To-Do%20Duck/To-Do%20Duck/MainView.swift)
  - 勾选图标更新为 circle 系列：未完成用 "circle"（次要灰），已完成用 "checkmark.circle.fill"（紫色），尺寸统一。
  - chainIndex 徽标：改为胶囊，背景紫色 16–20% 不透明度，文字紫色，左右内边距 8/垂直 4，圆角 999。
  - 标题 TextField 使用 .rounded 的 regular/medium，主文字 textPrimary。

- 新增待办输入框（保持现有焦点逻辑）
  文件： [MainView.swift](file:///Users/mycode/To-Do%20Duck/To-Do%20Duck/MainView.swift)
  - 视觉：浅色内嵌背景（#FAFAF5），1px 边框 cardBorder，圆角 12，左右内边距 12。
  - 占位符使用次要文字颜色 textSecondary。

## 间距与层级
- 页面左右内边距 16；模块间距 16；标题与按钮间距 12；按钮与列表间距 16。
- 阴影统一，避免多层叠加造成脏灰感。

## 动效与反馈
- 保留现有 Haptics.success/light。
- 按钮按压轻微缩放（SwiftUI Button 默认动画即可），不新增复杂动效。

## 实施步骤（逐文件）
1) DesignSystem.swift：补充色彩与尺寸 tokens，调整 cardCorner/shadowRadius。
2) MainView.swift：
   - HeaderBar 字体与颜色更新；
   - FloatingNewDayButton 胶囊样式；
   - DayCardViewNew 容器边框与阴影、日期字体；
   - TodoItemRowNew 图标与胶囊徽标样式；
   - TextField 外观与占位符颜色。

## 验证清单
- 不新增任何入口或交互，仅视觉变化。
- 页面背景 #f9f9f1；
- 标题与按钮布局不变，样式更精致；
- 卡片与行元素圆角/阴影与颜色符合基调；
- 勾选与徽标样式变化但行为不变；
- 输入框样式优化且焦点逻辑保持现状。

如确认，我将据此实施改动，并在本地完成编译与视觉验证。