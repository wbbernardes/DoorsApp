import Foundation

public protocol EventsRepository: Sendable {
    func fetchEvents(doorId: String) async throws -> [DoorEvent]
    func fetchRawEvents(doorId: String) async throws -> [String]
}
