@testable import CoreNetwork
import Foundation

// MARK: - MockURLProtocol

/// URLProtocol subclass that intercepts all requests and returns a stubbed response.
/// Register via URLSessionConfiguration.protocolClasses before creating the test URLSession.
final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    nonisolated(unsafe) static var lastRequest: URLRequest?

    override class func canInit(with _: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.lastRequest = request
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
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
}

// MARK: - Helpers

extension MockURLProtocol {
    static func stub(statusCode: Int, json: String, headers: [String: String]? = nil) {
        requestHandler = { request in
            var allHeaders = ["Content-Type": "application/json"]
            if let headers { allHeaders.merge(headers) { _, new in new } }
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: allHeaders
            )!
            return (response, Data(json.utf8))
        }
    }

    static func stub(statusCode: Int, data: Data, headers: [String: String]? = nil) {
        requestHandler = { request in
            var allHeaders = ["Content-Type": "application/json"]
            if let headers { allHeaders.merge(headers) { _, new in new } }
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: allHeaders
            )!
            return (response, data)
        }
    }

    static func reset() {
        requestHandler = nil
        lastRequest = nil
    }
}

// MARK: - Factory

func makeTestClient(
    keychain: any KeychainServiceProtocol = MockKeychainService(),
    encryptionService: any EncryptionServiceProtocol = EncryptionService(),
    encryptionEnabled: Bool = false
) -> APIClient {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    return APIClient(
        session: URLSession(configuration: config),
        keychain: keychain,
        encryptionService: encryptionService,
        encryptionEnabled: encryptionEnabled
    )
}
