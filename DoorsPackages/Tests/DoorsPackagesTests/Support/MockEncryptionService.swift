import CoreNetwork
import CryptoKit
import Foundation

struct MockEncryptionService: EncryptionServiceProtocol {
    var generateResult: (() throws -> (publicKeyBase64: String, privateKey: P256.KeyAgreement.PrivateKey))?
    var decryptResult: ((Data, Data, String, P256.KeyAgreement.PrivateKey) throws -> Data)?

    func generateKeyPair() throws -> (publicKeyBase64: String, privateKey: P256.KeyAgreement.PrivateKey) {
        if let generateResult {
            return try generateResult()
        }
        return try EncryptionService().generateKeyPair()
    }

    func decrypt(
        ciphertext: Data,
        nonce: Data,
        serverPublicKeyBase64: String,
        privateKey: P256.KeyAgreement.PrivateKey
    ) throws -> Data {
        if let decryptResult {
            return try decryptResult(ciphertext, nonce, serverPublicKeyBase64, privateKey)
        }
        return try EncryptionService().decrypt(
            ciphertext: ciphertext,
            nonce: nonce,
            serverPublicKeyBase64: serverPublicKeyBase64,
            privateKey: privateKey
        )
    }
}
