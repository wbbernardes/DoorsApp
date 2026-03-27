import CryptoKit
import Foundation

public final class APIClient: @unchecked Sendable {
    public static let shared = APIClient()

    private let baseURL = "https://hiring-api.samba.dev.assaabloyglobalsolutions.net"
    private let session: URLSession
    private let keychain: any KeychainServiceProtocol
    private let encryptionService: any EncryptionServiceProtocol
    public var encryptionEnabled: Bool = true
    private let decoder: JSONDecoder = {
        let dec = JSONDecoder()
        dec.keyDecodingStrategy = .convertFromSnakeCase
        // API returns timestamps without timezone: "2025-06-12T14:32:00"
        dec.dateDecodingStrategy = .custom { decoder in
            let string = try decoder.singleValueContainer().decode(String.self)
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(identifier: "UTC")
            for format in ["yyyy-MM-dd'T'HH:mm:ssZ", "yyyy-MM-dd'T'HH:mm:ss"] {
                formatter.dateFormat = format
                if let date = formatter.date(from: string) { return date }
            }
            throw try DecodingError.dataCorruptedError(in: decoder.singleValueContainer(),
                                                       debugDescription: "Cannot decode date: \(string)")
        }
        return dec
    }()

    private init() {
        session = .shared
        keychain = KeychainService.shared
        encryptionService = EncryptionService()
    }

    /// Injectable initializer for integration tests.
    init(
        session: URLSession,
        keychain: any KeychainServiceProtocol = KeychainService.shared,
        encryptionService: any EncryptionServiceProtocol = EncryptionService(),
        encryptionEnabled: Bool = false
    ) {
        self.session = session
        self.keychain = keychain
        self.encryptionService = encryptionService
        self.encryptionEnabled = encryptionEnabled
    }

    public func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        var urlRequest = try buildRequest(for: endpoint)

        var ephemeralPrivateKey: P256.KeyAgreement.PrivateKey?
        if encryptionEnabled, endpoint.supportsEncryption {
            let (publicKeyBase64, privateKey) = try encryptionService.generateKeyPair()
            urlRequest.setValue(publicKeyBase64, forHTTPHeaderField: "X-Client-Public-Key")
            ephemeralPrivateKey = privateKey
        }

        logRequest(urlRequest)
        let (data, response) = try await session.data(for: urlRequest)
        logResponse(response, data: data)
        try validate(response: response, data: data)

        let plainData: Data
        if let privateKey = ephemeralPrivateKey,
           let httpResponse = response as? HTTPURLResponse,
           let serverPublicKey = httpResponse.value(forHTTPHeaderField: "X-Server-Public-Key") {
            do {
                let envelope = try decoder.decode(EncryptedEnvelope.self, from: data)
                guard let nonceData = Data(base64Encoded: envelope.iv),
                      let ciphertextData = Data(base64Encoded: envelope.ciphertext)
                else {
                    throw EncryptionError.invalidCiphertext
                }
                plainData = try encryptionService.decrypt(
                    ciphertext: ciphertextData,
                    nonce: nonceData,
                    serverPublicKeyBase64: serverPublicKey,
                    privateKey: privateKey
                )
                print("[APIClient] Decrypted \(plainData.count) bytes")
            } catch {
                print("[APIClient] Decryption failed: \(error)")
                throw NetworkError.encryptionFailed(error)
            }
        } else {
            plainData = data
        }

        do {
            return try decoder.decode(T.self, from: plainData)
        } catch {
            let raw = String(data: plainData, encoding: .utf8) ?? "<non-utf8>"
            print("[APIClient] DecodingFailed for \(T.self): \(error)\nRaw JSON: \(raw)")
            throw NetworkError.decodingFailed(error)
        }
    }

    public func requestVoid(_ endpoint: Endpoint) async throws {
        let urlRequest = try buildRequest(for: endpoint)
        logRequest(urlRequest)
        let (data, response) = try await session.data(for: urlRequest)
        logResponse(response, data: data)
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

    private func logRequest(_ request: URLRequest) {
        print("[APIClient] --> \(request.httpMethod ?? "?") \(request.url?.absoluteString ?? "?")")
        if let body = request.httpBody, let json = String(data: body, encoding: .utf8) {
            print("[APIClient]     Body: \(json)")
        }
    }

    private func logResponse(_ response: URLResponse, data: Data) {
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        let body = String(data: data, encoding: .utf8) ?? "<non-utf8>"
        print("[APIClient] <-- \(status) (\(data.count) bytes): \(body)")
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        switch http.statusCode {
        case 200 ... 299: break
        case 401:
            keychain.deleteToken()
            throw NetworkError.unauthorized
        default:
            let body = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            print("[APIClient] HTTP \(http.statusCode): \(body)")
            throw NetworkError.httpError(statusCode: http.statusCode, data: data)
        }
    }
}
