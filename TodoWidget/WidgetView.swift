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
    
    // 优先级颜色辅助函数
    private func colorForPriority(_ priority: Int) -> Color {
        switch priority {
        case 3: return .red
        case 2: return .orange
        case 1: return .blue
        default: return DesignSystem.textTertiary
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
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
            .padding(.bottom, 20)
            
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
            .padding(.bottom, 20)
            
            // 任务列表
            VStack(alignment: .leading, spacing: 12) {
                if entry.topTasks.isEmpty {
                    if entry.totalCount > 0 && entry.completedCount == entry.totalCount {
                        // 全部完成
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 40))
                                .foregroundColor(DesignSystem.checkedColor)
                            Text("今日任务全搞定！\n好好休息一下吧~")
                                .multilineTextAlignment(.center)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(DesignSystem.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        Spacer()
                    } else {
                        // 无任务
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "plus.circle.dashed")
                                .font(.system(size: 40))
                                .foregroundColor(DesignSystem.textTertiary)
                            Text("点击创建今日卡片")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(DesignSystem.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        Spacer()
                    }
                } else {
                    // 显示前 6 条任务 (大号组件空间更多)
                    ForEach(entry.topTasks.prefix(6).indices, id: \.self) { index in
                        let task = entry.topTasks[index]
                        HStack(spacing: 12) {
                            ZStack {
                                if task.isDone {
                                    // 已完成：实心绿色背景 + 白色勾
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(DesignSystem.checkedColor)
                                        .frame(width: 20, height: 20)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                } else {
                                    // 未完成：优先级颜色边框
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(colorForPriority(task.priorityRawValue), lineWidth: 2)
                                        .frame(width: 20, height: 20)
                                    
                                    if task.priorityRawValue > 0 {
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(colorForPriority(task.priorityRawValue).opacity(0.1))
                                            .frame(width: 20, height: 20)
                                    }
                                }
                            }
                            
                            Text(task.title)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .lineLimit(1)
                                .foregroundColor(task.isDone ? DesignSystem.textTertiary : DesignSystem.textPrimary)
                                .strikethrough(task.isDone)
                            Spacer()
                        }
                    }
                    
                    if entry.totalCount - entry.completedCount > 6 {
                        Spacer()
                        Text("...还有 \(entry.totalCount - entry.completedCount - 6) 项任务")
                            .font(.system(size: 14))
                            .foregroundColor(DesignSystem.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        Spacer()
                    }
                }
            }
        }
        .padding(20)
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
    
    // 优先级颜色辅助函数
    private func colorForPriority(_ priority: Int) -> Color {
        switch priority {
        case 3: return .red
        case 2: return .orange
        case 1: return .blue
        default: return DesignSystem.textTertiary
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
    
    // 优先级颜色辅助函数
    private func colorForPriority(_ priority: Int) -> Color {
        switch priority {
        case 3: return .red
        case 2: return .orange
        case 1: return .blue
        default: return DesignSystem.textTertiary
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // 左侧概览
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.date, format: .dateTime.day())
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.textPrimary)
                
                Text(entry.date, format: .dateTime.weekday())
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(DesignSystem.textSecondary)
                
                Spacer()
                
                // 进度条
                VStack(alignment: .leading, spacing: 4) {
                    Text("剩余 \(entry.totalCount - entry.completedCount) 项")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
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
                .frame(width: 80)
            }
            .padding(.trailing, 16)
            
            // 右侧分割线
            Rectangle()
                .fill(DesignSystem.separatorColor)
                .frame(width: 1)
                .padding(.vertical, 8)
            
            // 右侧列表
            VStack(alignment: .leading, spacing: 8) {
                if entry.topTasks.isEmpty {
                    if entry.totalCount > 0 && entry.completedCount == entry.totalCount {
                        // 全部完成
                        VStack(alignment: .center, spacing: 8) {
                            Spacer()
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 24))
                                .foregroundColor(DesignSystem.checkedColor)
                            Text("今日任务全搞定！")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(DesignSystem.textPrimary)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        // 还没有任务
                        VStack(alignment: .center, spacing: 8) {
                            Spacer()
                            Image(systemName: "plus.circle")
                                .font(.system(size: 24))
                                .foregroundColor(DesignSystem.textTertiary)
                            Text("创建今日卡片")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(DesignSystem.textSecondary)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    // 显示前 3 条任务
                    ForEach(entry.topTasks.indices, id: \.self) { index in
                        let task = entry.topTasks[index]
                        HStack(spacing: 8) {
                            ZStack {
                                if task.isDone {
                                    // 已完成：实心绿色背景 + 白色勾
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(DesignSystem.checkedColor)
                                        .frame(width: 16, height: 16)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                } else {
                                    // 未完成：优先级颜色边框
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(colorForPriority(task.priorityRawValue), lineWidth: 1.5)
                                        .frame(width: 16, height: 16)
                                    
                                    if task.priorityRawValue > 0 {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(colorForPriority(task.priorityRawValue).opacity(0.1))
                                            .frame(width: 16, height: 16)
                                    }
                                }
                            }
                            
                            Text(task.title)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .lineLimit(1)
                                .foregroundColor(task.isDone ? DesignSystem.textTertiary : DesignSystem.textPrimary)
                                .strikethrough(task.isDone)
                            Spacer()
                        }
                    }
                    
                    if entry.totalCount - entry.completedCount > 3 {
                        Text("...还有 \(entry.totalCount - entry.completedCount - 3) 项")
                            .font(.system(size: 12))
                            .foregroundColor(DesignSystem.textTertiary)
                    }
                    Spacer()
                }
            }
            .padding(.leading, 16)
        }
        .padding()
    }
}
