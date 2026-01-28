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
        case .none: return DesignSystem.textTertiary
        case .low: return Color.blue
        case .medium: return Color.orange
        case .high: return Color.red
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
        self.card = card
    }
}

extension TodoItemV3 {
    var priority: TodoPriority {
        get { TodoPriority(rawValue: priorityRawValue) ?? .none }
        set { priorityRawValue = newValue.rawValue }
    }
}
