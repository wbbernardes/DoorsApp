import Foundation

public struct Door: Decodable, Identifiable, Sendable, Hashable {
    public let id: Int
    public let name: String
    public let serial: String?
    public let lockMac: String?
    public let address: String?
    public let latitude: Double?
    public let longitude: Double?
    public let battery: Int?

    public init(
        id: Int,
        name: String,
        serial: String?,
        lockMac: String?,
        address: String?,
        latitude: Double?,
        longitude: Double?,
        battery: Int?
    ) {
        self.id = id
        self.name = name
        self.serial = serial
        self.lockMac = lockMac
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.battery = battery
    }
}
