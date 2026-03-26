import Foundation

/// Simulates a BLE device for development and testing.
/// Inject mock responses keyed by command code to control simulation behavior.
public final class BLESimulator: BLEServiceProtocol {
    private let mockResponses: [UInt8: Data]

    public init(mockResponses: [UInt8: Data] = [:]) {
        self.mockResponses = mockResponses
    }

    public func connect(to _: String) async throws {
        try await Task.sleep(for: .milliseconds(100))
    }

    public func send(command: any BLECommandProtocol) async throws -> Data {
        try await Task.sleep(for: .milliseconds(50))
        return mockResponses[command.commandCode] ?? Data()
    }
}
