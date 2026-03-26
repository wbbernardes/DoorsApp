import Foundation

public protocol DoorsRepository: Sendable {
    func fetchDoors(page: Int, size: Int) async throws -> PaginatedResponse<Door>
    func searchDoors(name: String, page: Int, size: Int) async throws -> PaginatedResponse<Door>
}
