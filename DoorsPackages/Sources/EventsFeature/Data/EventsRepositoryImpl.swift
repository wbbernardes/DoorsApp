import CoreNetwork
import DomainKit

struct EventsRepositoryImpl: EventsRepository {
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func fetchEvents(doorId: String, page: Int, size: Int) async throws -> PaginatedResponse<DoorEvent> {
        try await client.request(.events(doorId: doorId, page: page, size: size))
    }

    func fetchRawEvents(doorId: String, page: Int, size: Int, debug: Bool) async throws
        -> PaginatedResponse<RawEventItem> {
        try await client.request(.rawEvents(doorId: doorId, page: page, size: size, debug: debug))
    }
}
