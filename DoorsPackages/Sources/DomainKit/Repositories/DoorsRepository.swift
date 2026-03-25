import Foundation

public protocol DoorsRepository: Sendable {
    func fetchDoors(page: Int, limit: Int) async throws -> PaginatedResponse<Door>
    func searchDoors(query: String, page: Int, limit: Int) async throws -> PaginatedResponse<Door>
}
