@testable import AuthFeature
import Foundation
import CoreNetwork
@testable import DomainKit
import Testing

@Suite("AuthViewModel")
@MainActor
struct AuthViewModelTests {
    // MARK: - Helpers

    private func makeVM(
        signInError: NetworkError? = nil,
        signUpError: NetworkError? = nil,
        token: String = "test-token"
    ) -> AuthViewModel {
        let repo = MockAuthRepository(
            token: AuthToken(token: token),
            signInError: signInError,
            signUpError: signUpError
        )
        let keychain = MockKeychainService()
        return AuthViewModel(
            signInUseCase: SignInUseCase(repository: repo, keychain: keychain),
            signUpUseCase: SignUpUseCase(repository: repo, keychain: keychain)
        )
    }

    // MARK: - Email Validation

    @Test func isEmailValid_validEmail() {
        let vm = makeVM()
        vm.email = "user@example.com"
        #expect(vm.isEmailValid == true)
    }

    @Test func isEmailValid_missingAt() {
        let vm = makeVM()
        vm.email = "userexample.com"
        #expect(vm.isEmailValid == false)
    }

    @Test func isEmailValid_missingDot() {
        let vm = makeVM()
        vm.email = "user@example"
        #expect(vm.isEmailValid == false)
    }

    @Test func isEmailValid_empty() {
        let vm = makeVM()
        #expect(vm.isEmailValid == false)
    }

    // MARK: - Password Validation

    @Test func isPasswordValid_allRequirementsMet() {
        let vm = makeVM()
        vm.password = "Pass1!"
        #expect(vm.isPasswordValid == true)
    }

    @Test func isPasswordValid_tooShort() {
        let vm = makeVM()
        vm.password = "P1!"
        #expect(vm.isPasswordValid == false)
    }

    @Test func isPasswordValid_tooLong() {
        let vm = makeVM()
        vm.password = "Password123!XYZ" // > 12 chars
        #expect(vm.isPasswordValid == false)
    }

    @Test func isPasswordValid_noUppercase() {
        let vm = makeVM()
        vm.password = "pass1!"
        #expect(vm.isPasswordValid == false)
    }

    @Test func isPasswordValid_noNumber() {
        let vm = makeVM()
        vm.password = "Password!"
        #expect(vm.isPasswordValid == false)
    }

    @Test func isPasswordValid_noSymbol() {
        let vm = makeVM()
        vm.password = "Password1"
        #expect(vm.isPasswordValid == false)
    }

    @Test func isPasswordValid_exactlyFourChars() {
        let vm = makeVM()
        vm.password = "P1!x"
        #expect(vm.isPasswordValid == true)
    }

    @Test func isPasswordValid_exactlyTwelveChars() {
        let vm = makeVM()
        vm.password = "Password123!"
        #expect(vm.isPasswordValid == true)
    }

    // MARK: - Form Validation

    @Test func isSignInFormValid_bothFilled() {
        let vm = makeVM()
        vm.email = "user@test.com"
        vm.password = "Pass1!"
        #expect(vm.isSignInFormValid == true)
    }

    @Test func isSignInFormValid_emptyEmail() {
        let vm = makeVM()
        vm.password = "Pass1!"
        #expect(vm.isSignInFormValid == false)
    }

    @Test func isSignInFormValid_emptyPassword() {
        let vm = makeVM()
        vm.email = "user@test.com"
        #expect(vm.isSignInFormValid == false)
    }

    @Test func isSignUpFormValid_allValid() {
        let vm = makeVM()
        vm.firstName = "John"
        vm.lastName = "Doe"
        vm.email = "john@test.com"
        vm.password = "Pass1!"
        #expect(vm.isSignUpFormValid == true)
    }

    @Test func isSignUpFormValid_missingFirstName() {
        let vm = makeVM()
        vm.lastName = "Doe"
        vm.email = "john@test.com"
        vm.password = "Pass1!"
        #expect(vm.isSignUpFormValid == false)
    }

    @Test func isSignUpFormValid_missingLastName() {
        let vm = makeVM()
        vm.firstName = "John"
        vm.email = "john@test.com"
        vm.password = "Pass1!"
        #expect(vm.isSignUpFormValid == false)
    }

    @Test func isSignUpFormValid_invalidEmail() {
        let vm = makeVM()
        vm.firstName = "John"
        vm.lastName = "Doe"
        vm.email = "not-an-email"
        vm.password = "Pass1!"
        #expect(vm.isSignUpFormValid == false)
    }

    @Test func isSignUpFormValid_invalidPassword() {
        let vm = makeVM()
        vm.firstName = "John"
        vm.lastName = "Doe"
        vm.email = "john@test.com"
        vm.password = "weak"
        #expect(vm.isSignUpFormValid == false)
    }

    // MARK: - Sign Out

    @Test func signOut_clearsAllFields() {
        let vm = makeVM()
        vm.email = "user@test.com"
        vm.password = "Pass1!"
        vm.firstName = "John"
        vm.lastName = "Doe"

        vm.signOut()

        #expect(vm.isAuthenticated == false)
        #expect(vm.email.isEmpty)
        #expect(vm.password.isEmpty)
        #expect(vm.firstName.isEmpty)
        #expect(vm.lastName.isEmpty)
    }

    @Test func clearError_nilsErrorMessage() {
        let vm = makeVM()
        vm.errorMessage = "Something went wrong"
        vm.clearError()
        #expect(vm.errorMessage == nil)
    }

    @Test func handleUnauthorized_signsOut() {
        let vm = makeVM()
        vm.email = "user@test.com"

        vm.handleUnauthorized()

        #expect(vm.isAuthenticated == false)
        #expect(vm.email.isEmpty)
    }

    // MARK: - Sign In (async)

    @Test func onSignInTap_success_setsAuthenticated() async {
        let vm = makeVM(token: "fresh-token")
        vm.email = "user@test.com"
        vm.password = "Pass1!"

        vm.onSignInTap()
        // Yield to let the spawned Task execute through the async chain
        for _ in 0 ..< 5 {
            await Task.yield()
        }

        #expect(vm.isAuthenticated == true)
        #expect(vm.password.isEmpty) // cleared via defer
        #expect(vm.errorMessage == nil)
    }

    @Test func onSignInTap_failure_setsErrorMessage() async {
        let vm = makeVM(signInError: .unauthorized)
        vm.email = "user@test.com"
        vm.password = "Pass1!"

        vm.onSignInTap()
        for _ in 0 ..< 5 {
            await Task.yield()
        }

        #expect(vm.isAuthenticated == false)
        #expect(vm.errorMessage != nil)
        #expect(vm.password.isEmpty)
    }

    // MARK: - Sign Up (async)

    @Test func onSignUpTap_success_setsAuthenticated() async {
        let vm = makeVM()
        vm.firstName = "John"
        vm.lastName = "Doe"
        vm.email = "john@test.com"
        vm.password = "Pass1!"

        vm.onSignUpTap()
        for _ in 0 ..< 5 {
            await Task.yield()
        }

        #expect(vm.isAuthenticated == true)
        #expect(vm.password.isEmpty)
    }

    @Test func onSignUpTap_failure_setsErrorMessage() async {
        let vm = makeVM(signUpError: .httpError(statusCode: 409, data: Data()))
        vm.firstName = "John"
        vm.lastName = "Doe"
        vm.email = "john@test.com"
        vm.password = "Pass1!"

        vm.onSignUpTap()
        for _ in 0 ..< 5 {
            await Task.yield()
        }

        #expect(vm.isAuthenticated == false)
        #expect(vm.errorMessage != nil)
    }
}
