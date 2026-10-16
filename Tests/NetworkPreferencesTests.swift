import XCTest
import dnssd
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
        defer { first.stop() }
        let firstReady = expectation(description: "First hostname registered")
        first.onChange = { if first.hostname != nil { firstReady.fulfill() } }
        first.publish(name: name, ipv4: "127.0.0.1")
        await fulfillment(of: [firstReady], timeout: 10)
        XCTAssertEqual(first.hostname, name + ".local")
        let secondReady = expectation(description: "Conflicting hostname renamed")
        first.onChange = { if first.hostname == name + "-2.local" { secondReady.fulfill() } }
        // Two records from one mDNS daemon can coexist. Deliver the external-conflict
        // event explicitly, then exercise real DNS-SD registration of the suffix.
        first.registrationDidComplete(Int32(kDNSServiceErr_NameConflict))
        await fulfillment(of: [secondReady], timeout: 10)
        XCTAssertEqual(first.hostname, name + "-2.local")
        first.stop()
        XCTAssertNil(first.hostname)
        first.onChange = nil
    }

    @MainActor
    func testDeniedRegistrationRetriesTheSameNameAfterPermissionCanChange() async {
        let name = "airtype-retry-" + UUID().uuidString.prefix(8).lowercased()
        var time = Date()
        let publisher = BonjourHostname(now: { time })
        defer { publisher.stop() }
        let ready = expectation(description: "Initial record")
        publisher.onChange = { if publisher.hostname != nil { ready.fulfill() } }
        publisher.publish(name: name, ipv4: "127.0.0.1")
        await fulfillment(of: [ready], timeout: 10)
        publisher.onChange = nil
        publisher.registrationDidComplete(Int32(kDNSServiceErr_PolicyDenied))
        // Allow deferred DNS-SD teardown to finish before refreshing the address.
        await Task.yield()
        XCTAssertNil(publisher.hostname)
        publisher.publish(name: name, ipv4: "127.0.0.1")
        XCTAssertNil(publisher.hostname)
        time.addTimeInterval(6)
        let retry = expectation(description: "Same hostname retried")
        publisher.onChange = { if publisher.hostname == name + ".local" { retry.fulfill() } }
        publisher.publish(name: name, ipv4: "127.0.0.1")
        await fulfillment(of: [retry], timeout: 10)
        XCTAssertEqual(publisher.hostname, name + ".local")
    }
}
