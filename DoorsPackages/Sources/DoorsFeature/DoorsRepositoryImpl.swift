import CoreNetwork
import DomainKit

public struct DoorsRepositoryImpl: DoorsRepository {
    private let client: APIClient

    public init(client: APIClient = .shared) {
        self.client = client
    }

    public func fetchDoors(page: Int, limit: Int) async throws -> PaginatedResponse<Door> {
        try await client.request(.doors(page: page, limit: limit))
    }

    public func searchDoors(query: String, page: Int, limit: Int) async throws -> PaginatedResponse<Door> {
        try await client.request(.findDoors(query: query, page: page, limit: limit))
    }
}
