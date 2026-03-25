import Foundation

public struct FetchEventsUseCase: Sendable {
    private let repository: any EventsRepository

    public init(repository: any EventsRepository) {
        self.repository = repository
    }

    public func execute(doorId: String) async throws -> [DoorEvent] {
        try await repository.fetchEvents(doorId: doorId)
    }
}
