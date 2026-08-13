import XCTest
@testable import OpenCodeGoWidget

final class UsageResponseTests: XCTestCase {
    func testDecodesUsagePayload() throws {
        let data = Data(#"{"Usage":{"rolling":{"percent":12,"resetsAt":"2026-08-12T12:00:00Z"},"weekly":{"percent":8,"resetsAt":null},"monthly":{"percent":35,"resetsAt":"2026-09-01T00:00:00Z"}}}"#.utf8)
        let response = try JSONDecoder().decode(UsageResponse.self, from: data)

        XCTAssertEqual(response.usage.rolling.percent, 12)
        XCTAssertEqual(response.usage.monthly.percent, 35)
        XCTAssertNil(response.usage.weekly.resetsAt)
    }

    func testDecodesLowercaseRootKey() throws {
        let data = Data(#"{"usage":{"rolling":{"percent":12,"resetsAt":null},"weekly":{"percent":8,"resetsAt":null},"monthly":{"percent":35,"resetsAt":null}}}"#.utf8)
        let response = try JSONDecoder().decode(UsageResponse.self, from: data)

        XCTAssertEqual(response.usage.rolling.percent, 12)
        XCTAssertEqual(response.usage.monthly.percent, 35)
    }

    func testDecodeFailsWhenUsageKeyMissing() {
        let data = Data(#"{"foo":1}"#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(UsageResponse.self, from: data))
    }

    func testDecodeFailsWhenWindowMissing() {
        let data = Data(#"{"usage":{"rolling":{"percent":12,"resetsAt":null},"weekly":{"percent":8,"resetsAt":null}}}"#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(UsageResponse.self, from: data))
    }

    func testValidatedPercentClampsBelowZero() {
        let window = UsageWindow(percent: -25)
        XCTAssertEqual(window.validatedPercent, 0)
    }

    func testValidatedPercentClampsAboveHundred() {
        let window = UsageWindow(percent: 150)
        XCTAssertEqual(window.validatedPercent, 100)
    }

    func testValidatedPercentKeepsInRangeValues() {
        let window = UsageWindow(percent: 42.5)
        XCTAssertEqual(window.validatedPercent, 42.5)
    }

    func testDecodedOutOfRangePercentIsClampedByValidatedPercent() throws {
        let data = Data(#"{"usage":{"rolling":{"percent":120,"resetsAt":null},"weekly":{"percent":-5,"resetsAt":null},"monthly":{"percent":50,"resetsAt":null}}}"#.utf8)
        let response = try JSONDecoder().decode(UsageResponse.self, from: data)

        XCTAssertEqual(response.usage.rolling.validatedPercent, 100)
        XCTAssertEqual(response.usage.weekly.validatedPercent, 0)
        XCTAssertEqual(response.usage.monthly.validatedPercent, 50)
    }
}
