import Foundation

public struct ParseBLEFrameUseCase: Sendable {
    /// BLE epoch: 2026-01-01T00:00:00Z
    private static let bleEpoch: TimeInterval = 1_767_225_600

    public init() {}

    public func execute(base64 raw: String) throws -> BLEFrame {
        guard let data = Data(base64Encoded: raw), data.count >= 5 else {
            throw BLEParseError.invalidFrame
        }
        let tsRaw = data[0 ..< 4].withUnsafeBytes { $0.load(as: UInt32.self) }.littleEndian
        let timestamp = Date(timeIntervalSince1970: Self.bleEpoch + TimeInterval(tsRaw))
        let logCode = data[4]
        let payloadLen = Int((logCode >> 4) & 0x0F)
        guard data.count >= 5 + payloadLen else { throw BLEParseError.truncatedPayload }
        let payload = Data(data[5 ..< (5 + payloadLen)])

        return try parseFrame(logCode: logCode, timestamp: timestamp, payload: payload)
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func parseFrame(logCode: UInt8, timestamp: Date, payload: Data) throws -> BLEFrame {
        switch logCode {
        // MARK: 0-byte events

        case 0x00: return .init(timestamp: timestamp, logCode: logCode, eventType: .setup, parsedValue: nil)
        case 0x01: return .init(timestamp: timestamp, logCode: logCode, eventType: .doorOpen, parsedValue: nil)
        case 0x02: return .init(timestamp: timestamp, logCode: logCode, eventType: .doorClose, parsedValue: nil)
        case 0x03: return .init(timestamp: timestamp, logCode: logCode, eventType: .touchUnlock, parsedValue: nil)
        case 0x06: return .init(timestamp: timestamp, logCode: logCode, eventType: .scheduleStart, parsedValue: nil)
        case 0x07: return .init(timestamp: timestamp, logCode: logCode, eventType: .scheduleFinish, parsedValue: nil)
        case 0x08: return .init(timestamp: timestamp, logCode: logCode, eventType: .scheduleTouchCancel, parsedValue: nil)
        case 0x09: return .init(timestamp: timestamp, logCode: logCode, eventType: .manufacture, parsedValue: nil)

        // MARK: 1-byte events
        case 0x10: return .init(timestamp: timestamp, logCode: logCode, eventType: .statusPrivate, parsedValue: "State(\(payload[0]))")
        case 0x11: return .init(timestamp: timestamp, logCode: logCode, eventType: .statusKey, parsedValue: "State(\(payload[0]))")
        case 0x12: return .init(timestamp: timestamp, logCode: logCode, eventType: .statusHalfOpen, parsedValue: "State(\(payload[0]))")
        case 0x13: return .init(timestamp: timestamp, logCode: logCode, eventType: .batteryLow, parsedValue: "Level(\(payload[0])%)")

        // MARK: 2-byte events
        case 0x20:
            let addr = readUInt16(payload)
            return .init(timestamp: timestamp, logCode: logCode, eventType: .eepromWriteError, parsedValue: "ErrorDescription(\(addr))")
        case 0x21:
            let addr = readUInt16(payload)
            return .init(timestamp: timestamp, logCode: logCode, eventType: .eepromCrcError, parsedValue: "ErrorDescription(\(addr))")

        // MARK: 4-byte events
        case 0x40:
            let uid = readUInt32(payload)
            return .init(timestamp: timestamp, logCode: logCode, eventType: .configuration, parsedValue: "UserId(\(uid))")
        case 0x42:
            let uid = readUInt32(payload)
            return .init(timestamp: timestamp, logCode: logCode, eventType: .scheduleCancel, parsedValue: "UserId(\(uid))")
        case 0x43:
            let uid = readUInt32(payload)
            return .init(timestamp: timestamp, logCode: logCode, eventType: .reset, parsedValue: "UserId(\(uid))")
        case 0x44:
            let uid = readUInt32(payload)
            return .init(timestamp: timestamp, logCode: logCode, eventType: .statusDfu, parsedValue: "UserId(\(uid))")
        case 0x45:
            let gap = readUInt32(payload)
            return .init(timestamp: timestamp, logCode: logCode, eventType: .logFull, parsedValue: "Gap(\(gap))")
        case 0x46:
            let code = readUInt32(payload)
            return .init(timestamp: timestamp, logCode: logCode, eventType: .error, parsedValue: "ErrorDescription(\(code))")
        case 0x47:
            let code = readUInt32(payload)
            return .init(timestamp: timestamp, logCode: logCode, eventType: .systemError, parsedValue: "ErrorDescription(\(code))")

        // MARK: 5-byte UNLOCK / UNLOCK_DENIED
        case 0x50, 0x51:
            let mode = payload[0]
            let permId = readUInt32(payload[1...])
            let eventType: BLEEventType = logCode == 0x50 ? .unlock : .unlockDenied
            let modeName = BLEPermissionMode(rawValue: mode).map { "\($0)" } ?? "Unknown"
            return .init(timestamp: timestamp, logCode: logCode, eventType: eventType, parsedValue: "Mode(\(modeName)) PermId(\(permId))")

        // MARK: 12-byte SCHEDULE_INIT
        case 0xC0:
            let userId = readUInt32(payload[0...])
            let start = readUInt32(payload[4...])
            let end = readUInt32(payload[8...])
            return .init(timestamp: timestamp, logCode: logCode, eventType: .scheduleInit,
                         parsedValue: "UserId(\(userId)) Start(\(start)) End(\(end))")
        default:
            return .init(timestamp: timestamp, logCode: logCode, eventType: .unknown, parsedValue: nil)
        }
    }

    private func readUInt16(_ data: Data) -> UInt16 {
        data.withUnsafeBytes { $0.loadUnaligned(as: UInt16.self) }.littleEndian
    }

    private func readUInt32(_ data: Data) -> UInt32 {
        data.withUnsafeBytes { $0.loadUnaligned(as: UInt32.self) }.littleEndian
    }
}

public enum BLEParseError: Error, LocalizedError {
    case invalidFrame
    case truncatedPayload

    public var errorDescription: String? {
        switch self {
        case .invalidFrame: "Invalid or empty BLE frame."
        case .truncatedPayload: "Frame payload is shorter than expected."
        }
    }
}
