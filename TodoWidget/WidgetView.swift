import SwiftUI
import WidgetKit

struct WidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            case .systemMedium:
                MediumWidgetView(entry: entry)
            case .systemLarge:
                LargeWidgetView(entry: entry)
            default:
                SmallWidgetView(entry: entry)
            }
        }
        .widgetURL(URL(string: "tododuck://home"))
    }
}

// MARK: - 大号组件 (详细清单)
struct LargeWidgetView: View {
    var entry: SimpleEntry
    private let visibleTaskLimit = 5
    
    // 优先级颜色辅助函数 - 与App内保持一致
    private func colorForPriority(_ priority: Int) -> Color {
        switch priority {
        case 3: return DesignSystem.error       // 高优先级 - 红色
        case 2: return Color(hex: "c77a1b")    // 中优先级 - 橙黄色
        case 1: return DesignSystem.secondary   // 低优先级 - 绿色
        default: return DesignSystem.outline    // 无优先级 - 灰色
        }
    }

    private var remainingTaskCount: Int {
        max(entry.totalCount - entry.completedCount - visibleTaskLimit, 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 顶部日期区域
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.date, format: .dateTime.month(.wide).day())
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(DesignSystem.textPrimary)
                    Text(entry.date, format: .dateTime.weekday(.wide))
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(DesignSystem.textSecondary)
                }
                Spacer()
                
                // 鸭子图标
                Image(systemName: "star.circle.fill") // 可以根据状态动态更换
                    .font(.system(size: 32))
                    .foregroundColor(DesignSystem.purple)
            }
            .padding(.bottom, 14)
            
            // 进度条
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("今日进度")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(DesignSystem.textSecondary)
                    Spacer()
                    Text("\(entry.completedCount)/\(entry.totalCount)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(DesignSystem.textPrimary)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(DesignSystem.textTertiary.opacity(0.2))
                            .frame(height: 8)
                        
                        if entry.totalCount > 0 {
                            Capsule()
                                .fill(DesignSystem.checkedColor)
                                .frame(width: geo.size.width * CGFloat(entry.completedCount) / CGFloat(entry.totalCount), height: 8)
                        }
                    }
                }
                .frame(height: 8)
            }
            .padding(.bottom, 14)
            
            // 任务列表
            VStack(alignment: .leading, spacing: 8) {
                if entry.topTasks.isEmpty {
                    if entry.totalCount > 0 && entry.completedCount == entry.totalCount {
                        // 全部完成
                        VStack(alignment: .leading, spacing: 10) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 30))
                                .foregroundColor(DesignSystem.checkedColor)
                            Text("今日任务全搞定！\n好好休息一下吧~")
                                .multilineTextAlignment(.leading)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(DesignSystem.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        // 无任务
                        VStack(alignment: .leading, spacing: 10) {
                            Image(systemName: "plus.circle.dashed")
                                .font(.system(size: 30))
                                .foregroundColor(DesignSystem.textTertiary)
                            Text("点击创建今日卡片")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(DesignSystem.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    // 显示前 5 条任务，给底部留出余量提示空间
                    ForEach(entry.topTasks.prefix(visibleTaskLimit).indices, id: \.self) { index in
                        let task = entry.topTasks[index]
                        HStack(spacing: 10) {
                            ZStack {
                                if task.isDone {
                                    // 已完成：实心绿色背景 + 白色勾
                                    Circle()
                                        .fill(DesignSystem.primary)
                                        .frame(width: 18, height: 18)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                } else {
                                    // 未完成：优先级颜色边框
                                    Circle()
                                        .stroke(colorForPriority(task.priorityRawValue), lineWidth: 2)
                                        .frame(width: 18, height: 18)

                                    if task.priorityRawValue > 0 {
                                        Circle()
                                            .fill(colorForPriority(task.priorityRawValue).opacity(0.1))
                                            .frame(width: 18, height: 18)
                                    }
                                }
                            }

                            Text(task.title)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .lineLimit(1)
                                .foregroundColor(task.isDone ? DesignSystem.textTertiary : DesignSystem.textPrimary)
                                .strikethrough(task.isDone)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    if remainingTaskCount > 0 {
                        Text("还有 \(remainingTaskCount) 项待处理")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(DesignSystem.textTertiary)
                            .padding(.top, 2)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - 小号组件 (鸭鸭心情)
struct SmallWidgetView: View {
    var entry: SimpleEntry
    
    var duckImageName: String {
        switch entry.duckStatus {
        case .working: return "book.circle.fill" // 暂时用 SF Symbols 替代，后续换自定义图片
        case .happy: return "star.circle.fill"
        case .chill: return "sun.max.circle.fill"
        case .sleep: return "moon.zzz.fill"
        }
    }
    
    var statusText: String {
        switch entry.duckStatus {
        case .working: return "加油鸭"
        case .happy: return "很棒鸭"
        case .chill: return "下班鸭"
        case .sleep: return "休息鸭"
        }
    }
    
    // 优先级颜色辅助函数 - 与App内保持一致
    private func colorForPriority(_ priority: Int) -> Color {
        switch priority {
        case 3: return DesignSystem.error       // 高优先级 - 红色
        case 2: return Color(hex: "c77a1b")    // 中优先级 - 橙黄色
        case 1: return DesignSystem.secondary   // 低优先级 - 绿色
        default: return DesignSystem.outline    // 无优先级 - 灰色
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            // 顶部日期
            HStack {
                Text(entry.date, format: .dateTime.weekday())
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.textSecondary)
                Spacer()
                Text("\(entry.completedCount)/\(entry.totalCount)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.textPrimary)
            }
            
            Spacer()
            
            // 中间鸭子
            Image(systemName: duckImageName)
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.purple)
            
            Spacer()
            
            // 底部状态
            Text(statusText)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(DesignSystem.textPrimary)
        }
        .padding()
    }
}

// MARK: - 中号组件 (今日清单)
struct MediumWidgetView: View {
    var entry: SimpleEntry
    private let visibleTaskLimit = 5

    // 优先级颜色辅助函数 - 与App内保持一致
    private func colorForPriority(_ priority: Int) -> Color {
        switch priority {
        case 3: return DesignSystem.error       // 高优先级 - 红色
        case 2: return Color(hex: "c77a1b")    // 中优先级 - 橙黄色
        case 1: return DesignSystem.secondary   // 低优先级 - 绿色
        default: return DesignSystem.outline    // 无优先级 - 灰色
        }
    }

    private var remainingTaskCount: Int {
        max(entry.totalCount - entry.completedCount - visibleTaskLimit, 0)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // 左侧概览
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.date, format: .dateTime.day())
                    .font(.system(size: 29, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.textPrimary)
                    .padding(.top, 1)

                Text(entry.date, format: .dateTime.weekday())
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(DesignSystem.textSecondary)

                Spacer()

                // 进度条
                VStack(alignment: .leading, spacing: 2) {
                    Text("剩余 \(entry.totalCount - entry.completedCount) 项")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(DesignSystem.textSecondary)
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(DesignSystem.textTertiary.opacity(0.2))
                                .frame(height: 6)

                            if entry.totalCount > 0 {
                                Capsule()
                                    .fill(DesignSystem.checkedColor)
                                    .frame(width: geo.size.width * CGFloat(entry.completedCount) / CGFloat(entry.totalCount), height: 6)
                            }
                        }
                    }
                    .frame(height: 6)
                }
                .frame(width: 56)
                .padding(.bottom, 6)
            }
            .padding(.trailing, 8)
            .frame(maxHeight: .infinity, alignment: .top)
            
            // 右侧分割线
            Rectangle()
                .fill(DesignSystem.separatorColor)
                .frame(width: 1)
                .padding(.vertical, 4)
            
            // 右侧列表
            VStack(alignment: .leading, spacing: 6) {
                if entry.topTasks.isEmpty {
                    if entry.totalCount > 0 && entry.completedCount == entry.totalCount {
                        // 全部完成
                        VStack(alignment: .leading, spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 22))
                                .foregroundColor(DesignSystem.checkedColor)
                            Text("今日任务全搞定！")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(DesignSystem.textPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        // 还没有任务
                        VStack(alignment: .leading, spacing: 8) {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 22))
                                .foregroundColor(DesignSystem.textTertiary)
                            Text("创建今日卡片")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(DesignSystem.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    // 显示前 5 条任务
                    ForEach(entry.topTasks.prefix(visibleTaskLimit).indices, id: \.self) { index in
                        let task = entry.topTasks[index]
                        HStack(spacing: 6) {
                            ZStack {
                                if task.isDone {
                                    // 已完成：实心绿色背景 + 白色勾
                                    Circle()
                                        .fill(DesignSystem.primary)
                                        .frame(width: 13, height: 13)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.white)
                                } else {
                                    // 未完成：优先级颜色边框
                                    Circle()
                                        .stroke(colorForPriority(task.priorityRawValue), lineWidth: 1.5)
                                        .frame(width: 13, height: 13)

                                    if task.priorityRawValue > 0 {
                                        Circle()
                                            .fill(colorForPriority(task.priorityRawValue).opacity(0.1))
                                            .frame(width: 13, height: 13)
                                    }
                                }
                            }

                            Text(task.title)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .lineLimit(1)
                                .minimumScaleFactor(0.9)
                                .foregroundColor(task.isDone ? DesignSystem.textTertiary : DesignSystem.textPrimary)
                                .strikethrough(task.isDone)
                            Spacer()
                        }
                    }
                    
                    if remainingTaskCount > 0 {
                        Text("还有 \(remainingTaskCount) 项")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(DesignSystem.textTertiary)
                    }
                }
            }
            .padding(.leading, 8)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
