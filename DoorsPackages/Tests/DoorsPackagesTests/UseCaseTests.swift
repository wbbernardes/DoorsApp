import CoreNetwork
import Foundation
@testable import DomainKit
import Testing

// MARK: - FetchDoorsUseCase

@Suite("FetchDoorsUseCase")
struct FetchDoorsUseCaseTests {
    @Test func execute_returnsDoors() async throws {
        let door = Door.stub(id: 1, name: "Front Door")
        let repo = MockDoorsRepository(
            response: PaginatedResponse(content: [door], page: 0, totalPages: 2)
        )
        let useCase = FetchDoorsUseCase(repository: repo)

        let result = try await useCase.execute(page: 0, size: 20)

        #expect(result.content.count == 1)
        #expect(result.content[0].id == 1)
        #expect(result.hasMore == true)
    }

    @Test func execute_propagatesError() async throws {
        let repo = MockDoorsRepository(fetchError: .unauthorized)
        let useCase = FetchDoorsUseCase(repository: repo)

        var threwNetworkError = false
        do {
            _ = try await useCase.execute(page: 0, size: 20)
        } catch is NetworkError {
            threwNetworkError = true
        }
        #expect(threwNetworkError)
    }

    @Test func execute_emptyResult() async throws {
        let repo = MockDoorsRepository(
            response: PaginatedResponse(content: [], page: 0, totalPages: 1)
        )
        let useCase = FetchDoorsUseCase(repository: repo)

        let result = try await useCase.execute(page: 0, size: 20)

        #expect(result.content.isEmpty)
        #expect(result.hasMore == false)
    }
}

// MARK: - SearchDoorsUseCase

@Suite("SearchDoorsUseCase")
struct SearchDoorsUseCaseTests {
    @Test func execute_returnsMatchingDoors() async throws {
        let door = Door.stub(id: 2, name: "Back Door")
        let repo = MockDoorsRepository(
            searchResponse: PaginatedResponse(content: [door], page: 0, totalPages: 1)
        )
        let useCase = SearchDoorsUseCase(repository: repo)

        let result = try await useCase.execute(name: "Back", page: 0, size: 20)

        #expect(result.content.count == 1)
        #expect(result.content[0].name == "Back Door")
    }

    @Test func execute_propagatesError() async throws {
        let repo = MockDoorsRepository(searchError: .noToken)
        let useCase = SearchDoorsUseCase(repository: repo)

        var threwNetworkError = false
        do {
            _ = try await useCase.execute(name: "X", page: 0, size: 20)
        } catch is NetworkError {
            threwNetworkError = true
        }
        #expect(threwNetworkError)
    }
}

// MARK: - FetchEventsUseCase

@Suite("FetchEventsUseCase")
struct FetchEventsUseCaseTests {
    @Test func execute_returnsEvents() async throws {
        let event = DoorEvent.stub(id: 10, logType: "DOOR_OPEN")
        let repo = MockEventsRepository(
            eventsResponse: PaginatedResponse(content: [event], page: 0, totalPages: 1)
        )
        let useCase = FetchEventsUseCase(repository: repo)

        let result = try await useCase.execute(doorId: "door-1")

        #expect(result.content.count == 1)
        #expect(result.content[0].logType == "DOOR_OPEN")
    }

    @Test func execute_propagatesError() async throws {
        let repo = MockEventsRepository(eventsError: .unauthorized)
        let useCase = FetchEventsUseCase(repository: repo)

        var threwNetworkError = false
        do {
            _ = try await useCase.execute(doorId: "door-1")
        } catch is NetworkError {
            threwNetworkError = true
        }
        #expect(threwNetworkError)
    }

    @Test func execute_usesDefaultPagination() async throws {
        let repo = MockEventsRepository()
        let useCase = FetchEventsUseCase(repository: repo)

        // Verify execute with only doorId compiles and runs without error (default page=0, size=20)
        let result = try await useCase.execute(doorId: "any-door")
        #expect(result.content.isEmpty)
    }
}

// MARK: - SignInUseCase

@Suite("SignInUseCase")
struct SignInUseCaseTests {
    @Test func execute_savesTokenToKeychain() async throws {
        let repo = MockAuthRepository(token: AuthToken(token: "jwt-xyz"))
        let keychain = MockKeychainService()
        let useCase = SignInUseCase(repository: repo, keychain: keychain)

        try await useCase.execute(email: "user@test.com", password: "Pass1!")

        let saved = try keychain.readToken()
        #expect(saved == "jwt-xyz")
    }

    @Test func execute_propagatesRepositoryError() async throws {
        let repo = MockAuthRepository(signInError: .unauthorized)
        let useCase = SignInUseCase(repository: repo, keychain: MockKeychainService())

        var threwNetworkError = false
        do {
            try await useCase.execute(email: "user@test.com", password: "wrong")
        } catch is NetworkError {
            threwNetworkError = true
        }
        #expect(threwNetworkError)
    }
}

// MARK: - SignUpUseCase

@Suite("SignUpUseCase")
struct SignUpUseCaseTests {
    @Test func execute_signUpThenSignIn_savesToken() async throws {
        let repo = MockAuthRepository(token: AuthToken(token: "new-token"))
        let keychain = MockKeychainService()
        let useCase = SignUpUseCase(repository: repo, keychain: keychain)

        try await useCase.execute(firstName: "John", lastName: "Doe", email: "john@test.com", password: "Pass1!")

        let saved = try keychain.readToken()
        #expect(saved == "new-token")
    }

    @Test func execute_propagatesSignUpError() async throws {
        let repo = MockAuthRepository(signUpError: .httpError(statusCode: 409, data: Data()))
        let useCase = SignUpUseCase(repository: repo, keychain: MockKeychainService())

        var threwNetworkError = false
        do {
            try await useCase.execute(firstName: "J", lastName: "D", email: "j@test.com", password: "Pass1!")
        } catch is NetworkError {
            threwNetworkError = true
        }
        #expect(threwNetworkError)
    }

    @Test func execute_propagatesSignInError_afterSuccessfulSignUp() async throws {
        let repo = MockAuthRepository(signInError: .unauthorized)
        let useCase = SignUpUseCase(repository: repo, keychain: MockKeychainService())

        var threwNetworkError = false
        do {
            try await useCase.execute(firstName: "J", lastName: "D", email: "j@test.com", password: "Pass1!")
        } catch is NetworkError {
            threwNetworkError = true
        }
        #expect(threwNetworkError)
    }
}
