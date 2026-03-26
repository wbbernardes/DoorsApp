import Foundation

/// Abstraction over BLE communication. Implementations can be real CoreBluetooth
/// or a simulator injected for testing and preview purposes.
public protocol BLEServiceProtocol: Sendable {
    func connect(to deviceID: String) async throws
    func send(command: any BLECommandProtocol) async throws -> Data
}

/// Represents a single command sent to a BLE device.
public protocol BLECommandProtocol: Sendable {
    var commandCode: UInt8 { get }
    var payload: Data { get }
}
