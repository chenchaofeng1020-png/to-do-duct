## 背景色调整
- 将 DesignSystem.warmBackground 修改为纯色 #f9f9f1，并确认 MainView 使用该背景。
- 文件： [DesignSystem.swift](file:///Users/mycode/To-Do%20Duck/To-Do%20Duck/Design/DesignSystem.swift), [MainView.swift](file:///Users/mycode/To-Do%20Duck/To-Do%20Duck/MainView.swift)

```swift
// DesignSystem.swift
static let warmBackground = Color(red: 249/255, green: 249/255, blue: 241/255)
```

## “新的一天”按钮改为文字+图标
- 重构 FloatingNewDayButton 的 UI 为文字按钮，左侧显示“新建”相关图标，放置在 HeaderBar 下方。
- 采用 Label("新的一天", systemImage: "calendar.badge.plus")，移除圆形背景与阴影。
- 文件： [MainView.swift](file:///Users/mycode/To-Do%20Duck/To-Do%20Duck/MainView.swift)

```swift
// MainView.swift（组件）
struct FloatingNewDayButton: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Label("新的一天", systemImage: "calendar.badge.plus")
        }
        .foregroundColor(DesignSystem.purple)
        .font(.headline)
    }
}

// MainView.swift（位置）
VStack(spacing: 16) {
    HeaderBar()
    HStack {
        FloatingNewDayButton { withAnimation { createTodayCard() } }
        Spacer()
    }
    ForEach(cards) { card in ... }
}
```

## 日期格式统一为 2020-20-02（yyyy-MM-dd）
- 将每日卡片的日期显示统一为 yyyy-MM-dd 的两位数字格式。
- 文件： [MainView.swift](file:///Users/mycode/To-Do%20Duck/To-Do%20Duck/MainView.swift)

```swift
// DayCardViewNew 标题日期
Text(card.date, format: .dateTime.year().month(.twoDigits).day(.twoDigits))
    .font(.title3.weight(.bold))
```

## 隐藏“继续一天”按钮
- 在 TodoItemRowNew 移除“继续一天”按钮，仅保留勾选、链条标识与标题编辑。
- 文件： [MainView.swift](file:///Users/mycode/To-Do%20Duck/To-Do%20Duck/MainView.swift)

```swift
// TodoItemRowNew 尾部按钮移除
// 原：Button("继续一天", action: onContinue)
// 直接删除该按钮相关代码
```

## 新建待办后保持输入框焦点
- 在 DayCardViewNew 为新增 TextField 添加焦点管理，提交后清空文本并重新聚焦输入框，以便连续输入。
- 文件： [MainView.swift](file:///Users/mycode/To-Do%20Duck/To-Do%20Duck/MainView.swift)

```swift
// DayCardViewNew 中添加
@FocusState private var addingFieldFocused: Bool

TextField("输入待办回车↩︎", text: $addingText)
    .focused($addingFieldFocused)
    .onSubmit {
        let t = addingText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        onAdd(t)
        addingText = ""
        addingFieldFocused = true
        Haptics.light()
    }
```

## 构建与验证
- 编译项目，运行后手动验证：
  - 背景色为 #f9f9f1。
  - “新的一天”为文字按钮，左侧图标，位于标题下。
  - 日期格式均为 yyyy-MM-dd。
  - 不显示“继续一天”按钮。
  - 输入待办后回车，输入框保持焦点可继续输入。
