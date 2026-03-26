import CoreNetwork
import DomainKit

struct AuthRepositoryImpl: AuthRepository {
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func signUp(firstName: String, lastName: String, email: String, password: String) async throws -> CreatedUser {
        try await client.request(.signUp(firstName: firstName, lastName: lastName, email: email, password: password))
    }

    func signIn(email: String, password: String) async throws -> AuthToken {
        try await client.request(.signIn(email: email, password: password))
    }
}
