@testable import CoreNetwork
import CryptoKit
@testable import DomainKit
import Foundation
import Testing

@Suite("Encryption", .serialized)
struct EncryptionIntegrationTests {
    @Test func doorsEndpoint_sendsClientPublicKeyHeader_whenEncryptionEnabled() async throws {
        defer { MockURLProtocol.reset() }
        MockURLProtocol.stub(
            statusCode: 200,
            json: #"{"content":[],"page":0,"total_pages":1}"#
        )
        let client = makeTestClient(encryptionEnabled: true)

        let _: PaginatedResponse<Door> = try await client.request(.doors(page: 0, size: 20))

        let header = MockURLProtocol.lastRequest?.value(forHTTPHeaderField: "X-Client-Public-Key")
        #expect(header != nil)
        let data = try #require(Data(base64Encoded: header ?? ""))
        #expect(data.count == 91)
    }

    @Test func authEndpoint_doesNotSendClientPublicKeyHeader() async throws {
        defer { MockURLProtocol.reset() }
        MockURLProtocol.stub(statusCode: 200, json: #"{"token":"jwt"}"#)
        let client = makeTestClient(encryptionEnabled: true)

        let _: AuthToken = try await client.request(.signIn(email: "a@b.com", password: "p"))

        let header = MockURLProtocol.lastRequest?.value(forHTTPHeaderField: "X-Client-Public-Key")
        #expect(header == nil)
    }

    @Test func doorsEndpoint_encryptionDisabled_doesNotSendHeader() async throws {
        defer { MockURLProtocol.reset() }
        MockURLProtocol.stub(
            statusCode: 200,
            json: #"{"content":[],"page":0,"total_pages":1}"#
        )
        let client = makeTestClient(encryptionEnabled: false)

        let _: PaginatedResponse<Door> = try await client.request(.doors(page: 0, size: 20))

        let header = MockURLProtocol.lastRequest?.value(forHTTPHeaderField: "X-Client-Public-Key")
        #expect(header == nil)
    }

    @Test func doorsEndpoint_decryptsEncryptedResponse() async throws {
        defer { MockURLProtocol.reset() }

        let encryptionService = EncryptionService()
        let (clientBase64, clientPrivateKey) = try encryptionService.generateKeyPair()

        // Simulate server side
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

        // Server encrypts JSON
        let plaintext = Data(#"{"content":[],"page":0,"total_pages":1}"#.utf8)
        let sealedBox = try AES.GCM.seal(plaintext, using: symmetricKey)
        let ciphertextWithTag = sealedBox.ciphertext + sealedBox.tag
        let nonceBase64 = Data(sealedBox.nonce).base64EncodedString()
        let ciphertextBase64 = ciphertextWithTag.base64EncodedString()

        // Server SPKI
        let spkiHeader = Data([
            0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2A, 0x86,
            0x48, 0xCE, 0x3D, 0x02, 0x01, 0x06, 0x08, 0x2A,
            0x86, 0x48, 0xCE, 0x3D, 0x03, 0x01, 0x07, 0x03,
            0x42, 0x00
        ])
        let serverSPKI = spkiHeader + serverPrivateKey.publicKey.x963Representation
        let serverBase64 = serverSPKI.base64EncodedString()

        let envelopeJSON = #"{"iv":"\#(nonceBase64)","ciphertext":"\#(ciphertextBase64)"}"#
        MockURLProtocol.stub(
            statusCode: 200,
            json: envelopeJSON,
            headers: ["X-Server-Public-Key": serverBase64]
        )

        let mock = MockEncryptionService(
            generateResult: { (clientBase64, clientPrivateKey) }
        )
        let client = makeTestClient(encryptionService: mock, encryptionEnabled: true)

        let result: PaginatedResponse<Door> = try await client.request(.doors(page: 0, size: 20))

        #expect(result.content.isEmpty)
        #expect(result.page == 0)
        #expect(result.totalPages == 1)
    }

    @Test func doorsEndpoint_noServerPublicKeyHeader_fallsBackToPlainDecoding() async throws {
        defer { MockURLProtocol.reset() }
        MockURLProtocol.stub(
            statusCode: 200,
            json: #"{"content":[],"page":0,"total_pages":1}"#
        )
        let client = makeTestClient(encryptionEnabled: true)

        let result: PaginatedResponse<Door> = try await client.request(.doors(page: 0, size: 20))

        #expect(result.content.isEmpty)
    }
}
