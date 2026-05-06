import Foundation
import SwiftData
import WidgetKit

enum QuickCaptureSaveError: LocalizedError {
    case emptyText

    var errorDescription: String? {
        switch self {
        case .emptyText:
            return "请输入内容后再保存"
        }
    }
}

@MainActor
final class QuickCaptureSaveService {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func saveInboxItem(text: String) throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw QuickCaptureSaveError.emptyText
        }

        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<TodoItemV3>(
            predicate: #Predicate<TodoItemV3> { item in
                item.card == nil
            },
            sortBy: [
                SortDescriptor(\TodoItemV3.orderIndex),
                SortDescriptor(\TodoItemV3.createdAt)
            ]
        )

        let inboxItems = try context.fetch(descriptor)
        let nextOrder = (inboxItems.map(\.orderIndex).max() ?? -1) + 1

        let item = TodoItemV3(title: trimmed, card: nil)
        item.orderIndex = nextOrder
        context.insert(item)

        try context.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    func saveMemo(text: String) throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw QuickCaptureSaveError.emptyText
        }

        let context = ModelContext(modelContainer)
        let memo = MemoCardV3(content: trimmed)
        context.insert(memo)

        try context.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
