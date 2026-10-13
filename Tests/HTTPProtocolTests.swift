import XCTest
@testable import AirType

final class HTTPProtocolTests: XCTestCase {
    func testFragmentedUnicodeBodyWaitsForFullUTF8Payload() throws {
        let body = Data("你好 👋".utf8)
        let header = Data("POST /command HTTP/1.1\r\nContent-Length: \(body.count)\r\n\r\n".utf8)
        XCTAssertNil(try HTTPRequest.parse(header + body.dropLast()))
        let request = try XCTUnwrap(HTTPRequest.parse(header + body))
        XCTAssertEqual(request.body,body)
    }
    func testRejectsAmbiguousOrOversizedRequests() {
        for raw in ["Content-Length: -1", "Content-Length: 999999", "Content-Length: 0\r\nContent-Length: 1", "Transfer-Encoding: chunked"] {
            XCTAssertThrowsError(try HTTPRequest.parse(Data("POST /command HTTP/1.1\r\n\(raw)\r\n\r\n".utf8)))
        }
        XCTAssertThrowsError(try HTTPRequest.parse(Data(repeating:65,count:65_537)))
    }
    func testCommandsValidateContentWithoutRestrictingLanguage() throws {
        XCTAssertTrue(RemoteCommand(id:UUID(),action:.insert,text:"廣東話 日本語 👨‍👩‍👧‍👦").isValid)
        XCTAssertFalse(RemoteCommand(id:UUID(),action:.insert,text:"").isValid)
        XCTAssertFalse(RemoteCommand(id:UUID(),action:.insert,text:nil).isValid)
        XCTAssertFalse(RemoteCommand(id:UUID(),action:.insert,text:String(repeating:"a",count:16_385)).isValid)
        XCTAssertTrue(RemoteCommand(id:UUID(),action:.delete,text:nil).isValid)
    }
}
