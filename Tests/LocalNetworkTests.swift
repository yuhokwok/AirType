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
    func testLegacyBrowserConnectsWithoutCodeAndIsRevokedWhenDisabled() async throws {
        let oldMode = NetworkPreferences.legacyMode
        NetworkPreferences.legacyMode = false
        let server = AirTypeServer()
        defer { server.stop(); NetworkPreferences.legacyMode = oldMode }
        let ready = expectation(description: "HTTP server ready")
        server.onStateChange = {
            if server.ipAddress != nil { server.onStateChange = nil; ready.fulfill() }
        }
        server.start(useDynamicPort: true)
        await fulfillment(of: [ready], timeout: 10)
        let address = try XCTUnwrap(server.ipAddress)
        let base = try XCTUnwrap(URL(string: String(address.split(separator: "#")[0])))
        let session = URLSession(configuration: .ephemeral)
        defer { session.invalidateAndCancel() }
        func request(_ path: String, token: String? = nil, body: [String: String]? = nil, origin: String? = nil) async throws -> (Int, Data) {
            var request = URLRequest(url: base.appendingPathComponent(path))
            request.timeoutInterval = 5
            if let token { request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization") }
            if let origin { request.setValue(origin, forHTTPHeaderField: "Origin") }
            if let body {
                request.httpMethod = "POST"
                request.httpBody = try JSONEncoder().encode(body)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            let (data, response) = try await session.data(for: request)
            return (try XCTUnwrap(response as? HTTPURLResponse).statusCode, data)
        }
        let (secureStatus, secureHTML) = try await request("")
        XCTAssertEqual(secureStatus, 200)
        XCTAssertTrue(String(decoding: secureHTML, as: UTF8.self).contains("const legacyToken = \"\";"))
        let (unauthorized, _) = try await request("status")
        XCTAssertEqual(unauthorized, 403)
        NetworkPreferences.legacyMode = true
        let (_, legacyHTML) = try await request("")
        let html = String(decoding: legacyHTML, as: UTF8.self)
        let prefix = "const legacyToken = "
        let start = try XCTUnwrap(html.range(of: prefix)).upperBound
        let end = try XCTUnwrap(html[start...].firstIndex(of: ";"))
        let token = try JSONDecoder().decode(String.self, from: Data(html[start..<end].utf8))
        XCTAssertFalse(token.isEmpty)
        XCTAssertNil(server.pairingCode)
        let (connected, _) = try await request("status", token: token)
        XCTAssertEqual(connected, 200)
        var inserted: String?
        server.onCommand = { inserted = $0.text }
        let (sent, _) = try await request("command", token: token, body: ["id": UUID().uuidString, "action": "insert", "text": "Legacy 你好"])
        XCTAssertEqual(sent, 200)
        XCTAssertEqual(inserted, "Legacy 你好")
        let (foreignOrigin, _) = try await request("status", token: token, origin: "http://example.com")
        XCTAssertEqual(foreignOrigin, 403)
        NetworkPreferences.legacyMode = false
        let (revoked, _) = try await request("status", token: token)
        XCTAssertEqual(revoked, 403)
        XCTAssertNotNil(server.pairingCode)
        let (paired, _) = try await request("pair", body: ["code": try XCTUnwrap(server.pairingCode)])
        XCTAssertEqual(paired, 200)
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
