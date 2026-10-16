import XCTest
import Combine
import Network
import dnssd
@testable import AirType

final class LocalNetworkTests: XCTestCase {
    func testPermissionErrorsAreDistinguishedFromOfflineAndPortErrors() {
        XCTAssertTrue(LocalNetworkFailure.isPermissionDenied(.dns(Int32(kDNSServiceErr_PolicyDenied))))
        XCTAssertFalse(LocalNetworkFailure.isPermissionDenied(.posix(.ENETDOWN)))
        XCTAssertFalse(LocalNetworkFailure.isPermissionDenied(.posix(.EADDRINUSE)))
        XCTAssertFalse(LocalNetworkFailure.isPermissionDenied(.dns(Int32(kDNSServiceErr_NameConflict))))
        XCTAssertTrue(LocalNetworkFailure.message(for: .dns(Int32(kDNSServiceErr_PolicyDenied))).contains("Open AirType app"))
    }

    @MainActor
    func testForegroundCheckDiscoversItsOwnBonjourService() async {
        let check = LocalNetworkCheck()
        let discovered = expectation(description: "Round-trip Bonjour discovery")
        let subscription = check.$state.sink { if $0 == .available { discovered.fulfill() } }
        defer { subscription.cancel(); check.stop() }
        check.start()
        await fulfillment(of: [discovered], timeout: 15)
        XCTAssertEqual(check.state, .available)
        // Verify the temporary advertisement and browse can be started again after cleanup.
        check.start()
        XCTAssertEqual(check.state, .checking)
        check.stop()
    }
}
