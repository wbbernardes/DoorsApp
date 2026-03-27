import Foundation

struct EncryptedEnvelope: Decodable, Sendable {
    let iv: String // swiftlint:disable:this identifier_name
    let ciphertext: String
}
