# 待办任务重复功能需求文档

## 1. 功能概述
用户希望能够为特定的待办任务设置“重复规则”，以便在未来的日期自动创建相同的任务。

核心场景：用户完成了一个任务，或者决定这个任务需要持续做一段时间，于是设置“重复到下周五”。之后，每当用户在未来（直到下周五）点击“新的一天”生成当日卡片时，系统会自动把这个任务加入到当日的待办列表中。

## 2. 用户流程 (User Flow)

### 2.1 设置重复
1.  用户在待办列表（MacTodoHomeView）中点击某个任务（或通过右键/悬浮菜单）。
2.  点击新增的“设置重复”按钮（图标建议使用 `repeat` 或 `calendar.badge.clock`）。
3.  系统弹出“重复设置”弹窗。
4.  **弹窗内容**：
    *   **标题**：“重复此任务”
    *   **日期选择**：“重复截止至...” (Date Picker)
    *   **快捷选项**：
        *   [明天] (截止日期 = 明天)
        *   [后天] (截止日期 = 后天)
        *   [未来一周] (截止日期 = 今天 + 7天)
        *   [未来一个月] (截止日期 = 今天 + 30天)
    *   **说明文本**：“设置后，在截止日期前，每天创建新卡片时会自动包含此任务。”
    *   **操作按钮**：[取消] [确认]
5.  点击[确认]后，保存重复规则，并提示“已设置重复”。

### 2.2 自动生成任务
1.  用户点击界面顶部的“新的一天” (New Day) 按钮。
2.  系统创建今日（或次日）的 `DailyCard`。
3.  **触发检查**：系统查询所有活跃的重复规则。
    *   条件：`规则开始日期 <= 目标日期 <= 规则截止日期`。
4.  **去重检查**：检查该 `DailyCard` 中是否已经存在由该规则生成的任务（避免重复插入）。
5.  **执行插入**：将符合条件的任务自动添加到新创建的 `DailyCard` 中。

### 2.3 取消重复
1.  对于由重复规则生成的任务，或者已设置重复的原始任务，界面上应有标识（如小图标）。
2.  用户点击该任务的“设置重复”按钮（此时状态为“已设置”）。
3.  弹窗显示当前重复信息：“正在重复，截止至 202X-XX-XX”。
4.  提供 [停止重复] 按钮。
5.  点击后，删除对应的重复规则（未来的卡片不再生成，已生成的保留）。

## 3. 数据模型设计 (Schema Changes)

我们需要新增一个模型来存储重复规则，并在 `TodoItemV3` 中建立关联。

### 3.1 新增模型: `RepeatRule`

```swift
@Model
final class RepeatRule {
    var id: UUID
    var title: String          // 任务标题快照
    var startDate: Date        // 规则生效开始时间
    var endDate: Date          // 规则结束时间（含）
    var frequency: String      // 预留字段，目前默认为 "daily"
    var createdAt: Date
    
    // 关联生成的任务（可选，用于统计或级联删除，暂不强关联以简化）
    // var generatedItems: [TodoItemV3]? 
    
    init(title: String, startDate: Date, endDate: Date) { ... }
}
```

### 3.2 修改模型: `TodoItemV3`

```swift
@Model
final class TodoItemV3 {
    // ... 现有字段 ...
    
    // 新增字段
    var fromRepeatRuleId: UUID? = nil // 标识该任务是否由某个规则生成
}
```

## 4. 功能逻辑细节

### 4.1 规则匹配逻辑
在 `createTodayCard` (或类似创建特定日期卡片的方法) 中：
```swift
let targetDate = card.date
let rules = fetch(RepeatRule)
for rule in rules {
    // 检查日期范围（忽略时分秒，只比较日期部分）
    if targetDate >= rule.startDate && targetDate <= rule.endDate {
        // 检查当前卡片是否已存在该任务
        if !card.items.contains(where: { $0.fromRepeatRuleId == rule.id }) {
            let newItem = TodoItemV3(title: rule.title)
            newItem.fromRepeatRuleId = rule.id
            card.items.append(newItem)
        }
    }
}
```

### 4.2 快捷选项计算
*   **明天**：`Date() + 1 day`
*   **后天**：`Date() + 2 days`
*   **未来一周**：`Date() + 7 days`
*   **未来一个月**：`Date() + 1 month`

## 5. UI 调整计划
1.  **MacTodoItemView**: 
    *   Hover 状态下增加“重复”按钮（或者放入右键菜单/更多菜单）。
    *   如果是重复生成的任务，显示一个小图标提示。
2.  **RepeatSettingSheet**: 新增 SwiftUI 视图，用于设置截止日期。
3.  **MacTodoHomeView**: 修改 `createTodayCard` 方法，集成规则检查逻辑。

