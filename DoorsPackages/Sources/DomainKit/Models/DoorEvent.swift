import Foundation

public struct DoorEvent: Decodable, Identifiable, Sendable {
    public let id: Int
    public let logType: String
    public let eventTimestamp: Date
    public let additionalData: [EventParameter]

    public init(id: Int, logType: String, eventTimestamp: Date, additionalData: [EventParameter]) {
        self.id = id
        self.logType = logType
        self.eventTimestamp = eventTimestamp
        self.additionalData = additionalData
    }
}

public struct EventParameter: Decodable, Sendable {
    public let parameterName: String
    public let hexValue: String?
    public let parsedValue: String?

    public init(parameterName: String, hexValue: String?, parsedValue: String?) {
        self.parameterName = parameterName
        self.hexValue = hexValue
        self.parsedValue = parsedValue
    }
}

public struct RawEventItem: Decodable, Sendable {
    public let messageKey: String
    public let logEvent: String
    public let parsedEvent: ParsedEventDebug?
}

public struct ParsedEventDebug: Decodable, Sendable {
    public let logType: String
    public let additionalData: [DebugParameter]
}

public struct DebugParameter: Decodable, Sendable {
    public let parameterName: String
    public let hexValue: String?
    public let parsedValue: String?
}
