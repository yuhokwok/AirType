import XCTest
@testable import AirType

final class PairingCodeTests: XCTestCase {
    func testWrongCodeDoesNotAuthenticateAndCorrectCodeDoes() {
        var code = PairingCode(value: "123456")
        XCTAssertEqual(code.verify("654321"), .incorrect)
        XCTAssertEqual(code.verify("123456"), .accepted)
    }
    func testRepeatedGuessingBlocksEvenCorrectCodeUntilWindowExpires() {
        var code = PairingCode(value: "123456")
        let now = Date()
        for _ in 0..<5 { XCTAssertEqual(code.verify("000000", now: now), .incorrect) }
        XCTAssertEqual(code.verify("123456", now: now.addingTimeInterval(59)), .rateLimited)
        XCTAssertEqual(code.verify("123456", now: now.addingTimeInterval(60)), .accepted)
    }
    func testGeneratedCodeCanBeEnteredAsSixDigits() {
        let code = PairingCode().value
        XCTAssertEqual(code.count, 6)
        XCTAssertTrue(code.allSatisfy(\.isNumber))
    }
}
