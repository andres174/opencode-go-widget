import XCTest
@testable import OpenCodeGoWidget

final class ResetDateFormatterTests: XCTestCase {
    private var formatter: ResetDateFormatter!
    private var now: Date!

    override func setUp() {
        super.setUp()
        formatter = ResetDateFormatter(locale: Locale(identifier: "en_US"), timeZone: TimeZone(secondsFromGMT: 0)!)
        now = Date(timeIntervalSince1970: 1_700_000_000) // 2023-11-14T22:13:20Z
    }

    private func iso(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    func testNilResetsAtReturnsNil() {
        XCTAssertNil(formatter.friendlyResetText(resetsAt: nil, relativeTo: now))
    }

    func testInvalidDateReturnsNil() {
        XCTAssertNil(formatter.friendlyResetText(resetsAt: "not-a-date", relativeTo: now))
    }

    func testResetsNowWithinAMinute() {
        let future = now.addingTimeInterval(30)
        let text = formatter.friendlyResetText(resetsAt: iso(future), relativeTo: now)
        XCTAssertEqual(text, "Resets now")
    }

    func testResetsInMinutes() {
        let future = now.addingTimeInterval(34 * 60)
        let text = formatter.friendlyResetText(resetsAt: iso(future), relativeTo: now)
        XCTAssertEqual(text, "Resets in 34 minutes")
    }

    func testResetsInHours() {
        let morning = Date(timeIntervalSince1970: 1_699_956_000) // 2023-11-14T10:00:00Z
        let future = morning.addingTimeInterval(4 * 3600) // same calendar day
        let text = formatter.friendlyResetText(resetsAt: iso(future), relativeTo: morning)
        XCTAssertEqual(text, "Resets in 4 hours")
    }

    func testResetsTomorrow() {
        let future = now.addingTimeInterval(20 * 3600) // 2023-11-15T18:13:20Z
        let text = formatter.friendlyResetText(resetsAt: iso(future), relativeTo: now)
        XCTAssertEqual(text, "Resets tomorrow")
    }

    func testResetsInDays() {
        let future = now.addingTimeInterval(3 * 86_400)
        let text = formatter.friendlyResetText(resetsAt: iso(future), relativeTo: now)
        XCTAssertEqual(text, "Resets in 3 days")
    }

    func testResetsOnExactDateBeyondAWeek() {
        let future = now.addingTimeInterval(18 * 86_400)
        let text = formatter.friendlyResetText(resetsAt: iso(future), relativeTo: now)
        XCTAssertEqual(text, "Resets on Dec 2, 2023")
    }

    func testPastDateUsesExactDate() {
        let past = now.addingTimeInterval(-2 * 86_400)
        let text = formatter.friendlyResetText(resetsAt: iso(past), relativeTo: now)
        XCTAssertEqual(text, "Resets on Nov 12, 2023")
    }

    func testExactResetTextFormatsFullDateAndTime() {
        let date = now.addingTimeInterval(18 * 86_400)
        let text = formatter.exactResetText(resetsAt: iso(date))
        let normalized = text?.replacingOccurrences(of: "\u{202F}", with: " ")
        XCTAssertEqual(normalized, "Dec 2, 2023 at 10:13 PM")
    }

    func testExactResetTextNilForNilInput() {
        XCTAssertNil(formatter.exactResetText(resetsAt: nil))
    }
}
