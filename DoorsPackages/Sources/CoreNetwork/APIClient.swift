import Foundation

public final class APIClient: Sendable {
    public static let shared = APIClient()

    private let baseURL = "https://hiring-api.samba.dev.assaabloyglobalsolutions.net"
    private let keychain = KeychainService.shared
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private init() {}

    public func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        let urlRequest = try buildRequest(for: endpoint)
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        try validate(response: response, data: data)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }

    public func requestVoid(_ endpoint: Endpoint) async throws {
        let urlRequest = try buildRequest(for: endpoint)
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        try validate(response: response, data: data)
    }

    private func buildRequest(for endpoint: Endpoint) throws -> URLRequest {
        guard var components = URLComponents(string: baseURL + endpoint.path) else {
            throw NetworkError.invalidURL
        }
        components.queryItems = endpoint.queryItems

        guard let url = components.url else { throw NetworkError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = endpoint.body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        if let token = try? keychain.readToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        switch http.statusCode {
        case 200...299: break
        case 401: throw NetworkError.unauthorized
        default: throw NetworkError.httpError(statusCode: http.statusCode, data: data)
        }
    }
}
