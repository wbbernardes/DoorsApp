import CoreNetwork

public struct SignUpUseCase: Sendable {
    private let repository: any AuthRepository
    private let keychain: KeychainService

    public init(repository: any AuthRepository, keychain: KeychainService = .shared) {
        self.repository = repository
        self.keychain = keychain
    }

    public func execute(name: String, email: String, password: String) async throws {
        let token = try await repository.signUp(name: name, email: email, password: password)
        try keychain.save(token: token.token)
    }
}
