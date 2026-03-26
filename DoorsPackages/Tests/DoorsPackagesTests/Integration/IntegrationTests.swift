@testable import AuthFeature
@testable import CoreNetwork
@testable import DomainKit
@testable import DoorsFeature
@testable import EventsFeature
import Foundation
import Testing

// MARK: - Integration Tests

//
// All integration tests share MockURLProtocol's static handler, so they MUST run serially.
// The .serialized trait on the parent suite guarantees that nested suites also run serially,
// preventing handler bleed-through between concurrent tests.

@Suite("Integration", .serialized)
struct IntegrationTests {
    // MARK: - APIClient

    @Suite("APIClient")
    struct APIClientIntegrationTests {
        // MARK: Decoding

        @Test func request_200_decodesResponse() async throws {
            defer { MockURLProtocol.reset() }
            MockURLProtocol.stub(statusCode: 200, json: #"{"token":"jwt-abc"}"#)
            let client = makeTestClient()

            let result: AuthToken = try await client.request(.signIn(email: "a@b.com", password: "p"))

            #expect(result.token == "jwt-abc")
        }

        @Test func request_200_appliesSnakeCaseDecoding() async throws {
            defer { MockURLProtocol.reset() }
            let json = #"{"id":1,"first_name":"John","last_name":"Doe","email":"j@test.com"}"#
            MockURLProtocol.stub(statusCode: 200, json: json)
            let client = makeTestClient()

            let result: CreatedUser = try await client.request(
                .signUp(firstName: "John", lastName: "Doe", email: "j@test.com", password: "P1!")
            )

            #expect(result.firstName == "John")
            #expect(result.lastName == "Doe")
            #expect(result.id == 1)
        }

        // MARK: Error Classification

        @Test func request_401_throwsUnauthorized() async throws {
            defer { MockURLProtocol.reset() }
            MockURLProtocol.stub(statusCode: 401, json: #"{"error":"unauthorized"}"#)
            let client = makeTestClient()

            var caughtUnauthorized = false
            do {
                let _: AuthToken = try await client.request(.signIn(email: "a@b.com", password: "p"))
            } catch NetworkError.unauthorized {
                caughtUnauthorized = true
            }
            #expect(caughtUnauthorized)
        }

        @Test func request_401_clearsTokenFromKeychain() async throws {
            defer { MockURLProtocol.reset() }
            MockURLProtocol.stub(statusCode: 401, json: #"{}"#)
            let keychain = MockKeychainService()
            try keychain.save(token: "existing-token")
            let client = makeTestClient(keychain: keychain)

            _ = try? await client.request(.signIn(email: "a@b.com", password: "p")) as AuthToken

            var tokenCleared = false
            do { _ = try keychain.readToken() } catch NetworkError.noToken { tokenCleared = true }
            #expect(tokenCleared)
        }

        @Test func request_404_throwsHTTPError() async throws {
            defer { MockURLProtocol.reset() }
            MockURLProtocol.stub(statusCode: 404, json: #"{"message":"not found"}"#)
            let client = makeTestClient()

            var statusCode: Int?
            do {
                let _: AuthToken = try await client.request(.signIn(email: "a@b.com", password: "p"))
            } catch let NetworkError.httpError(code, _) {
                statusCode = code
            }
            #expect(statusCode == 404)
        }

        @Test func request_500_throwsHTTPError() async throws {
            defer { MockURLProtocol.reset() }
            MockURLProtocol.stub(statusCode: 500, json: #"{"error":"server error"}"#)
            let client = makeTestClient()

            var statusCode: Int?
            do {
                let _: AuthToken = try await client.request(.signIn(email: "a@b.com", password: "p"))
            } catch let NetworkError.httpError(code, _) {
                statusCode = code
            }
            #expect(statusCode == 500)
        }

        @Test func request_invalidJSON_throwsDecodingFailed() async throws {
            defer { MockURLProtocol.reset() }
            MockURLProtocol.stub(statusCode: 200, json: "not json at all")
            let client = makeTestClient()

            var caughtDecodingFailed = false
            do {
                let _: AuthToken = try await client.request(.signIn(email: "a@b.com", password: "p"))
            } catch NetworkError.decodingFailed {
                caughtDecodingFailed = true
            }
            #expect(caughtDecodingFailed)
        }

        // MARK: Bearer Token Injection

        @Test func request_injectsBearerTokenFromKeychain() async throws {
            defer { MockURLProtocol.reset() }
            MockURLProtocol.stub(statusCode: 200, json: #"{"token":"t"}"#)
            let keychain = MockKeychainService()
            try keychain.save(token: "my-jwt")
            let client = makeTestClient(keychain: keychain)

            let _: AuthToken = try await client.request(.signIn(email: "a@b.com", password: "p"))

            let authHeader = MockURLProtocol.lastRequest?.value(forHTTPHeaderField: "Authorization")
            #expect(authHeader == "Bearer my-jwt")
        }

        @Test func request_noTokenInKeychain_omitsAuthorizationHeader() async throws {
            defer { MockURLProtocol.reset() }
            MockURLProtocol.stub(statusCode: 200, json: #"{"token":"t"}"#)
            let client = makeTestClient(keychain: MockKeychainService())

            let _: AuthToken = try await client.request(.signIn(email: "a@b.com", password: "p"))

            let authHeader = MockURLProtocol.lastRequest?.value(forHTTPHeaderField: "Authorization")
            #expect(authHeader == nil)
        }

        // MARK: requestVoid

        @Test func requestVoid_200_succeeds() async throws {
            defer { MockURLProtocol.reset() }
            MockURLProtocol.stub(statusCode: 200, json: "")
            let client = makeTestClient()

            try await client.requestVoid(.simulateEvent(count: 1, logType: "DOOR_OPEN", debug: false))
        }

        @Test func requestVoid_400_throwsHTTPError() async throws {
            defer { MockURLProtocol.reset() }
            MockURLProtocol.stub(statusCode: 400, json: #"{"error":"bad request"}"#)
            let client = makeTestClient()

            var statusCode: Int?
            do {
                try await client.requestVoid(.simulateEvent(count: 1, logType: "DOOR_OPEN", debug: false))
            } catch let NetworkError.httpError(code, _) {
                statusCode = code
            }
            #expect(statusCode == 400)
        }
    }

    // MARK: - AuthRepository

    @Suite("AuthRepository")
    struct AuthRepositoryIntegrationTests {
        @Test func signIn_parsesTokenField() async throws {
            defer { MockURLProtocol.reset() }
            MockURLProtocol.stub(statusCode: 200, json: #"{"token":"jwt-integration"}"#)
            let repo = AuthRepositoryImpl(client: makeTestClient())

            let token = try await repo.signIn(email: "user@test.com", password: "Pass1!")

            #expect(token.token == "jwt-integration")
        }

        @Test func signUp_parsesCreatedUser_withSnakeCaseFields() async throws {
            defer { MockURLProtocol.reset() }
            let json = #"{"id":42,"first_name":"Jane","last_name":"Smith","email":"jane@test.com"}"#
            MockURLProtocol.stub(statusCode: 200, json: json)
            let repo = AuthRepositoryImpl(client: makeTestClient())

            let user = try await repo.signUp(
                firstName: "Jane", lastName: "Smith",
                email: "jane@test.com", password: "Pass1!"
            )

            #expect(user.id == 42)
            #expect(user.firstName == "Jane")
            #expect(user.lastName == "Smith")
            #expect(user.email == "jane@test.com")
        }

        @Test func signIn_401_throwsUnauthorized() async throws {
            defer { MockURLProtocol.reset() }
            MockURLProtocol.stub(statusCode: 401, json: #"{"error":"unauthorized"}"#)
            let repo = AuthRepositoryImpl(client: makeTestClient())

            var caughtUnauthorized = false
            do {
                _ = try await repo.signIn(email: "user@test.com", password: "wrong")
            } catch NetworkError.unauthorized {
                caughtUnauthorized = true
            }
            #expect(caughtUnauthorized)
        }

        @Test func signIn_409_throwsHTTPError() async throws {
            defer { MockURLProtocol.reset() }
            MockURLProtocol.stub(statusCode: 409, json: #"{"error":"conflict"}"#)
            let repo = AuthRepositoryImpl(client: makeTestClient())

            var statusCode: Int?
            do {
                _ = try await repo.signIn(email: "user@test.com", password: "Pass1!")
            } catch let NetworkError.httpError(code, _) {
                statusCode = code
            }
            #expect(statusCode == 409)
        }
    }

    // MARK: - DoorsRepository

    @Suite("DoorsRepository")
    struct DoorsRepositoryIntegrationTests {
        @Test func fetchDoors_parsesPaginatedResponse() async throws {
            defer { MockURLProtocol.reset() }
            let json = """
            {
              "content": [{
                "id": 7, "name": "Main Entrance", "serial": "SN-001",
                "lock_mac": "AA:BB:CC:DD", "address": "123 Main St",
                "latitude": 51.5, "longitude": -0.1, "battery": 85
              }],
              "page": 0, "total_pages": 3
            }
            """
            MockURLProtocol.stub(statusCode: 200, json: json)
            let repo = DoorsRepositoryImpl(client: makeTestClient())

            let result = try await repo.fetchDoors(page: 0, size: 20)

            #expect(result.content.count == 1)
            #expect(result.content[0].id == 7)
            #expect(result.content[0].name == "Main Entrance")
            #expect(result.content[0].lockMac == "AA:BB:CC:DD")
            #expect(result.content[0].battery == 85)
            #expect(result.totalPages == 3)
            #expect(result.hasMore == true)
        }

        @Test func fetchDoors_emptyContent_hasMoreIsFalse() async throws {
            defer { MockURLProtocol.reset() }
            MockURLProtocol.stub(statusCode: 200, json: #"{"content":[],"page":0,"total_pages":1}"#)
            let repo = DoorsRepositoryImpl(client: makeTestClient())

            let result = try await repo.fetchDoors(page: 0, size: 20)

            #expect(result.content.isEmpty)
            #expect(result.hasMore == false)
        }

        @Test func fetchDoors_sendsPageAndSizeQueryParams() async throws {
            defer { MockURLProtocol.reset() }
            MockURLProtocol.stub(statusCode: 200, json: #"{"content":[],"page":2,"total_pages":5}"#)
            let repo = DoorsRepositoryImpl(client: makeTestClient())

            _ = try await repo.fetchDoors(page: 2, size: 10)

            let url = MockURLProtocol.lastRequest?.url?.absoluteString ?? ""
            #expect(url.contains("page=2"))
            #expect(url.contains("size=10"))
        }

        @Test func searchDoors_sendsNameQueryParam() async throws {
            defer { MockURLProtocol.reset() }
            MockURLProtocol.stub(statusCode: 200, json: #"{"content":[],"page":0,"total_pages":1}"#)
            let repo = DoorsRepositoryImpl(client: makeTestClient())

            _ = try await repo.searchDoors(name: "garage", page: 0, size: 20)

            let url = MockURLProtocol.lastRequest?.url?.absoluteString ?? ""
            #expect(url.contains("name=garage"))
            #expect(url.contains("/doors/find"))
        }

        @Test func fetchDoors_nullableFieldsDecodeAsNil() async throws {
            defer { MockURLProtocol.reset() }
            let json = #"{"content":[{"id":1,"name":"X","serial":null,"lock_mac":null,"address":null,"latitude":null,"longitude":null,"battery":null}],"page":0,"total_pages":1}"#
            MockURLProtocol.stub(statusCode: 200, json: json)
            let repo = DoorsRepositoryImpl(client: makeTestClient())

            let result = try await repo.fetchDoors(page: 0, size: 20)

            let door = try #require(result.content.first)
            #expect(door.serial == nil)
            #expect(door.lockMac == nil)
            #expect(door.battery == nil)
        }
    }

    // MARK: - EventsRepository

    @Suite("EventsRepository")
    struct EventsRepositoryIntegrationTests {
        @Test func fetchEvents_parsesCustomDateFormat_withoutTimezone() async throws {
            defer { MockURLProtocol.reset() }
            let json = """
            {
              "content": [{
                "id": 10, "log_type": "DOOR_OPEN",
                "event_timestamp": "2025-06-12T14:32:00",
                "additional_data": []
              }],
              "page": 0, "total_pages": 1
            }
            """
            MockURLProtocol.stub(statusCode: 200, json: json)
            let repo = EventsRepositoryImpl(client: makeTestClient())

            let result = try await repo.fetchEvents(doorId: "door-1", page: 0, size: 20)

            #expect(result.content.count == 1)
            #expect(result.content[0].logType == "DOOR_OPEN")
            let year = Calendar.current.component(.year, from: result.content[0].eventTimestamp)
            #expect(year == 2025)
        }

        @Test func fetchEvents_parsesISO8601DateFormat_withTimezone() async throws {
            defer { MockURLProtocol.reset() }
            let json = """
            {
              "content": [{
                "id": 11, "log_type": "DOOR_CLOSE",
                "event_timestamp": "2025-06-12T14:32:00Z",
                "additional_data": [
                  {"parameter_name": "battery", "hex_value": "0A", "parsed_value": "10%"}
                ]
              }],
              "page": 0, "total_pages": 1
            }
            """
            MockURLProtocol.stub(statusCode: 200, json: json)
            let repo = EventsRepositoryImpl(client: makeTestClient())

            let result = try await repo.fetchEvents(doorId: "door-2", page: 0, size: 20)

            let event = try #require(result.content.first)
            #expect(event.logType == "DOOR_CLOSE")
            #expect(event.additionalData[0].parameterName == "battery")
            #expect(event.additionalData[0].parsedValue == "10%")
        }

        @Test func fetchEvents_sendsCorrectPathAndQueryParams() async throws {
            defer { MockURLProtocol.reset() }
            MockURLProtocol.stub(statusCode: 200, json: #"{"content":[],"page":0,"total_pages":1}"#)
            let repo = EventsRepositoryImpl(client: makeTestClient())

            _ = try await repo.fetchEvents(doorId: "abc-123", page: 1, size: 15)

            let url = MockURLProtocol.lastRequest?.url?.absoluteString ?? ""
            #expect(url.contains("/doors/abc-123/events"))
            #expect(url.contains("page=1"))
            #expect(url.contains("size=15"))
            #expect(url.contains("sort=eventTimestamp"))
        }

        @Test func fetchRawEvents_parsesPaginatedRawEventItems() async throws {
            defer { MockURLProtocol.reset() }
            let json = """
            {
              "content": [{
                "message_key": "msg-001",
                "log_event": "BASE64DATA==",
                "parsed_event": {
                  "log_type": "DOOR_OPEN",
                  "additional_data": [{"parameter_name": "p", "hex_value": null, "parsed_value": "v"}]
                }
              }],
              "page": 0, "total_pages": 1
            }
            """
            MockURLProtocol.stub(statusCode: 200, json: json)
            let repo = EventsRepositoryImpl(client: makeTestClient())

            let result = try await repo.fetchRawEvents(doorId: "door-1", page: 0, size: 20, debug: true)

            #expect(result.content.count == 1)
            #expect(result.content[0].messageKey == "msg-001")
            #expect(result.content[0].parsedEvent?.logType == "DOOR_OPEN")
        }
    }
}
