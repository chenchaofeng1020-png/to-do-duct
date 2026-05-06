import Foundation
import Testing
@testable import To_Do_Duck

struct TodoSearchMatcherTests {
    @Test func matchesCaseInsensitively() {
        #expect(TodoSearchMatcher.matches("Buy Coffee", query: "coffee"))
    }

    @Test func trimsWhitespaceInQuery() {
        #expect(TodoSearchMatcher.matches("Plan trip", query: "  trip  "))
    }

    @Test func supportsChineseDateAliases() {
        #expect(TodoSearchMatcher.matchesAny(["今天", "2026年5月6日"], query: "今天"))
    }

    @Test func returnsFalseForUnmatchedContent() {
        #expect(!TodoSearchMatcher.matches("Write report", query: "groceries"))
    }
}
