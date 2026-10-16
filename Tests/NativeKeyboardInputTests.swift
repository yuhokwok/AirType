import XCTest
import UIKit
@testable import AirType

final class NativeKeyboardInputTests: XCTestCase {
    @MainActor
    func testEncryptedDesktopCommandInsertsIntoTextInput() throws {
        let field = UITextView()
        let sink = NativeKeyboardInput(insert: { field.insertText($0) }, delete: { field.deleteBackward() }, move: { _ in })
        let code = NearbyProtocol.pairingCode(), key = try NearbyProtocol.key(code: code)
        let session = try NearbyReceiverSession(code: code)
        func receive(_ packet: NearbyPacket) throws -> NearbyPacket {
            var decoder = NearbyFrameDecoder(), replies = NearbyFrameDecoder()
            let envelope = try XCTUnwrap(decoder.append(NearbyProtocol.seal(packet, key: key)).first)
            let response = try session.receive(envelope, execute: sink.execute)
            return try NearbyProtocol.open(XCTUnwrap(replies.append(response).first), key: key)
        }
        let auth = NearbyPacket(kind: .authenticate, id: UUID(), challenge: session.challenge, sequence: 0)
        XCTAssertEqual(try receive(auth).accepted, true)
        XCTAssertEqual(field.text, "")
        let packet = NearbyPacket(kind: .command, id: UUID(), challenge: session.challenge, sequence: 1, action: .insert, text: "打入鍵盤當前文字欄 👨‍👩‍👧‍👦")
        XCTAssertEqual(try receive(packet).accepted, true)
        XCTAssertEqual(field.text, packet.text)
    }
    @MainActor
    func testDeleteReturnAndTabUseTheTextInputDestination() {
        let field = UITextView()
        let sink = NativeKeyboardInput(insert: { field.insertText($0) }, delete: { field.deleteBackward() }, move: { _ in })
        func run(_ action: NearbyPacket.Action, text: String? = nil) {
            XCTAssertNil(sink.execute(NearbyPacket(kind: .command, id: UUID(), challenge: "test", sequence: 1, action: action, text: text)))
        }
        run(.insert, text: "你好👋")
        run(.delete)
        XCTAssertEqual(field.text, "你好")
        run(.newline); run(.tab); run(.insert, text: "第二行")
        XCTAssertEqual(field.text, "你好\n\t第二行")
    }
    func testCursorRoutingAndUnsupportedKeysDoNotInsertCharacters() {
        var moved: [Int] = [], inserted = ""
        let sink = NativeKeyboardInput(insert: { inserted += $0 }, delete: {}, move: { moved.append($0) })
        for action in [NearbyPacket.Action.left, .right] {
            XCTAssertNil(sink.execute(NearbyPacket(kind: .command, id: UUID(), challenge: "test", sequence: 1, action: action)))
        }
        XCTAssertEqual(moved, [-1, 1])
        for action in [NearbyPacket.Action.up, .down, .escape] {
            XCTAssertNotNil(sink.execute(NearbyPacket(kind: .command, id: UUID(), challenge: "test", sequence: 1, action: action)))
        }
        XCTAssertEqual(inserted, "")
    }
}
