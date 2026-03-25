import CoreNetwork
import DomainKit

public struct AuthRepositoryImpl: AuthRepository {
    private let client: APIClient

    public init(client: APIClient = .shared) {
        self.client = client
    }

    public func signUp(name: String, email: String, password: String) async throws -> AuthToken {
        try await client.request(.signUp(.init(name: name, email: email, password: password)))
    }

    public func signIn(email: String, password: String) async throws -> AuthToken {
        try await client.request(.signIn(.init(email: email, password: password)))
    }
}
