import Foundation

public struct Door: Decodable, Identifiable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let description: String?
    public let status: String?
}
