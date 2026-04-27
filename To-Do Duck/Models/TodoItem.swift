import Foundation
import SwiftData
import SwiftUI

enum TodoPriority: Int, Codable, CaseIterable {
    case none = 0
    case low = 1
    case medium = 2
    case high = 3
    
    var color: Color {
        switch self {
        case .none: return DesignSystem.outline
        case .low: return DesignSystem.secondary    // 绿色 - 低优先级
        case .medium: return Color(hex: "c77a1b")  // 橙黄色 - 中优先级，更明显的区分
        case .high: return DesignSystem.error       // 红色 - 高优先级
        }
    }
    
    var label: String {
        switch self {
        case .none: return "无"
        case .low: return "低"
        case .medium: return "中"
        case .high: return "高"
        }
    }
}

@Model
final class TodoItemV3 {
    var id: UUID = UUID()
    var title: String = ""
    var isDone: Bool = false
    var createdAt: Date = Date()
    var completedAt: Date? = nil
    var orderIndex: Int = 0
    var seriesId: UUID? = nil
    var chainIndex: Int? = nil
    var priorityRawValue: Int = 0
    var fromRepeatRuleId: UUID? = nil // 新增字段：关联重复规则 ID
    var progressRawValue: Int = 0 // 当前进度 0~100
    var carriedOverProgress: Int = 0 // 从上一个延续任务继承的进度（记录用）
    // 移除显式 inverse 以避免与 DailyCardV3 的 Relationship 宏发生循环展开死锁
    // SwiftData 会自动推断反向关系
    var card: DailyCardV3? = nil

    init(title: String, card: DailyCardV3?) {
        self.id = UUID()
        self.title = title
        self.isDone = false
        self.createdAt = Date()
        self.completedAt = nil
        self.orderIndex = 0
        self.seriesId = nil
        self.chainIndex = nil
        self.priorityRawValue = 0
        self.fromRepeatRuleId = nil
        self.progressRawValue = 0
        self.carriedOverProgress = 0
        self.card = card
    }
}

extension TodoItemV3 {
    var priority: TodoPriority {
        get { TodoPriority(rawValue: priorityRawValue) ?? .none }
        set { priorityRawValue = newValue.rawValue }
    }

    var progress: Int {
        get {
            if isDone { return 100 }
            return min(max(progressRawValue, 0), 100)
        }
        set {
            let clamped = min(max(newValue, 0), 100)
            progressRawValue = clamped
            isDone = (clamped == 100)
            if isDone && completedAt == nil {
                completedAt = Date()
            } else if !isDone {
                completedAt = nil
            }
        }
    }
}

// MARK: - RepeatRule Model
// Moved from RepeatRule.swift to ensure visibility across targets without modifying project file
@Model
final class RepeatRule {
    var id: UUID = UUID()
    var title: String = ""
    var startDate: Date = Date()
    var endDate: Date = Date()
    var frequency: String = "daily" // 预留字段：daily, weekly, etc.
    var createdAt: Date = Date()
    
    init(title: String, startDate: Date, endDate: Date) {
        self.id = UUID()
        self.title = title
        self.startDate = Calendar.current.startOfDay(for: startDate)
        self.endDate = Calendar.current.startOfDay(for: endDate)
        self.frequency = "daily"
        self.createdAt = Date()
    }
}
