import Foundation

public enum UsageAPIError: Error, LocalizedError {
    case invalidResponse
    case httpError(Int)

    public var errorDescription: String? {
        switch self {
        case .invalidResponse: return "La respuesta de usage no tiene un formato válido."
        case .httpError(let status):
            return status == 401 ? "API key inválida o expirada." : "Error del servidor (HTTP \(status))."
        }
    }
}

public struct UsageAPIClient: Sendable {
    public let endpoint: URL

    public init(endpoint: URL = URL(string: "https://opencode.ai/zen/go/v1/usage")!) {
        self.endpoint = endpoint
    }

    public func fetchUsage(apiKey: String, session: URLSession = .shared) async throws -> UsageResponse {
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
