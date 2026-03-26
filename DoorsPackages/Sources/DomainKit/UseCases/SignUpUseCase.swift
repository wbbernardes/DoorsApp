import CoreNetwork

public struct SignUpUseCase: Sendable {
    private let repository: any AuthRepository
    private let keychain: KeychainService

    public init(repository: any AuthRepository, keychain: KeychainService = .shared) {
        self.repository = repository
        self.keychain = keychain
    }

    /// Sign up then immediately sign in — saves token to Keychain on success.
    public func execute(firstName: String, lastName: String, email: String, password: String) async throws {
        _ = try await repository.signUp(firstName: firstName, lastName: lastName, email: email, password: password)
        let token = try await repository.signIn(email: email, password: password)
        try keychain.save(token: token.token)
    }
}
