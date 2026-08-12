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
}
