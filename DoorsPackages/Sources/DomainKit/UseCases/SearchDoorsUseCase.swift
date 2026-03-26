import Foundation

public struct SearchDoorsUseCase: Sendable {
    private let repository: any DoorsRepository

    public init(repository: any DoorsRepository) {
        self.repository = repository
    }

    public func execute(name: String, page: Int, size: Int = 20) async throws -> PaginatedResponse<Door> {
        try await repository.searchDoors(name: name, page: page, size: size)
    }
}
