import Foundation

public struct SearchDoorsUseCase: Sendable {
    private let repository: any DoorsRepository

    public init(repository: any DoorsRepository) {
        self.repository = repository
    }

    public func execute(query: String, page: Int, limit: Int = 20) async throws -> PaginatedResponse<Door> {
        try await repository.searchDoors(query: query, page: page, limit: limit)
    }
}
