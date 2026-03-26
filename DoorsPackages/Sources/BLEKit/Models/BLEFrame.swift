import Foundation

public struct BLEFrame: Identifiable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let logCode: UInt8
    public let eventType: BLEEventType
    public let parsedValue: String?

    public init(timestamp: Date, logCode: UInt8, eventType: BLEEventType, parsedValue: String?) {
        id = UUID()
        self.timestamp = timestamp
        self.logCode = logCode
        self.eventType = eventType
        self.parsedValue = parsedValue
    }

    public var displayTitle: String {
        eventType.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }

    public var displayCode: String {
        String(format: "0x%02X", logCode)
    }
}

public enum BLEEventType: String, Sendable {
    // 0-byte
    case setup = "SETUP"
    case doorOpen = "DOOR_OPEN"
    case doorClose = "DOOR_CLOSE"
    case touchUnlock = "TOUCH_UNLOCK"
    case scheduleStart = "SCHEDULE_START"
    case scheduleFinish = "SCHEDULE_FINISH"
    case scheduleTouchCancel = "SCHEDULE_TOUCH_CANCEL"
    case manufacture = "MANUFACTURE"
    // 1-byte
    case statusPrivate = "STATUS_PRIVATE"
    case statusKey = "STATUS_KEY"
    case statusHalfOpen = "STATUS_HALF_OPEN"
    case batteryLow = "BATTERY_LOW"
    // 2-byte
    case eepromWriteError = "EEPROM_WRITE_ERROR"
    case eepromCrcError = "EEPROM_CRC_ERROR"
    // 4-byte
    case configuration = "CONFIGURATION"
    case scheduleCancel = "SCHEDULE_CANCEL"
    case reset = "RESET"
    case statusDfu = "STATUS_DFU"
    case logFull = "LOG_FULL"
    case error = "ERROR"
    case systemError = "SYSTEM_ERROR"
    // 5-byte
    case unlock = "UNLOCK"
    case unlockDenied = "UNLOCK_DENIED"
    /// 12-byte
    case scheduleInit = "SCHEDULE_INIT"

    case unknown = "UNKNOWN"
}

public enum BLEPermissionMode: UInt8, Sendable {
    case all = 0, card = 1, password = 2, bot = 3
    case passwordOtp = 4, qrCode = 5, app = 6, fingerprint = 7
}
