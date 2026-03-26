import CoreNetwork

public struct SignInUseCase: Sendable {
    private let repository: any AuthRepository
    private let keychain: any KeychainServiceProtocol

    public init(repository: any AuthRepository, keychain: any KeychainServiceProtocol = KeychainService.shared) {
        self.repository = repository
        self.keychain = keychain
    }

    public func execute(email: String, password: String) async throws {
        let token = try await repository.signIn(email: email, password: password)
        try keychain.save(token: token.token)
    }
}
