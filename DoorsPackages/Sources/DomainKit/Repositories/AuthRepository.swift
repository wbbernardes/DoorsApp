import Foundation

public protocol AuthRepository: Sendable {
    func signUp(firstName: String, lastName: String, email: String, password: String) async throws -> CreatedUser
    func signIn(email: String, password: String) async throws -> AuthToken
}
