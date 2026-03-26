import CoreNetwork
import DomainKit

struct DoorsRepositoryImpl: DoorsRepository {
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func fetchDoors(page: Int, size: Int) async throws -> PaginatedResponse<Door> {
        try await client.request(.doors(page: page, size: size))
    }

    func searchDoors(name: String, page: Int, size: Int) async throws -> PaginatedResponse<Door> {
        try await client.request(.findDoors(name: name, page: page, size: size))
    }
}
