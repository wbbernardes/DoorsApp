import CryptoKit
import Foundation

// MARK: - Protocol

public protocol EncryptionServiceProtocol: Sendable {
    func generateKeyPair() throws -> (publicKeyBase64: String, privateKey: P256.KeyAgreement.PrivateKey)
    func decrypt(
        ciphertext: Data,
        nonce: Data,
        serverPublicKeyBase64: String,
        privateKey: P256.KeyAgreement.PrivateKey
    ) throws -> Data
}

// MARK: - Implementation

public struct EncryptionService: EncryptionServiceProtocol, Sendable {
    public init() {}

    public func generateKeyPair() throws -> (publicKeyBase64: String, privateKey: P256.KeyAgreement.PrivateKey) {
        let privateKey = P256.KeyAgreement.PrivateKey()
        let spkiData = spkiEncode(privateKey.publicKey)
        let base64 = spkiData.base64EncodedString()
        return (base64, privateKey)
    }

    public func decrypt(
        ciphertext: Data,
        nonce: Data,
        serverPublicKeyBase64: String,
        privateKey: P256.KeyAgreement.PrivateKey
    ) throws -> Data {
        let serverPublicKey = try spkiDecode(base64: serverPublicKeyBase64)
        let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: serverPublicKey)

        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: Data("door-event-api-v1".utf8),
            outputByteCount: 32
        )

        let gcmNonce = try AES.GCM.Nonce(data: nonce)

        // GCM tag is appended to the ciphertext (last 16 bytes)
        guard ciphertext.count > 16 else {
            throw EncryptionError.invalidCiphertext
        }
        let encryptedBytes = ciphertext.prefix(ciphertext.count - 16)
        let tag = ciphertext.suffix(16)

        let sealedBox = try AES.GCM.SealedBox(nonce: gcmNonce, ciphertext: encryptedBytes, tag: tag)
        return try AES.GCM.open(sealedBox, using: symmetricKey)
    }
}

// MARK: - SPKI DER Helpers

/// Fixed 26-byte ASN.1 header for a P-256 Subject Public Key Info (SPKI) structure.
private let spkiHeaderP256 = Data([
    0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2A, 0x86,
    0x48, 0xCE, 0x3D, 0x02, 0x01, 0x06, 0x08, 0x2A,
    0x86, 0x48, 0xCE, 0x3D, 0x03, 0x01, 0x07, 0x03,
    0x42, 0x00
])

private func spkiEncode(_ publicKey: P256.KeyAgreement.PublicKey) -> Data {
    spkiHeaderP256 + publicKey.x963Representation
}

private func spkiDecode(base64: String) throws -> P256.KeyAgreement.PublicKey {
    guard let data = Data(base64Encoded: base64) else {
        throw EncryptionError.invalidPublicKey
    }
    guard data.count == spkiHeaderP256.count + 65,
          data.prefix(spkiHeaderP256.count) == spkiHeaderP256
    else {
        throw EncryptionError.invalidPublicKey
    }
    let x963 = data.suffix(65)
    return try P256.KeyAgreement.PublicKey(x963Representation: x963)
}

// MARK: - Errors

public enum EncryptionError: Error, LocalizedError, Sendable {
    case invalidPublicKey
    case invalidCiphertext

    public var errorDescription: String? {
        switch self {
        case .invalidPublicKey: "Invalid server public key."
        case .invalidCiphertext: "Invalid encrypted response data."
        }
    }
}
