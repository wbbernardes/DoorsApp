import Testing
@testable import DomainKit

@Suite("ParseBLEFrameUseCase")
struct ParseBLEFrameUseCaseTests {
    let useCase = ParseBLEFrameUseCase()

    // Epoch: 2026-01-01T00:00:00Z = 1767225600
    // tsRaw = 0 → timestamp == epoch

    private func makeBase64(tsRaw: UInt32 = 0, logCode: UInt8, payload: [UInt8] = []) -> String {
        var bytes: [UInt8] = [
            UInt8(tsRaw & 0xFF),
            UInt8((tsRaw >> 8) & 0xFF),
            UInt8((tsRaw >> 16) & 0xFF),
            UInt8((tsRaw >> 24) & 0xFF),
            logCode,
        ]
        bytes.append(contentsOf: payload)
        return Data(bytes).base64EncodedString()
    }

    @Test func parsesDoorOpen() throws {
        let raw = makeBase64(logCode: 0x01)
        let frame = try useCase.execute(base64: raw)
        #expect(frame.eventType == .doorOpen)
        #expect(frame.parsedValue == nil)
    }

    @Test func parsesDoorClose() throws {
        let frame = try useCase.execute(base64: makeBase64(logCode: 0x02))
        #expect(frame.eventType == .doorClose)
    }

    @Test func parsesBatteryLow() throws {
        let frame = try useCase.execute(base64: makeBase64(logCode: 0x13, payload: [75]))
        #expect(frame.eventType == .batteryLow)
        #expect(frame.parsedValue == "Level(75%)")
    }

    @Test func parsesEepromWriteError() throws {
        // address = 0x00FF (255 LE: 0xFF 0x00)
        let frame = try useCase.execute(base64: makeBase64(logCode: 0x20, payload: [0xFF, 0x00]))
        #expect(frame.eventType == .eepromWriteError)
        #expect(frame.parsedValue == "WriteError(255)")
    }

    @Test func parsesUnlock() throws {
        // mode=6 (APP), permId=1 (0x01 0x00 0x00 0x00)
        let frame = try useCase.execute(base64: makeBase64(logCode: 0x50, payload: [6, 1, 0, 0, 0]))
        #expect(frame.eventType == .unlock)
        #expect(frame.parsedValue?.contains("app") == true)
    }

    @Test func parsesUnlockDenied() throws {
        let frame = try useCase.execute(base64: makeBase64(logCode: 0x51, payload: [1, 2, 0, 0, 0]))
        #expect(frame.eventType == .unlockDenied)
    }

    @Test func parsesScheduleInit() throws {
        // userId=1, start=100, end=200 all LE
        let payload: [UInt8] = [1,0,0,0, 100,0,0,0, 200,0,0,0]
        let frame = try useCase.execute(base64: makeBase64(logCode: 0xC0, payload: payload))
        #expect(frame.eventType == .scheduleInit)
        #expect(frame.parsedValue?.contains("UserId(1)") == true)
    }

    @Test func throwsOnEmptyData() {
        #expect(throws: BLEParseError.invalidFrame) {
            try useCase.execute(base64: "")
        }
    }

    @Test func parsesTimestampEpochOffset() throws {
        // tsRaw = 60 → epoch + 60s
        let frame = try useCase.execute(base64: makeBase64(tsRaw: 60, logCode: 0x01))
        let bleEpoch = Date(timeIntervalSince1970: 1_767_225_600)
        #expect(frame.timestamp == bleEpoch.addingTimeInterval(60))
    }
}
