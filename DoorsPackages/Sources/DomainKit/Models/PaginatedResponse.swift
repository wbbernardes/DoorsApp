import Foundation

public struct PaginatedResponse<T: Decodable & Sendable>: Decodable, Sendable {
    public let data: [T]
    public let total: Int
    public let page: Int
    public let limit: Int

    public var hasMore: Bool { page * limit < total }
}
