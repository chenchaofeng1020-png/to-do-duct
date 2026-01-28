import Foundation
import SwiftData

@Model
final class DailyCardV3 {
    var id: UUID = UUID()
    var date: Date = Date()
    var createdAt: Date = Date()
    var customTitle: String? = nil
    @Relationship(deleteRule: .cascade) var items: [TodoItemV3] = []

    init(date: Date) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.createdAt = Date()
        self.customTitle = nil
    }
}
