import CoreNetwork

public protocol AuthRepository: Sendable {
    func signUp(name: String, email: String, password: String) async throws -> AuthToken
    func signIn(email: String, password: String) async throws -> AuthToken
}
