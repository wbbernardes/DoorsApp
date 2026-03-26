import Foundation

public struct PaginatedResponse<T: Decodable & Sendable>: Decodable, Sendable {
    public let content: [T]
    public let page: Int
    public let totalPages: Int

    public var hasMore: Bool {
        page + 1 < totalPages
    }
}
