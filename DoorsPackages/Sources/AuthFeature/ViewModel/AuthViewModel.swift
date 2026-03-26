import CoreNetwork
import DomainKit
import SwiftUI

@MainActor
@Observable
public final class AuthViewModel {
    // MARK: - Local UI State

    var email = ""
    var password = ""
    var firstName = ""
    var lastName = ""
    var isLoading = false
    var errorMessage: String?
    public var isAuthenticated = false

    // MARK: - Computed Properties

    let isUITesting = ProcessInfo.processInfo.arguments.contains("-uitesting")

    var isEmailValid: Bool {
        email.contains("@") && email.contains(".")
    }

    var isPasswordValid: Bool {
        passwordLengthValid && passwordHasUppercase && passwordHasNumber && passwordHasSymbol
    }

    var passwordLengthValid: Bool {
        let count = password.count
        return count >= 4 && count <= 12
    }

    var passwordHasUppercase: Bool {
        password.contains { $0.isUppercase }
    }

    var passwordHasNumber: Bool {
        password.contains { $0.isNumber }
    }

    var passwordHasSymbol: Bool {
        password.contains { $0.isPunctuation || $0.isSymbol }
    }

    var isSignInFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }

    var isSignUpFormValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty && isEmailValid && isPasswordValid
    }

    // MARK: - Dependencies

    private let signInUseCase: SignInUseCase
    private let signUpUseCase: SignUpUseCase

    // MARK: - Initialization

    public init() {
        signInUseCase = .init(repository: AuthRepositoryImpl())
        signUpUseCase = .init(repository: AuthRepositoryImpl())
        checkExistingSession()
    }

    /// Injectable init for testing.
    init(signInUseCase: SignInUseCase, signUpUseCase: SignUpUseCase) {
        self.signInUseCase = signInUseCase
        self.signUpUseCase = signUpUseCase
        checkExistingSession()
    }

    // MARK: - Actions

    func onSignInTap() {
        Task { await signIn() }
    }

    func onSignUpTap() {
        Task { await signUp() }
    }

    public func signOut() {
        KeychainService.shared.deleteToken()
        isAuthenticated = false
        email = ""
        password = ""
        firstName = ""
        lastName = ""
    }

    public func handleUnauthorized() {
        signOut()
    }

    public func clearError() {
        errorMessage = nil
    }

    // MARK: - Private

    private func signIn() async {
        isLoading = true
        errorMessage = nil
        defer { password = "" }
        do {
            try await signInUseCase.execute(email: email, password: password)
            isAuthenticated = true
        } catch {
            print("[AuthViewModel] signIn error: \(error)")
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func signUp() async {
        isLoading = true
        errorMessage = nil
        defer { password = "" }
        do {
            try await signUpUseCase.execute(
                firstName: firstName,
                lastName: lastName,
                email: email,
                password: password
            )
            isAuthenticated = true
        } catch {
            print("[AuthViewModel] signUp error: \(error)")
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func checkExistingSession() {
        guard !ProcessInfo.processInfo.arguments.contains("-uitesting") else { return }
        isAuthenticated = (try? KeychainService.shared.readToken()) != nil
    }
}
