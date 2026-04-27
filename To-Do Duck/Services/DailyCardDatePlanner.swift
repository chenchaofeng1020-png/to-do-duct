import Foundation

enum DailyCardDatePlanner {
    static func targetDate(
        latestCardDate: Date?,
        today: Date = Date(),
        calendar: Calendar = .current
    ) -> Date {
        let todayStart = calendar.startOfDay(for: today)

        guard let latestCardDate else {
            return todayStart
        }

        let latestStart = calendar.startOfDay(for: latestCardDate)
        if latestStart < todayStart {
            return todayStart
        }

        let nextDate = calendar.date(byAdding: .day, value: 1, to: latestStart) ?? todayStart
        return calendar.startOfDay(for: nextDate)
    }
}
