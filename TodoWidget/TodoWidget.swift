import WidgetKit
import SwiftUI
import SwiftData

// 注意：这里没有 @main，因为入口在 TodoWidgetBundle.swift 中
struct DuckWidget: Widget {
    let kind: String = "DuckWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetEntryView(entry: entry)
                .containerBackground(DesignSystem.warmBackground, for: .widget)
        }
        .configurationDisplayName("To-Do Duck")
        .description("查看今天的待办事项和鸭鸭心情。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// 预览代码
#Preview(as: .systemMedium) {
    DuckWidget()
} timeline: {
    SimpleEntry(date: .now, completedCount: 2, totalCount: 5, topTasks: [
        WidgetTask(id: UUID(), title: "高优先级任务", isDone: false, priorityRawValue: 3),
        WidgetTask(id: UUID(), title: "中优先级任务", isDone: false, priorityRawValue: 2),
        WidgetTask(id: UUID(), title: "已完成任务", isDone: true, priorityRawValue: 1)
    ], duckStatus: .working)
}
