import BLEKit
import CoreNetwork
@testable import DomainKit
import Foundation

// MARK: - MockAuthRepository

struct MockAuthRepository: AuthRepository {
    let token: AuthToken
    let user: CreatedUser
    let signInError: NetworkError?
    let signUpError: NetworkError?

    init(
        token: AuthToken = AuthToken(token: "test-token"),
        user: CreatedUser = CreatedUser(id: 1, firstName: "Test", lastName: "User", email: "test@test.com"),
        signInError: NetworkError? = nil,
        signUpError: NetworkError? = nil
    ) {
        self.token = token
        self.user = user
        self.signInError = signInError
        self.signUpError = signUpError
    }

    func signIn(email _: String, password _: String) async throws -> AuthToken {
        if let error = signInError { throw error }
        return token
    }

    func signUp(firstName _: String, lastName _: String, email _: String, password _: String) async throws -> CreatedUser {
        if let error = signUpError { throw error }
        return user
    }
}

// MARK: - MockDoorsRepository

struct MockDoorsRepository: DoorsRepository {
    let response: PaginatedResponse<Door>
    let searchResponse: PaginatedResponse<Door>
    let fetchError: NetworkError?
    let searchError: NetworkError?

    init(
        response: PaginatedResponse<Door> = PaginatedResponse(content: [], page: 0, totalPages: 1),
        searchResponse: PaginatedResponse<Door>? = nil,
        fetchError: NetworkError? = nil,
        searchError: NetworkError? = nil
    ) {
        self.response = response
        self.searchResponse = searchResponse ?? response
        self.fetchError = fetchError
        self.searchError = searchError
    }

    func fetchDoors(page _: Int, size _: Int) async throws -> PaginatedResponse<Door> {
        if let error = fetchError { throw error }
        return response
    }

    func searchDoors(name _: String, page _: Int, size _: Int) async throws -> PaginatedResponse<Door> {
        if let error = searchError { throw error }
        return searchResponse
    }
}

// MARK: - MockEventsRepository

struct MockEventsRepository: EventsRepository {
    let eventsResponse: PaginatedResponse<DoorEvent>
    let rawResponse: PaginatedResponse<RawEventItem>
    let eventsError: NetworkError?
    let rawError: NetworkError?

    init(
        eventsResponse: PaginatedResponse<DoorEvent> = PaginatedResponse(content: [], page: 0, totalPages: 1),
        rawResponse: PaginatedResponse<RawEventItem> = PaginatedResponse(content: [], page: 0, totalPages: 1),
        eventsError: NetworkError? = nil,
        rawError: NetworkError? = nil
    ) {
        self.eventsResponse = eventsResponse
        self.rawResponse = rawResponse
        self.eventsError = eventsError
        self.rawError = rawError
    }

    func fetchEvents(doorId _: String, page _: Int, size _: Int) async throws -> PaginatedResponse<DoorEvent> {
        if let error = eventsError { throw error }
        return eventsResponse
    }

    func fetchRawEvents(doorId _: String, page _: Int, size _: Int, debug _: Bool) async throws -> PaginatedResponse<RawEventItem> {
        if let error = rawError { throw error }
        return rawResponse
    }
}

// MARK: - MockFeatureFlagService

struct MockFeatureFlagService: FeatureFlagServiceProtocol {
    let enabledFlags: Set<FeatureFlag>
    let stringValues: [FeatureFlag: String]

    init(enabledFlags: Set<FeatureFlag> = [], stringValues: [FeatureFlag: String] = [:]) {
        self.enabledFlags = enabledFlags
        self.stringValues = stringValues
    }

    func isEnabled(_ flag: FeatureFlag) async -> Bool {
        enabledFlags.contains(flag)
    }

    func stringValue(for flag: FeatureFlag) async -> String {
        stringValues[flag] ?? ""
    }
}

// MARK: - MockKeychainService

final class MockKeychainService: @unchecked Sendable, KeychainServiceProtocol {
    private var storedToken: String?

    func save(token: String) throws {
        storedToken = token
    }

    func readToken() throws -> String {
        guard let token = storedToken else { throw NetworkError.noToken }
        return token
    }

    func deleteToken() {
        storedToken = nil
    }
}

// MARK: - Helpers

extension Door {
    static func stub(id: Int = 1, name: String = "Front Door") -> Door {
        Door(id: id, name: name, serial: nil, lockMac: nil, address: nil, latitude: nil, longitude: nil, battery: nil)
    }
}

extension DoorEvent {
    static func stub(id: Int = 1, logType: String = "DOOR_OPEN") -> DoorEvent {
        DoorEvent(id: id, logType: logType, eventTimestamp: .now, additionalData: [])
    }
}

extension BLEFrame {
    static func stub(eventType: BLEEventType, logCode: UInt8 = 0x01) -> BLEFrame {
        BLEFrame(timestamp: .now, logCode: logCode, eventType: eventType, parsedValue: nil)
    }
}
