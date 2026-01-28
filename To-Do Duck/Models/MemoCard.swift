import Foundation
import SwiftData

@Model
final class MemoCardV3 {
    var id: UUID
    var content: String
    var createdAt: Date
    var updatedAt: Date? = nil
    var pinned: Bool = false
    var archived: Bool = false
    var color: String? = nil

    init(content: String) {
        self.id = UUID()
        self.content = content
        self.createdAt = Date()
        self.updatedAt = nil
        self.pinned = false
        self.archived = false
        self.color = nil
    }
}

