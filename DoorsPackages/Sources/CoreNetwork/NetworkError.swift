import Foundation

public enum NetworkError: Error, LocalizedError, Sendable {
    case invalidURL
    case unauthorized
    case httpError(statusCode: Int, data: Data)
    case decodingFailed(Error)
    case noToken
    case encryptionFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidURL: "Invalid URL."
        case .unauthorized: "Session expired. Please sign in again."
        case let .httpError(code, _): "Server error (\(code))."
        case .decodingFailed: "Unexpected server response."
        case .noToken: "No auth token found."
        case .encryptionFailed: "Failed to decrypt server response."
        }
    }
}
