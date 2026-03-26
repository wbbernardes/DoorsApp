import CoreNetwork
import Foundation
import Testing

@Suite("NetworkError")
struct NetworkErrorTests {
    @Test func unauthorizedDescription() {
        #expect(NetworkError.unauthorized.errorDescription == "Session expired. Please sign in again.")
    }

    @Test func invalidURLDescription() {
        #expect(NetworkError.invalidURL.errorDescription == "Invalid URL.")
    }

    @Test func noTokenDescription() {
        #expect(NetworkError.noToken.errorDescription == "No auth token found.")
    }

    @Test func httpErrorDescription_includesStatusCode() {
        let error = NetworkError.httpError(statusCode: 500, data: Data())
        #expect(error.errorDescription == "Server error (500).")
    }

    @Test func httpErrorDescription_404() {
        let error = NetworkError.httpError(statusCode: 404, data: Data())
        #expect(error.errorDescription == "Server error (404).")
    }

    @Test func decodingFailedDescription() {
        let underlying = NSError(domain: "test", code: 0)
        let error = NetworkError.decodingFailed(underlying)
        #expect(error.errorDescription == "Unexpected server response.")
    }
}
