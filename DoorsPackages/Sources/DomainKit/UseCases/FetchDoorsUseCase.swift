import Foundation

public struct FetchDoorsUseCase: Sendable {
    private let repository: any DoorsRepository

    public init(repository: any DoorsRepository) {
        self.repository = repository
    }

    public func execute(page: Int, size: Int = 20) async throws -> PaginatedResponse<Door> {
        try await repository.fetchDoors(page: page, size: size)
    }
}
