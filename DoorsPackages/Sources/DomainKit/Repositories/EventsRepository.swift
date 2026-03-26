import Foundation

public protocol EventsRepository: Sendable {
    func fetchEvents(doorId: String, page: Int, size: Int) async throws -> PaginatedResponse<DoorEvent>
    func fetchRawEvents(doorId: String, page: Int, size: Int, debug: Bool) async throws
        -> PaginatedResponse<RawEventItem>
}
