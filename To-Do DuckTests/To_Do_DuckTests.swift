//
//  To_Do_DuckTests.swift
//  To-Do DuckTests
//
//  Created by 朝峰 chen on 2026/1/8.
//

import Testing
import SwiftData
@testable import To_Do_Duck

struct To_Do_DuckTests {

    @Test func chainRecalculation() async throws {
        let schema = Schema([DailyCard.self, TodoItem.self, MemoCard.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        let context = container.mainContext
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let card1 = DailyCard(date: today)
        let card2 = DailyCard(date: tomorrow)
        context.insert(card1)
        context.insert(card2)
        let item = TodoItem(title: "继续做年度报告", card: card1)
        context.insert(item)
        try ContinuationService.continueItem(item, to: tomorrow, context: context)
        let series = item.seriesId!
        let descriptor = FetchDescriptor<TodoItem>(predicate: #Predicate { $0.seriesId == series })
        let items = try context.fetch(descriptor).sorted { ($0.card?.date ?? $0.createdAt) < ($1.card?.date ?? $1.createdAt) }
        #expect(items.count == 2)
        #expect(items[0].chainIndex == 1)
        #expect(items[1].chainIndex == 2)
    }

}
