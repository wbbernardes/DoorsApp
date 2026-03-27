import CoreNetwork
import CryptoKit
import Foundation
import Testing

@Suite("EncryptionService")
struct EncryptionServiceTests {
    let service = EncryptionService()

    @Test func generateKeyPair_returnsValidSPKIBase64() throws {
        let (base64, _) = try service.generateKeyPair()
        let data = try #require(Data(base64Encoded: base64))
        // SPKI DER = 26-byte header + 65-byte uncompressed point
        #expect(data.count == 91)
        // Starts with fixed ASN.1 header
        let expectedPrefix = Data([0x30, 0x59, 0x30, 0x13])
        #expect(data.prefix(4) == expectedPrefix)
    }

    @Test func spki_encodeDecodeRoundTrip() throws {
        let (base64, privateKey) = try service.generateKeyPair()
        // Decode back to a public key and compare x963 representation
        let data = try #require(Data(base64Encoded: base64))
        let x963 = data.suffix(65)
        let reconstructed = try P256.KeyAgreement.PublicKey(x963Representation: x963)
        #expect(reconstructed.x963Representation == privateKey.publicKey.x963Representation)
    }

    @Test func decrypt_roundTrip_succeeds() throws {
        // Simulate the full ECDH flow: client generates key pair, server generates key pair,
        // server encrypts a message, client decrypts it.
        let (clientBase64, clientPrivateKey) = try service.generateKeyPair()

        // Simulate server side
        let serverPrivateKey = P256.KeyAgreement.PrivateKey()
        let serverPublicKey = serverPrivateKey.publicKey

        // Server derives shared secret using client's public key
        let clientSPKI = try #require(Data(base64Encoded: clientBase64))
        let clientX963 = clientSPKI.suffix(65)
        let clientPublicKey = try P256.KeyAgreement.PublicKey(x963Representation: clientX963)
        let serverSharedSecret = try serverPrivateKey.sharedSecretFromKeyAgreement(with: clientPublicKey)
        let serverSymmetricKey = serverSharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: Data("door-event-api-v1".utf8),
            outputByteCount: 32
        )

        // Server encrypts a JSON payload
        let plaintext = Data(#"{"content":[{"id":1,"name":"Door A"}],"page":0,"totalPages":1}"#.utf8)
        let sealedBox = try AES.GCM.seal(plaintext, using: serverSymmetricKey)

        // Build server public key as SPKI Base64
        let spkiHeader = Data([
            0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2A, 0x86,
            0x48, 0xCE, 0x3D, 0x02, 0x01, 0x06, 0x08, 0x2A,
            0x86, 0x48, 0xCE, 0x3D, 0x03, 0x01, 0x07, 0x03,
            0x42, 0x00
        ])
        let serverSPKI = spkiHeader + serverPublicKey.x963Representation
        let serverBase64 = serverSPKI.base64EncodedString()

        // Client decrypts: ciphertext = encrypted bytes + tag (appended)
        let ciphertextWithTag = sealedBox.ciphertext + sealedBox.tag
        let nonceData = Data(sealedBox.nonce)

        let decrypted = try service.decrypt(
            ciphertext: ciphertextWithTag,
            nonce: nonceData,
            serverPublicKeyBase64: serverBase64,
            privateKey: clientPrivateKey
        )

        #expect(decrypted == plaintext)
    }

    @Test func decrypt_wrongServerKey_throws() throws {
        let (_, clientPrivateKey) = try service.generateKeyPair()

        // Encrypt with one server key
        let realServerKey = P256.KeyAgreement.PrivateKey()
        let sharedSecret = try realServerKey.sharedSecretFromKeyAgreement(with: clientPrivateKey.publicKey)
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: Data("door-event-api-v1".utf8),
            outputByteCount: 32
        )
        let sealedBox = try AES.GCM.seal(Data("test".utf8), using: symmetricKey)
        let ciphertextWithTag = sealedBox.ciphertext + sealedBox.tag

        // Provide a different server public key for decryption
        let wrongServerKey = P256.KeyAgreement.PrivateKey()
        let spkiHeader = Data([
            0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2A, 0x86,
            0x48, 0xCE, 0x3D, 0x02, 0x01, 0x06, 0x08, 0x2A,
            0x86, 0x48, 0xCE, 0x3D, 0x03, 0x01, 0x07, 0x03,
            0x42, 0x00
        ])
        let wrongSPKI = spkiHeader + wrongServerKey.publicKey.x963Representation
        let wrongBase64 = wrongSPKI.base64EncodedString()

        #expect(throws: (any Error).self) {
            try service.decrypt(
                ciphertext: ciphertextWithTag,
                nonce: Data(sealedBox.nonce),
                serverPublicKeyBase64: wrongBase64,
                privateKey: clientPrivateKey
            )
        }
    }

    @Test func decrypt_corruptedCiphertext_throws() throws {
        let (clientBase64, clientPrivateKey) = try service.generateKeyPair()

        let serverPrivateKey = P256.KeyAgreement.PrivateKey()
        let clientSPKI = try #require(Data(base64Encoded: clientBase64))
        let clientPublicKey = try P256.KeyAgreement.PublicKey(x963Representation: clientSPKI.suffix(65))
        let sharedSecret = try serverPrivateKey.sharedSecretFromKeyAgreement(with: clientPublicKey)
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: Data("door-event-api-v1".utf8),
            outputByteCount: 32
        )
        let sealedBox = try AES.GCM.seal(Data("test data".utf8), using: symmetricKey)

        // Corrupt the ciphertext
        var corrupted = sealedBox.ciphertext + sealedBox.tag
        corrupted[0] ^= 0xFF

        let spkiHeader = Data([
            0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2A, 0x86,
            0x48, 0xCE, 0x3D, 0x02, 0x01, 0x06, 0x08, 0x2A,
            0x86, 0x48, 0xCE, 0x3D, 0x03, 0x01, 0x07, 0x03,
            0x42, 0x00
        ])
        let serverSPKI = spkiHeader + serverPrivateKey.publicKey.x963Representation

        #expect(throws: (any Error).self) {
            try service.decrypt(
                ciphertext: corrupted,
                nonce: Data(sealedBox.nonce),
                serverPublicKeyBase64: serverSPKI.base64EncodedString(),
                privateKey: clientPrivateKey
            )
        }
    }

    @Test func decrypt_tooShortCiphertext_throwsInvalidCiphertext() throws {
        let (_, privateKey) = try service.generateKeyPair()
        let shortData = Data(repeating: 0, count: 10) // less than 16 bytes

        #expect(throws: EncryptionError.self) {
            try service.decrypt(
                ciphertext: shortData,
                nonce: Data(repeating: 0, count: 12),
                serverPublicKeyBase64: "invalid",
                privateKey: privateKey
            )
        }
    }
}
