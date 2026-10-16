import XCTest
@testable import AirType

final class NetworkPreferencesTests: XCTestCase {
    func testNamesAreSafeDNSLabels() {
        XCTAssertEqual(NetworkPreferences.normalizedHostname(" My AirType.local "), "my-airtype")
        XCTAssertEqual(NetworkPreferences.normalizedHostname("---Desk__Keyboard!!!"), "desk-keyboard")
        XCTAssertEqual(NetworkPreferences.normalizedHostname("鍵盤"), "airtype")
        XCTAssertLessThanOrEqual(NetworkPreferences.normalizedHostname(String(repeating: "x", count: 100)).count, 50)
        XCTAssertEqual(NetworkPreferences.candidate("airtype", attempt: 2), "airtype-2.local")
    }
    func testCustomNameIsStoredInTheSharedAppGroup() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: NetworkPreferences.appGroup))
        let previous = defaults.object(forKey: NetworkPreferences.nameKey)
        defer {
            if let previous { defaults.set(previous, forKey: NetworkPreferences.nameKey) }
            else { defaults.removeObject(forKey: NetworkPreferences.nameKey) }
        }
        NetworkPreferences.saveHostname("Desk Keyboard.local")
        let extensionDefaults = try XCTUnwrap(UserDefaults(suiteName: NetworkPreferences.appGroup))
        XCTAssertEqual(extensionDefaults.string(forKey: NetworkPreferences.nameKey), "desk-keyboard")
        XCTAssertEqual(NetworkPreferences.hostname, "desk-keyboard")
    }
    @MainActor
    func testHostConflictRenamesAndStopClearsTheAddress() async {
        let name = "airtype-test-" + UUID().uuidString.prefix(8).lowercased()
        let first = BonjourHostname()
        let second = BonjourHostname()
        defer { first.stop(); second.stop() }
        let firstReady = expectation(description: "First hostname registered")
        first.onChange = { if first.hostname != nil { firstReady.fulfill() } }
        first.publish(name: name, ipv4: "127.0.0.1")
        await fulfillment(of: [firstReady], timeout: 10)
        XCTAssertEqual(first.hostname, name + ".local")
        first.onChange = nil
        let secondReady = expectation(description: "Conflicting hostname renamed")
        second.onChange = { if second.hostname != nil { secondReady.fulfill() } }
        second.publish(name: name, ipv4: "127.0.0.2")
        await fulfillment(of: [secondReady], timeout: 10)
        XCTAssertEqual(second.hostname, name + "-2.local")
        first.stop(); second.stop()
        XCTAssertNil(first.hostname)
        XCTAssertNil(second.hostname)
        first.onChange = nil; second.onChange = nil
    }
}
