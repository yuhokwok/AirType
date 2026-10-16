import XCTest
import CryptoKit
@testable import AirType

final class NearbyProtocolTests: XCTestCase {
    private let code = "ABCDE-FGHJK-LMNPQ-RSTUV"
    private func envelope(_ data: Data) throws -> NearbyEnvelope {
        var decoder = NearbyFrameDecoder()
        return try XCTUnwrap(decoder.append(data).first)
    }
    private func authenticate(_ session: NearbyReceiverSession, key: SymmetricKey) throws {
        let packet = NearbyPacket(kind: .authenticate, id: UUID(), challenge: session.challenge, sequence: 0)
        let reply = try session.receive(envelope(NearbyProtocol.seal(packet, key: key))) { _ in XCTFail("Authentication executed a key command"); return nil }
        XCTAssertEqual(try NearbyProtocol.open(envelope(reply), key: key).accepted, true)
    }
    func testCodeNormalizationAndEntropyLength() throws {
        XCTAssertEqual(NearbyProtocol.normalizedCode("abcde-fghjk lmnpq-rstuv"), "ABCDEFGHJKLMNPQRSTUV")
        XCTAssertNoThrow(try NearbyProtocol.key(code: code))
        XCTAssertThrowsError(try NearbyProtocol.key(code: "123456"))
        XCTAssertThrowsError(try NearbyProtocol.key(code: String(repeating: "0", count: 20)))
        XCTAssertEqual(NearbyProtocol.pairingCode().count, 20)
    }
    func testFragmentedAndCoalescedFrames() throws {
        let first = try NearbyProtocol.challengeFrame("first")
        let second = try NearbyProtocol.challengeFrame("second")
        var decoder = NearbyFrameDecoder()
        XCTAssertTrue(try decoder.append(first.prefix(5)).isEmpty)
        let frames = try decoder.append(Data(first.dropFirst(5)) + second)
        XCTAssertEqual(frames.map(\.challenge), ["first", "second"])
        XCTAssertThrowsError(try decoder.append(Data(repeating: 65, count: NearbyProtocol.maxFrame + 1)))
    }
    func testAuthenticatedUnicodeCommandAndAcknowledgement() throws {
        let key = try NearbyProtocol.key(code: code)
        let session = try NearbyReceiverSession(code: code)
        try authenticate(session, key: key)
        let text = "你好 👨‍👩‍👧‍👦 — café\n第二行"
        let packet = NearbyPacket(kind: .command, id: UUID(), challenge: session.challenge, sequence: 1, action: .insert, text: text)
        var executed = 0
        let reply = try session.receive(envelope(NearbyProtocol.seal(packet, key: key))) { command in
            XCTAssertEqual(command.text, text); executed += 1; return nil
        }
        let ack = try NearbyProtocol.open(envelope(reply), key: key)
        XCTAssertEqual(executed, 1); XCTAssertEqual(ack.id, packet.id); XCTAssertEqual(ack.accepted, true)
        XCTAssertThrowsError(try session.receive(envelope(NearbyProtocol.seal(packet, key: key))) { _ in XCTFail("Replay executed"); return nil })
    }
    func testWrongKeyAndCommandsBeforePairingCannotExecute() throws {
        let session = try NearbyReceiverSession(code: code)
        let key = try NearbyProtocol.key(code: code)
        let packet = NearbyPacket(kind: .command, id: UUID(), challenge: session.challenge, sequence: 1, action: .delete)
        XCTAssertThrowsError(try session.receive(envelope(NearbyProtocol.seal(packet, key: key))) { _ in XCTFail(); return nil })
        let wrongKey = try NearbyProtocol.key(code: "VVVVV-VVVVV-VVVVV-VVVVV")
        let auth = NearbyPacket(kind: .authenticate, id: UUID(), challenge: session.challenge, sequence: 0)
        XCTAssertThrowsError(try session.receive(envelope(NearbyProtocol.seal(auth, key: wrongKey))) { _ in XCTFail(); return nil })
    }
    func testCapturedAuthenticationCannotReplayOnNewConnection() throws {
        let old = try NearbyReceiverSession(code: code), fresh = try NearbyReceiverSession(code: code)
        let key = try NearbyProtocol.key(code: code)
        let auth = NearbyPacket(kind: .authenticate, id: UUID(), challenge: old.challenge, sequence: 0)
        XCTAssertThrowsError(try fresh.receive(envelope(NearbyProtocol.seal(auth, key: key))) { _ in XCTFail(); return nil })
    }
    func testTamperingFailsAuthenticatedDecryption() throws {
        let key = try NearbyProtocol.key(code: code)
        let packet = NearbyPacket(kind: .authenticate, id: UUID(), challenge: "test", sequence: 0)
        let valid = try envelope(NearbyProtocol.seal(packet, key: key))
        var ciphertext = try XCTUnwrap(Data(base64Encoded: XCTUnwrap(valid.sealed)))
        ciphertext[ciphertext.count - 1] ^= 1
        XCTAssertThrowsError(try NearbyProtocol.open(NearbyEnvelope(challenge: nil, sealed: ciphertext.base64EncodedString()), key: key))
    }
    func testReceiverRejectionIsAcknowledgedWithoutDeliverySuccess() throws {
        let key = try NearbyProtocol.key(code: code), session = try NearbyReceiverSession(code: code)
        try authenticate(session, key: key)
        let packet = NearbyPacket(kind: .command, id: UUID(), challenge: session.challenge, sequence: 1, action: .delete)
        let reply = try session.receive(envelope(NearbyProtocol.seal(packet, key: key))) { _ in "Accessibility unavailable" }
        let ack = try NearbyProtocol.open(envelope(reply), key: key)
        XCTAssertEqual(ack.accepted, false); XCTAssertEqual(ack.message, "Accessibility unavailable")
    }
    func testCommandBoundsAndReconnectDeduplication() {
        let packet = NearbyPacket(kind: .command, id: UUID(), challenge: "a", sequence: 1, action: .insert, text: String(repeating: "👋", count: 1025))
        XCTAssertFalse(packet.validCommand)
        var ledger = NearbyCommandLedger()
        let id = UUID(); ledger.record(id); XCTAssertTrue(ledger.contains(id))
        ledger.record(id)
        for _ in 0..<512 { ledger.record(UUID()) }
        XCTAssertFalse(ledger.contains(id))
    }
    func testLongUnicodeCommandSurvivesSmallBLEChunks() throws {
        let key = try NearbyProtocol.key(code: code)
        let session = try NearbyReceiverSession(code: code)
        try authenticate(session, key: key)
        let text = String(repeating: "你好🧑‍💻", count: 150)
        let packet = NearbyPacket(kind: .command, id: UUID(), challenge: session.challenge, sequence: 1, action: .insert, text: text)
        XCTAssertTrue(packet.validCommand)
        let frame = try NearbyProtocol.seal(packet, key: key)
        var decoder = NearbyFrameDecoder(), frames: [NearbyEnvelope] = []
        for offset in stride(from: 0, to: frame.count, by: 20) {
            frames += try decoder.append(Data(frame[offset..<min(offset + 20, frame.count)]))
        }
        XCTAssertEqual(frames.count, 1)
        let reply = try session.receive(XCTUnwrap(frames.first)) { command in
            XCTAssertEqual(command.text, text); return nil
        }
        XCTAssertEqual(try NearbyProtocol.open(envelope(reply), key: key).accepted, true)
    }
}
