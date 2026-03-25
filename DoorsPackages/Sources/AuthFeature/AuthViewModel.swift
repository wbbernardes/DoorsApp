import CoreNetwork
import DomainKit
import SwiftUI

@MainActor
@Observable
public final class AuthViewModel {
    public var email = ""
    public var password = ""
    public var name = ""
    public var isLoading = false
    public var errorMessage: String?
    public var isAuthenticated = false

    private let signInUseCase: SignInUseCase
    private let signUpUseCase: SignUpUseCase

    public init(
        signInUseCase: SignInUseCase = .init(repository: AuthRepositoryImpl()),
        signUpUseCase: SignUpUseCase = .init(repository: AuthRepositoryImpl())
    ) {
        self.signInUseCase = signInUseCase
        self.signUpUseCase = signUpUseCase
        checkExistingSession()
    }

    public func onSignInTap() {
        Task { await signIn() }
    }

    public func onSignUpTap() {
        Task { await signUp() }
    }

    private func signIn() async {
        isLoading = true
        errorMessage = nil
        do {
            try await signInUseCase.execute(email: email, password: password)
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func signUp() async {
        isLoading = true
        errorMessage = nil
        do {
            try await signUpUseCase.execute(name: name, email: email, password: password)
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func checkExistingSession() {
        isAuthenticated = (try? KeychainService.shared.readToken()) != nil
    }

    public func signOut() {
        KeychainService.shared.deleteToken()
        isAuthenticated = false
        email = ""
        password = ""
    }
}
