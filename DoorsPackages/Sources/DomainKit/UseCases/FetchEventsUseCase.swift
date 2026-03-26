import Foundation

public struct FetchEventsUseCase: Sendable {
    private let repository: any EventsRepository

    public init(repository: any EventsRepository) {
        self.repository = repository
    }

    public func execute(doorId: String, page: Int = 0, size: Int = 20) async throws -> PaginatedResponse<DoorEvent> {
        try await repository.fetchEvents(doorId: doorId, page: page, size: size)
    }
}
