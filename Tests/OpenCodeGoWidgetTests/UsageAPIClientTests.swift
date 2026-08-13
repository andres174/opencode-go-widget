import XCTest
@testable import OpenCodeGoWidget

final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    nonisolated(unsafe) static var rawResponse: URLResponse?
    nonisolated(unsafe) static var lastRequest: URLRequest?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lastRequest = request
        if let rawResponse = Self.rawResponse {
            client?.urlProtocol(self, didReceive: rawResponse, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data())
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

final class UsageAPIClientTests: XCTestCase {
    private let endpoint = URL(string: "https://example.test/v1/usage")!

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        MockURLProtocol.rawResponse = nil
        MockURLProtocol.lastRequest = nil
        super.tearDown()
    }

    private func makeClient() -> UsageAPIClient {
        UsageAPIClient(endpoint: endpoint, session: MockURLProtocol.makeSession())
    }

    private func httpResponse(_ statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: endpoint, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }

    private static let lowercasePayload = """
    {"usage":{"rolling":{"percent":12,"resetsAt":"2026-08-12T12:00:00Z"},"weekly":{"percent":8,"resetsAt":null},"monthly":{"percent":35,"resetsAt":"2026-09-01T00:00:00Z"}}}
    """

    private static let capitalizedPayload = """
    {"Usage":{"rolling":{"percent":12,"resetsAt":null},"weekly":{"percent":8,"resetsAt":null},"monthly":{"percent":35,"resetsAt":null}}}
    """

    func testFetchUsageDecodesLowercaseRoot() async throws {
        MockURLProtocol.requestHandler = { request in
            (self.httpResponse(200), Data(Self.lowercasePayload.utf8))
        }

        let usage = try await makeClient().fetchUsage(apiKey: "test-key")

        XCTAssertEqual(usage.usage.rolling.percent, 12)
        XCTAssertEqual(usage.usage.weekly.percent, 8)
        XCTAssertEqual(usage.usage.monthly.percent, 35)
    }

    func testFetchUsageDecodesCapitalizedRoot() async throws {
        MockURLProtocol.requestHandler = { _ in
            (self.httpResponse(200), Data(Self.capitalizedPayload.utf8))
        }

        let usage = try await makeClient().fetchUsage(apiKey: "test-key")

        XCTAssertEqual(usage.usage.monthly.percent, 35)
    }

    func testFetchUsageSendsBearerToken() async throws {
        MockURLProtocol.requestHandler = { _ in
            (self.httpResponse(200), Data(Self.lowercasePayload.utf8))
        }

        _ = try await makeClient().fetchUsage(apiKey: "secret-key")

        let request = try XCTUnwrap(MockURLProtocol.lastRequest)
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer secret-key")
    }

    func testFetchUsageUnauthorized() async {
        MockURLProtocol.requestHandler = { _ in (self.httpResponse(401), Data()) }

        do {
            _ = try await makeClient().fetchUsage(apiKey: "wrong-key")
            XCTFail("Expected UsageAPIError.httpError")
        } catch let error as UsageAPIError {
            XCTAssertEqual(error, .httpError(401))
            XCTAssertEqual(error.errorDescription, "Invalid or expired API key.")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testFetchUsageServerError() async {
        MockURLProtocol.requestHandler = { _ in (self.httpResponse(500), Data()) }

        do {
            _ = try await makeClient().fetchUsage(apiKey: "test-key")
            XCTFail("Expected UsageAPIError.httpError")
        } catch let error as UsageAPIError {
            XCTAssertEqual(error, .httpError(500))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testFetchUsageNetworkErrorPropagates() async {
        MockURLProtocol.requestHandler = { _ in throw URLError(.notConnectedToInternet) }

        do {
            _ = try await makeClient().fetchUsage(apiKey: "test-key")
            XCTFail("Expected URLError")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .notConnectedToInternet)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testFetchUsageInvalidJSON() async {
        MockURLProtocol.requestHandler = { _ in (self.httpResponse(200), Data("not json".utf8)) }

        do {
            _ = try await makeClient().fetchUsage(apiKey: "test-key")
            XCTFail("Expected UsageAPIError.invalidResponse")
        } catch let error as UsageAPIError {
            XCTAssertEqual(error, .invalidResponse)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testFetchUsageMissingFields() async {
        MockURLProtocol.requestHandler = { _ in (self.httpResponse(200), Data("{}".utf8)) }

        do {
            _ = try await makeClient().fetchUsage(apiKey: "test-key")
            XCTFail("Expected UsageAPIError.invalidResponse")
        } catch let error as UsageAPIError {
            XCTAssertEqual(error, .invalidResponse)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testFetchUsageNonHTTPResponse() async {
        MockURLProtocol.rawResponse = URLResponse(
            url: endpoint,
            mimeType: nil,
            expectedContentLength: 0,
            textEncodingName: nil
        )

        do {
            _ = try await makeClient().fetchUsage(apiKey: "test-key")
            XCTFail("Expected UsageAPIError.invalidResponse")
        } catch let error as UsageAPIError {
            XCTAssertEqual(error, .invalidResponse)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
