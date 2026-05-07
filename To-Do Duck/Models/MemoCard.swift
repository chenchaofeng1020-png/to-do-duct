import Foundation
import SwiftData

@Model
final class MemoCardV3 {
    var id: UUID = UUID()
    var content: String = ""
    var richTextData: Data? = nil
    var createdAt: Date = Date()
    var updatedAt: Date? = nil
    var pinned: Bool = false
    var archived: Bool = false
    var color: String? = nil

    init(content: String, richTextData: Data? = nil) {
        self.content = content
        self.richTextData = richTextData
    }
}
