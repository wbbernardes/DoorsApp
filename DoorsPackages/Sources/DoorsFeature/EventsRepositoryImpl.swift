import CoreNetwork
import DomainKit

public struct EventsRepositoryImpl: EventsRepository {
    private let client: APIClient

    public init(client: APIClient = .shared) {
        self.client = client
    }

    public func fetchEvents(doorId: String) async throws -> [DoorEvent] {
        let response: EventsResponse = try await client.request(.events(doorId: doorId))
        return response.data
    }

    public func fetchRawEvents(doorId: String) async throws -> [String] {
        let response: RawEventsResponse = try await client.request(.rawEvents(doorId: doorId))
        return response.data
    }
}

private struct EventsResponse: Decodable, Sendable {
    let data: [DoorEvent]
}

private struct RawEventsResponse: Decodable, Sendable {
    let data: [String]
}
