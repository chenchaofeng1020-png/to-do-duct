import Foundation
import SwiftData

struct ContinuationService {
    static func ensureCard(for date: Date, context: ModelContext) throws -> DailyCardV3 {
        let target = Calendar.current.startOfDay(for: date)
        let descriptor = FetchDescriptor<DailyCardV3>(predicate: #Predicate { $0.date == target })
        if let found = try context.fetch(descriptor).first {
            return found
        }
        let card = DailyCardV3(date: target)
        context.insert(card)
        return card
    }

    static func continueItem(_ item: TodoItemV3, to targetDate: Date, context: ModelContext) throws {
        let card = try ensureCard(for: targetDate, context: context)
        let title = item.title
        let series = item.seriesId ?? UUID()
        item.seriesId = series
        if item.chainIndex == nil { item.chainIndex = 1 }

        let newItem = TodoItemV3(title: title, card: card)
        newItem.seriesId = series
        newItem.priority = item.priority

        // 继承进度：新任务从原进度继续
        let carriedProgress = item.progress
        if carriedProgress > 0 && carriedProgress < 100 {
            newItem.carriedOverProgress = carriedProgress
            newItem.progressRawValue = carriedProgress
        }

        context.insert(newItem)
        try recalcSeries(seriesId: series, context: context)
    }

    static func recalcSeries(seriesId: UUID, context: ModelContext) throws {
        let descriptor = FetchDescriptor<TodoItemV3>(predicate: #Predicate { $0.seriesId == seriesId })
        var seriesItems = try context.fetch(descriptor)
        seriesItems.sort { lhs, rhs in
            let l = lhs.card?.date ?? lhs.createdAt
            let r = rhs.card?.date ?? rhs.createdAt
            return l < r
        }
        var index = 1
        for i in seriesItems {
            i.chainIndex = index
            index += 1
        }
    }
}

