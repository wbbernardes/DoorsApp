import Foundation

public enum Endpoint {
    // Auth
    case signUp(firstName: String, lastName: String, email: String, password: String)
    case signIn(email: String, password: String)
    // Doors
    case doors(page: Int, size: Int)
    case findDoors(name: String, page: Int, size: Int)
    // Events
    case events(doorId: String, page: Int, size: Int)
    case rawEvents(doorId: String, page: Int, size: Int, debug: Bool)
    case simulateEvent(debug: Bool)

    public var path: String {
        switch self {
        case .signUp: "/users/signup"
        case .signIn: "/users/signin"
        case .doors: "/doors"
        case .findDoors: "/doors/find"
        case let .events(id, _, _): "/doors/\(id)/events"
        case let .rawEvents(id, _, _, _): "/doors/\(id)/events/raw"
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
        case let .doors(page, size):
            [.init(name: "page", value: "\(page)"), .init(name: "size", value: "\(size)")]
        case let .findDoors(name, page, size):
            [.init(name: "name", value: name), .init(name: "page", value: "\(page)"), .init(name: "size", value: "\(size)")]
        case let .events(_, page, size):
            [.init(name: "page", value: "\(page)"), .init(name: "size", value: "\(size)"), .init(name: "sort", value: "eventTimestamp,desc")]
        case let .rawEvents(_, page, size, debug):
            [.init(name: "page", value: "\(page)"), .init(name: "size", value: "\(size)"), .init(name: "debug", value: "\(debug)")]
        case let .simulateEvent(debug):
            [.init(name: "debug", value: "\(debug)")]
        default:
            nil
        }
    }

    public var body: Encodable? {
        switch self {
        case let .signUp(firstName, lastName, email, password):
            SignUpRequestBody(firstName: firstName, lastName: lastName, email: email, password: password)
        case let .signIn(email, password):
            SignInRequestBody(email: email, password: password)
        default:
            nil
        }
    }
}

// MARK: - Internal request body types

private struct SignUpRequestBody: Encodable {
    let firstName: String
    let lastName: String
    let email: String
    let password: String
}

private struct SignInRequestBody: Encodable {
    let email: String
    let password: String
}
