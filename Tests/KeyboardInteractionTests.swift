import XCTest
import UIKit
@testable import AirType

final class KeyboardInteractionTests: XCTestCase {
    func testSentenceCapitalizationMatchesCInputForProseAndChinesePunctuation() {
        for context in ["", "Hello. ", "你好！ ", "Hello\n", "   "] {
            XCTAssertEqual(KeyboardTypingBehavior.automaticShift(type: .sentences, context: context), true, context)
        }
        for context in ["hello", "hello ", "hello."] {
            XCTAssertEqual(KeyboardTypingBehavior.automaticShift(type: .sentences, context: context), false, context)
        }
    }
    func testHiddenContextDoesNotRearmShiftAfterEveryLetter() {
        XCTAssertNil(KeyboardTypingBehavior.automaticShift(type: .sentences, context: nil))
        XCTAssertNil(KeyboardTypingBehavior.automaticShift(type: .words, context: nil))
        XCTAssertEqual(KeyboardTypingBehavior.automaticShift(type: .none, context: nil), false)
        XCTAssertEqual(KeyboardTypingBehavior.automaticShift(type: .allCharacters, context: nil), true)
    }
    func testWordAndDisabledCapitalizationRespectHostTraits() {
        XCTAssertEqual(KeyboardTypingBehavior.automaticShift(type: .words, context: "hello "), true)
        XCTAssertEqual(KeyboardTypingBehavior.automaticShift(type: .words, context: "hello"), false)
        XCTAssertEqual(KeyboardTypingBehavior.automaticShift(type: .none, context: ""), false)
    }
    func testDeleteDragCadenceIsBoundedAndAcceleratesOnlyLeftward() {
        XCTAssertEqual(KeyboardTypingBehavior.deleteInterval(leftDrag: -100), 0.1)
        XCTAssertEqual(KeyboardTypingBehavior.deleteInterval(leftDrag: 8), 0.1)
        XCTAssertLessThan(KeyboardTypingBehavior.deleteInterval(leftDrag: 50), 0.1)
        XCTAssertEqual(KeyboardTypingBehavior.deleteInterval(leftDrag: 96), 0.035)
        XCTAssertEqual(KeyboardTypingBehavior.deleteInterval(leftDrag: 1000), 0.035)
    }
    @MainActor
    private func descendants(_ view: UIView) -> [UIView] { [view] + view.subviews.flatMap { descendants($0) } }

    @MainActor
    func testWebOnlyConnectionPanelHasEqualHalvesWithoutTransportSelector() throws {
        for size in [CGSize(width: 320, height: 216), CGSize(width: 852, height: 162), CGSize(width: 1024, height: 264)] {
            let keyboard = AirKeyboardView(frame: CGRect(origin: .zero, size: size))
            keyboard.showsGlobe = false; keyboard.receiveMode = .wifi
            keyboard.pairingCode = "ABCDEFGHJK23456789LM"
            keyboard.layoutIfNeeded(); keyboard.layoutIfNeeded()
            let views = descendants(keyboard)
            let left = try XCTUnwrap(views.first { $0.accessibilityIdentifier == "AirTypeStatusHalf" })
            let right = try XCTUnwrap(views.first { $0.accessibilityIdentifier == "AirTypePairingHalf" })
            XCTAssertEqual(left.bounds.width, size.width / 2, accuracy: 0.5)
            XCTAssertEqual(right.bounds.width, size.width / 2, accuracy: 0.5)
            XCTAssertFalse(views.contains { $0 is UISegmentedControl })
            XCTAssertEqual(keyboard.receiveMode, .web)
            XCTAssertFalse(views.contains { $0.accessibilityLabel == "Next keyboard" })
            for name in ["Back to keyboard", "Delete"] {
                let button = try XCTUnwrap(views.compactMap { $0 as? UIButton }.first { $0.accessibilityLabel == name })
                let bounds = button.convert(button.bounds, to: keyboard)
                XCTAssertEqual(bounds.width, 44, accuracy: 0.5)
                XCTAssertEqual(bounds.height, 44, accuracy: 0.5)
                XCTAssertLessThanOrEqual(bounds.maxY, size.height + 0.5)
            }
            XCTAssertFalse(keyboard.hasAmbiguousLayout)
        }
    }
    @MainActor
    func testAddressToggleUpdatesLiveAddressesAndQRDestination() throws {
        let keyboard = AirKeyboardView(frame: CGRect(x: 0, y: 0, width: 390, height: 216))
        keyboard.showsGlobe = false
        keyboard.address = "http://airtype.local:8307/#PAIRINGTOKEN"
        keyboard.ipAddress = "http://192.168.1.2:8307/#PAIRINGTOKEN"
        func text(_ id: String) -> String? {
            descendants(keyboard).compactMap { $0 as? UILabel }.first { $0.accessibilityIdentifier == id }?.text
        }
        let toggle = try XCTUnwrap(descendants(keyboard).compactMap { $0 as? UIButton }.first { $0.accessibilityIdentifier == "AirTypeAddressToggle" })
        XCTAssertEqual(text("AirTypePrimaryAddress"), "http://airtype.local:8307/")
        XCTAssertEqual(text("AirTypeSecondaryAddress"), "http://192.168.1.2:8307/")
        toggle.sendActions(for: .touchUpInside)
        XCTAssertEqual(text("AirTypePrimaryAddress"), "http://192.168.1.2:8307/")
        XCTAssertEqual(text("AirTypeSecondaryAddress"), "http://airtype.local:8307/")
        keyboard.ipAddress = "http://192.168.1.3:8307/#PAIRINGTOKEN"
        XCTAssertEqual(text("AirTypePrimaryAddress"), "http://192.168.1.3:8307/")
        let detailsAction = try XCTUnwrap(toggle.accessibilityCustomActions?.first)
        XCTAssertTrue(detailsAction.actionHandler?(detailsAction) ?? false)
        let labels = descendants(keyboard).compactMap { ($0 as? UILabel)?.text }
        XCTAssertTrue(labels.contains("http://192.168.1.3:8307/#PAIRINGTOKEN"))
        let qr = try XCTUnwrap(descendants(keyboard).compactMap { $0 as? UIImageView }.first { $0.accessibilityLabel == "QR code for AirType connection address" })
        XCTAssertNotNil(qr.image)
    }

    @MainActor
    func testAddressToggleHandlesIPOnlyAndDuplicateAddresses() throws {
        let keyboard = AirKeyboardView(frame: CGRect(x: 0, y: 0, width: 320, height: 216))
        keyboard.showsGlobe = false
        keyboard.ipAddress = "http://192.168.1.2:8307/#TOKEN"
        let labels = descendants(keyboard).compactMap { $0 as? UILabel }
        let primary = try XCTUnwrap(labels.first { $0.accessibilityIdentifier == "AirTypePrimaryAddress" })
        let secondary = try XCTUnwrap(labels.first { $0.accessibilityIdentifier == "AirTypeSecondaryAddress" })
        XCTAssertEqual(primary.text, "http://192.168.1.2:8307/")
        XCTAssertTrue(secondary.isHidden)
        keyboard.address = keyboard.ipAddress
        let toggle = try XCTUnwrap(descendants(keyboard).compactMap { $0 as? UIButton }.first { $0.accessibilityIdentifier == "AirTypeAddressToggle" })
        toggle.sendActions(for: .touchUpInside)
        XCTAssertEqual(primary.text, "http://192.168.1.2:8307/")
        XCTAssertTrue(secondary.isHidden)
        XCTAssertFalse(toggle.accessibilityValue?.contains("TOKEN") ?? true)
    }

    @MainActor
    func testBackButtonOpensLocalKeyboardAndWiFiReturnsToConnection() throws {
        let keyboard = AirKeyboardView(frame: CGRect(x: 0, y: 0, width: 390, height: 216))
        keyboard.showsGlobe = false
        let back = try XCTUnwrap(descendants(keyboard).compactMap { $0 as? UIButton }.first { $0.accessibilityLabel == "Back to keyboard" })
        back.sendActions(for: .touchUpInside)
        XCTAssertFalse(keyboard.webMode)
        XCTAssertFalse(descendants(keyboard).contains { $0.accessibilityLabel == "Next keyboard" })
        keyboard.showsGlobe = true
        keyboard.layoutIfNeeded()
        let globe = try XCTUnwrap(descendants(keyboard).compactMap { $0 as? UIButton }.first { $0.accessibilityLabel == "Next keyboard" })
        let numeric = try XCTUnwrap(descendants(keyboard).compactMap { $0 as? UIButton }.first { $0.title(for: .normal) == "123" })
        let airtype = try XCTUnwrap(descendants(keyboard).compactMap { $0 as? UIButton }.first { $0.accessibilityIdentifier == "AirTypeModeButton" })
        XCTAssertNotNil(airtype.image(for: .normal))
        XCTAssertLessThan(numeric.frame.maxX, globe.frame.minX)
        XCTAssertLessThan(globe.frame.maxX, airtype.frame.minX)
        airtype.sendActions(for: .touchUpInside)
        XCTAssertTrue(keyboard.webMode)
        keyboard.showsGlobe = true
        XCTAssertTrue(descendants(keyboard).contains { $0.accessibilityLabel == "Next keyboard" })
    }
    @MainActor
    func testLocalTypingConsumesShiftAndUsesCurrentDocumentContext() throws {
        let keyboard = AirKeyboardView(); keyboard.webMode = false
        var text = ""
        keyboard.contextBeforeInput = { text }
        keyboard.insertText = { text += $0 }
        keyboard.autocapitalizationType = .sentences
        keyboard.synchronizeCapitalization()
        func tap(_ title: String) throws {
            let key = try XCTUnwrap(descendants(keyboard).compactMap { $0 as? UIButton }.first { $0.title(for: .normal) == title })
            key.sendActions(for: .touchUpInside)
        }
        try tap("H"); try tap("i"); try tap("space")
        XCTAssertEqual(text, "Hi ")
        text = "Hi. "; keyboard.synchronizeCapitalization()
        try tap("A"); try tap("b")
        XCTAssertEqual(text, "Hi. Ab")
    }
}

extension KeyboardInteractionTests {
    @MainActor
    func testDeleteStartsImmediatelyRepeatsAndStopsWhenModeChanges() async throws {
        let keyboard = AirKeyboardView()
        var deletes = 0; keyboard.deleteText = { deletes += 1 }
        let key = try XCTUnwrap(descendants(keyboard).compactMap { $0 as? UIButton }.first { $0.accessibilityLabel == "Delete" })
        key.sendActions(for: .touchDown)
        XCTAssertEqual(deletes, 1)
        try await Task.sleep(for: .milliseconds(1250))
        XCTAssertGreaterThan(deletes, 1)
        keyboard.webMode = false
        let count = deletes
        try await Task.sleep(for: .milliseconds(200))
        XCTAssertEqual(deletes, count)
        let localDelete = try XCTUnwrap(descendants(keyboard).compactMap { $0 as? UIButton }.first { $0.accessibilityLabel == "Delete" })
        XCTAssertTrue(localDelete.accessibilityActivate())
        XCTAssertEqual(deletes, count + 1)
    }
}
