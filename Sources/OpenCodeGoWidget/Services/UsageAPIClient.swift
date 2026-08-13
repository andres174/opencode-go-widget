import Foundation

public enum UsageAPIError: Error, LocalizedError, Equatable {
    case invalidResponse
    case httpError(Int)

    public var errorDescription: String? {
        switch self {
        case .invalidResponse: return "The usage response has an invalid format."
        case .httpError(let status):
            return status == 401 ? "Invalid or expired API key." : "Server error (HTTP \(status))."
        }
    }
}

public struct UsageAPIClient: Sendable {
    public let endpoint: URL
    private let session: URLSession

    public init(
        endpoint: URL = URL(string: "https://opencode.ai/zen/go/v1/usage")!,
        session: URLSession = .shared
    ) {
        self.endpoint = endpoint
        self.session = session
    }

    public func fetchUsage(apiKey: String) async throws -> UsageResponse {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.timeoutInterval = 20
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw UsageAPIError.invalidResponse }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw UsageAPIError.httpError(httpResponse.statusCode)
        }
        do {
            return try JSONDecoder().decode(UsageResponse.self, from: data)
        } catch {
            throw UsageAPIError.invalidResponse
        }
    }
}
