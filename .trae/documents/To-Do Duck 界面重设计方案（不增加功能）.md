## 设计目标
- 提升整体“完成度”和精致度，不增加功能，仅优化视觉与交互细节。
- 保持轻量、温和、克制的风格，强调层次、留白与触感反馈。
- 优先保证可读性、易用性与一致性，减少视觉噪点。

## 视觉基调与配色
- 背景：推荐延续奶油浅灰米色 #f2f2eb（或系统浅灰），避免纯白刺眼。
- 卡片：纯白 #FFFFFF，形成清晰的层级对比。
- 文本：
  - 主文本：#1C1C1C（代码中已有 textPrimary）
  - 次文本：#6B6B6B（textSecondary）
  - 辅助文本：#AFAFAF（textTertiary）
- 强调色：保持现有清新绿色（checkedColor）做完成态与微强调；辅助保留紫色（purple）用于延续次数徽标。
- 分割线与边框：黑色 0.5px，透明度 0.04–0.06，尽量轻。

## 字体与排版
- 字体：系统 SF / SF Rounded（代码已使用），对标题使用 Rounded 增加亲和感。
- 层级：
  - App 标题：32 Heavy Rounded
  - 日期栏：15 Medium Rounded
  - 待办标题：16 Medium（完成态降为 Regular 并加删除线）
- 行距：行内容 14–16 的垂直间距，卡片内块与块之间 12–16。

## 间距与圆角
- 全局间距刻度：4 / 8 / 12 / 16 / 20 / 24。
- 卡片圆角：20–24（沿用现有 24）。
- 徽标与胶囊角：12。

## 阴影与层次
- 卡片阴影：黑色 0.06，半径 12–16，y 偏移 6–8，控制场景光感且不漂浮。
- 标题栏浅背景：整行轻微灰底提升模块感，避免分隔线堆叠。

## 组件重设计
- HeaderBar（[MainView.swift](file:///Users/mycode/To-Do%20Duck/To-Do%20Duck/MainView.swift)）
  - 保留大标题“To-Do Duck”。
  - 下方日期采用“yyyy-MM-dd 星期X”，颜色使用次文本色。
  - 标题与内容区间距加大，增强层级。
- DayCard（[MainView.swift](file:///Users/mycode/To-Do%20Duck/To-Do%20Duck/MainView.swift)）
  - 顶部日期行整行浅灰背景（不使用边线），水平 20、垂直 14–16。
  - 卡片主体白底、轻边框 0.5px（透明度 0.03–0.04），配合轻阴影。
  - 列表项分隔线统一为 0.5px + 0.04–0.05 透明度，左缩进与文字对齐。
- TodoItemRow（[MainView.swift](file:///Users/mycode/To-Do%20Duck/To-Do%20Duck/MainView.swift)）
  - 方形复选框：22px、圆角 6、选中填充强调绿 + 白色对勾，未选为描边灰。
  - 标题多行输入，完成态 Regular + 删除线 + 次文本色。
  - 延续次数徽标沿用紫色系，减轻饱和度，保持信息层级。
- FloatingNewDayButton（[MainView.swift](file:///Users/mycode/To-Do%20Duck/To-Do%20Duck/MainView.swift)）
  - 胶囊按钮维持高可见性，可将纯黑改为更柔和的深灰或纯黑但降低阴影饱和度。

## 交互与细节
- 键盘：点击空白收起 + ScrollView 交互式收起（已实现）。
- 触感反馈：完成打勾触感成功、添加轻触感（已实现）。
- 动效：复选框切换使用轻微弹性（代码已加 spring），避免过度动画。
- 滑动删除：保持系统风格，减少自定义颜色冲突。

## 无障碍与对比度
- 颜色对比度遵循 WCAG AA：主文本与背景对比度 ≥ 4.5:1。
- 文本大小与行距可读性优先，动态字体兼容。

## 主题与可扩展
- 主题变量集中在 [DesignSystem.swift](file:///Users/mycode/To-Do%20Duck/To-Do%20Duck/Design/DesignSystem.swift)：
  - 背景、文本、强调色、阴影、圆角、分隔线透明度等。
  - 预留两套背景方案：奶油浅灰米色 #f2f2eb 与系统浅灰，便于切换。

## 实施方案（不增加功能）
1. 设计令牌统一（DesignSystem）：
   - 新增/校准颜色常量：creamBackground（#f2f2eb）、separatorOpacity、borderOpacity、accent 等。
   - 确认圆角、阴影、间距刻度常量。
2. 页面结构微调（MainView.swift）：
   - HeaderBar 日期格式与间距调整。
   - ScrollView 背景与点击收起键盘区域统一。
3. 卡片样式（MainView.swift）：
   - 日期行整行浅灰背景；卡片白底 + 轻边框 + 轻阴影。
   - 列表分隔线统一为 Rectangle 0.5px + 透明度。
4. 行项目样式（TodoItemRowNew）：
   - 复选框描边/填充与对勾尺寸统一；文字权重与颜色按完成态区分。
5. 统一测试：
   - 运行模拟器检查不同内容长度、长文本换行、分隔线与阴影表现。

## 交付内容
- 更新的设计令牌与颜色方案。
- 调整后的 HeaderBar、DayCard、TodoItemRow、按钮样式。
- 代码修改集中在：
  - [DesignSystem.swift](file:///Users/mycode/To-Do%20Duck/To-Do%20Duck/Design/DesignSystem.swift)
  - [MainView.swift](file:///Users/mycode/To-Do%20Duck/To-Do%20Duck/MainView.swift)

## 确认
- 请选择背景基调：
  - A：奶油浅灰米色 #f2f2eb（更温和、有设计感）
  - B：系统浅灰（更中性、通用）
- 确认后我将按此方案落地实现并编译验证。