import Foundation
import Testing
@testable import To_Do_Duck

struct DailyCardDatePlannerTests {
    private let calendar = Calendar(identifier: .gregorian)

    @Test func createsTodayWhenThereAreNoCards() {
        let today = date(2026, 1, 8)

        let target = DailyCardDatePlanner.targetDate(
            latestCardDate: nil,
            today: today,
            calendar: calendar
        )

        #expect(target == today)
    }

    @Test func jumpsToTodayWhenLatestCardIsBehind() {
        let latest = date(2026, 1, 1)
        let today = date(2026, 1, 8)

        let target = DailyCardDatePlanner.targetDate(
            latestCardDate: latest,
            today: today,
            calendar: calendar
        )

        #expect(target == today)
    }

    @Test func createsTomorrowWhenLatestCardIsToday() {
        let today = date(2026, 1, 8)
        let tomorrow = date(2026, 1, 9)

        let target = DailyCardDatePlanner.targetDate(
            latestCardDate: today,
            today: today,
            calendar: calendar
        )

        #expect(target == tomorrow)
    }

    @Test func keepsCreatingForwardWhenLatestCardIsAlreadyInTheFuture() {
        let today = date(2026, 1, 8)
        let latest = date(2026, 1, 10)
        let expected = date(2026, 1, 11)

        let target = DailyCardDatePlanner.targetDate(
            latestCardDate: latest,
            today: today,
            calendar: calendar
        )

        #expect(target == expected)
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        let components = DateComponents(
            calendar: calendar,
            timeZone: TimeZone(secondsFromGMT: 0),
            year: year,
            month: month,
            day: day
        )
        return calendar.date(from: components)!
    }
}
