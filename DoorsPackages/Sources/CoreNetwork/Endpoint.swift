import Foundation

public enum Endpoint {
    // Auth
    case signUp(SignUpRequestBody)
    case signIn(SignInRequestBody)
    // Doors
    case doors(page: Int, limit: Int)
    case findDoors(query: String, page: Int, limit: Int)
    // Events
    case events(doorId: String)
    case rawEvents(doorId: String)
    case simulateEvent(debug: Bool)

    public var path: String {
        switch self {
        case .signUp: "/users/signup"
        case .signIn: "/users/signin"
        case .doors: "/doors"
        case .findDoors: "/doors/find"
        case .events(let id): "/doors/\(id)/events"
        case .rawEvents(let id): "/doors/\(id)/events/raw"
        case .simulateEvent: "/doors/events/simulate"
        }
    }

    public var method: String {
        switch self {
        case .signUp, .signIn: "POST"
        default: "GET"
        }
    }

    public var queryItems: [URLQueryItem]? {
        switch self {
        case .doors(let page, let limit):
            [.init(name: "page", value: "\(page)"), .init(name: "limit", value: "\(limit)")]
        case .findDoors(let query, let page, let limit):
            [.init(name: "name", value: query), .init(name: "page", value: "\(page)"), .init(name: "limit", value: "\(limit)")]
        case .simulateEvent(let debug):
            [.init(name: "debug", value: "\(debug)")]
        default:
            nil
        }
    }

    public var body: Encodable? {
        switch self {
        case .signUp(let b): b
        case .signIn(let b): b
        default: nil
        }
    }
}

public struct SignUpRequestBody: Encodable, Sendable {
    public let name: String
    public let email: String
    public let password: String
    public init(name: String, email: String, password: String) {
        self.name = name; self.email = email; self.password = password
    }
}

public struct SignInRequestBody: Encodable, Sendable {
    public let email: String
    public let password: String
    public init(email: String, password: String) {
        self.email = email; self.password = password
    }
}
