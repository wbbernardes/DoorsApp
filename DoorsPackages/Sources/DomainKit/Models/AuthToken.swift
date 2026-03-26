import Foundation

public struct AuthToken: Decodable, Sendable {
    public let token: String
}

public struct CreatedUser: Decodable, Sendable {
    public let id: Int
    public let firstName: String
    public let lastName: String
    public let email: String
}
