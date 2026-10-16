import XCTest
import UIKit
@testable import AirType

final class LocalKeyboardTouchTests: XCTestCase {
    typealias Engine = LocalKeyboardInteraction<Int>
    func testShiftDragTypesOneCapitalAndRestoresLowercase() {
        var engine = Engine(); engine.synchronizeShift(false, context: "a")
        XCTAssertEqual(engine.begin(1, key: .shift), [])
        XCTAssertTrue(engine.uppercase)
        engine.move(1, to: .character("a"))
        XCTAssertEqual(engine.end(1, on: .character("a")), [.insert("A")])
        XCTAssertFalse(engine.uppercase); XCTAssertFalse(engine.hasContacts)
    }
    func testHeldShiftAndSecondFingerRemainUppercaseUntilShiftReleases() {
        var engine = Engine(); engine.synchronizeShift(false, context: "a")
        _ = engine.begin(1, key: .shift)
        _ = engine.begin(2, key: .character("a"))
        XCTAssertEqual(engine.end(2, on: .character("a")), [.insert("A")])
        _ = engine.begin(3, key: .character("b"))
        XCTAssertEqual(engine.end(3, on: .character("b")), [.insert("B")])
        _ = engine.end(1, on: .shift)
        XCTAssertFalse(engine.uppercase)
    }
    func testSymbolDragRestoresExactSourceWhileTapKeepsDestination() {
        var engine = Engine()
        _ = engine.begin(1, key: .layout(.numbers)); _ = engine.end(1, on: .layout(.numbers))
        XCTAssertEqual(engine.page, .numbers)
        _ = engine.begin(2, key: .layout(.symbols))
        XCTAssertEqual(engine.page, .symbols)
        XCTAssertEqual(engine.end(2, on: .character("#")), [.insert("#")])
        XCTAssertEqual(engine.page, .numbers)
        _ = engine.begin(3, key: .layout(.letters))
        XCTAssertEqual(engine.end(3, on: .character("a")), [.insert("a")])
        XCTAssertEqual(engine.page, .numbers)
    }
    func testHeldSymbolModifierCanTypeWithAnotherFinger() {
        var engine = Engine()
        _ = engine.begin(1, key: .layout(.numbers))
        _ = engine.begin(2, key: .character("1"))
        XCTAssertEqual(engine.end(2, on: .character("1")), [.insert("1")])
        _ = engine.end(1, on: .layout(.numbers))
        XCTAssertEqual(engine.page, .letters)
    }
    func testRolloverCommitsInPressOrderAndNeverAgainOnReverseRelease() {
        var engine = Engine(); engine.synchronizeShift(false, context: "x")
        _ = engine.begin(1, key: .character("a"))
        engine.move(1, to: .character("z"))
        XCTAssertEqual(engine.begin(2, key: .character("b")), [.insert("a")])
        XCTAssertEqual(engine.begin(3, key: .space), [.insert("b")])
        XCTAssertEqual(engine.end(3, on: .space), [.insert(" ")])
        XCTAssertEqual(engine.end(2, on: .character("b")), [])
        XCTAssertEqual(engine.end(1, on: .character("a")), [])
        XCTAssertEqual(engine.end(1, on: .character("a")), [])
    }
    func testRolloverConsumesAutomaticShiftBeforeNextContact() {
        var engine = Engine()
        _ = engine.begin(1, key: .character("a"))
        XCTAssertEqual(engine.begin(2, key: .character("b")), [.insert("A")])
        XCTAssertEqual(engine.end(2, on: .character("b")), [.insert("b")])
    }
    func testSlideCorrectionAndControlReleaseSafety() {
        var engine = Engine(); engine.synchronizeShift(false, context: "a")
        _ = engine.begin(1, key: .character("a"))
        XCTAssertEqual(engine.end(1, on: .character("s")), [.insert("s")])
        _ = engine.begin(2, key: .character("a"))
        XCTAssertEqual(engine.end(2, on: .enter), [])
        _ = engine.begin(3, key: .delete)
        XCTAssertEqual(engine.end(3, on: .character("s")), [.endDelete])
        _ = engine.begin(4, key: .character("a"))
        XCTAssertEqual(engine.end(4, on: .wifi), [])
    }
    func testCancellationRestoresModifiersAndDoesNotType() {
        var engine = Engine(); engine.synchronizeShift(false, context: "a")
        _ = engine.begin(1, key: .shift); _ = engine.begin(2, key: .layout(.symbols))
        engine.cancelAll()
        XCTAssertEqual(engine.page, .letters); XCTAssertFalse(engine.uppercase)
        XCTAssertFalse(engine.hasContacts)
        _ = engine.begin(3, key: .character("a")); XCTAssertEqual(engine.cancel(3), [])
    }
    func testManualShiftAndCapsLockSurviveRepeatedHostCallbacks() {
        var engine = Engine(); engine.synchronizeShift(true, context: "")
        _ = engine.begin(1, key: .shift); _ = engine.end(1, on: .shift, context: "")
        engine.synchronizeShift(true, context: "")
        XCTAssertFalse(engine.uppercase)
        _ = engine.begin(2, key: .shift, tapCount: 2); _ = engine.end(2, on: .shift)
        XCTAssertEqual(engine.shift, .locked)
        _ = engine.begin(3, key: .character("a")); XCTAssertEqual(engine.end(3, on: .character("a")), [.insert("A")])
        engine.synchronizeShift(false, context: "a")
        XCTAssertEqual(engine.shift, .locked)
    }
    @MainActor
    private func button(_ title: String, in view: UIView) throws -> UIButton {
        if let button = view as? UIButton, button.title(for: .normal) == title { return button }
        for child in view.subviews { if let button = try? button(title, in: child) { return button } }
        throw NSError(domain: "Missing key \(title)", code: 1)
    }
    @MainActor
    func testActualSurfaceRolloverPopupsAndWiFiPeriodLayout() throws {
        let keyboard = LocalKeyboardView(frame: CGRect(x: 0, y: 0, width: 390, height: 250))
        keyboard.autocapitalizationType = .none; keyboard.synchronizeCapitalization(); keyboard.layoutIfNeeded()
        var text = ""; keyboard.insertText = { text += $0 }
        let a = try button("a", in: keyboard), b = try button("b", in: keyboard)
        let first = NSObject(), second = NSObject()
        keyboard.beginContact(ObjectIdentifier(first), at: a.center)
        XCTAssertEqual(keyboard.subviews.filter { $0.accessibilityIdentifier == "KeyPreview" }.count, 1)
        keyboard.beginContact(ObjectIdentifier(second), at: b.center)
        XCTAssertEqual(text, "a")
        keyboard.endContact(ObjectIdentifier(second), at: b.center)
        keyboard.endContact(ObjectIdentifier(first), at: a.center)
        XCTAssertEqual(text, "ab")
        let numeric = try button("123", in: keyboard), space = try button("space", in: keyboard)
        let wifi = try XCTUnwrap(keyboard.subviews.compactMap { $0 as? UIButton }.first { $0.accessibilityIdentifier == "AirTypeModeButton" })
        let period = try XCTUnwrap(keyboard.subviews.compactMap { $0 as? UIButton }.filter { $0.title(for: .normal) == "." }.last)
        XCTAssertLessThan(numeric.frame.maxX, wifi.frame.minX)
        XCTAssertLessThan(wifi.frame.maxX, space.frame.minX)
        XCTAssertLessThan(space.frame.maxX, period.frame.minX)
        XCTAssertEqual(a.layer.cornerRadius, 10)
    }
}

extension LocalKeyboardTouchTests {
    func testSymbolModifierCanReleaseBeforePendingCharacterWithoutChangingItsMeaning() {
        var engine = Engine()
        _ = engine.begin(1, key: .layout(.numbers))
        _ = engine.begin(2, key: .character("1"))
        _ = engine.end(1, on: .layout(.numbers))
        XCTAssertEqual(engine.page, .letters)
        XCTAssertEqual(engine.end(2, on: .character("q")), [.insert("1")])
    }
    @MainActor
    func testSurfaceShiftDragAndSymbolDragKeepContactThroughLayoutChanges() throws {
        let keyboard = LocalKeyboardView(frame: CGRect(x: 0, y: 0, width: 390, height: 250))
        keyboard.autocapitalizationType = .none; keyboard.synchronizeCapitalization(); keyboard.layoutIfNeeded()
        var text = ""; keyboard.insertText = { text += $0 }
        let token = NSObject(), id = ObjectIdentifier(token)
        let shift = try XCTUnwrap(keyboard.subviews.compactMap { $0 as? UIButton }.first { $0.accessibilityLabel == "Shift" })
        keyboard.beginContact(id, at: shift.center)
        let a = try button("A", in: keyboard)
        keyboard.moveContact(id, to: a.center); keyboard.endContact(id, at: a.center)
        XCTAssertEqual(text, "A")
        let numeric = try button("123", in: keyboard)
        numeric.sendActions(for: .touchUpInside); keyboard.layoutIfNeeded()
        let symbols = try button("#+=", in: keyboard)
        keyboard.beginContact(id, at: symbols.center)
        let hash = try button("#", in: keyboard)
        keyboard.moveContact(id, to: hash.center); keyboard.endContact(id, at: hash.center)
        XCTAssertEqual(text, "A#")
        XCTAssertEqual(keyboard.interaction.page, .numbers)
    }
    @MainActor
    func testPopupSnapshotAndSpellingSuggestionKeepSpace() throws {
        let keyboard = LocalKeyboardView(frame: CGRect(x: 0, y: 0, width: 390, height: 250))
        keyboard.backgroundColor = UIColor(red: 0.82, green: 0.83, blue: 0.85, alpha: 1)
        keyboard.autocapitalizationType = .none
        var text = "helo"
        keyboard.contextBeforeInput = { text }
        keyboard.insertText = { text += $0 }; keyboard.deleteText = { if !text.isEmpty { text.removeLast() } }
        keyboard.synchronizeCapitalization(); keyboard.layoutIfNeeded()
        let suggestions = try XCTUnwrap(keyboard.subviews.first { $0.accessibilityIdentifier == "SpellingSuggestions" })
        XCTAssertFalse(suggestions.subviews.compactMap { $0 as? UIButton }.isEmpty)
        let tokens = [NSObject(), NSObject()]
        let a = try button("a", in: keyboard), b = try button("b", in: keyboard)
        keyboard.beginContact(ObjectIdentifier(tokens[0]), at: a.center)
        // A second input commits the first; only the newest uncommitted key retains a preview.
        keyboard.beginContact(ObjectIdentifier(tokens[1]), at: b.center)
        let attachment = XCTAttachment(image: UIGraphicsImageRenderer(bounds: keyboard.bounds).image { context in keyboard.layer.render(in: context.cgContext) })
        attachment.name = "AirType rounded keys and rollover preview"; attachment.lifetime = .keepAlways; add(attachment)
        keyboard.cancelTouches()
        let source = text
        keyboard.synchronizeCapitalization()
        let choice = try XCTUnwrap(suggestions.subviews.compactMap { $0 as? UIButton }.first)
        choice.sendActions(for: .touchUpInside)
        XCTAssertTrue(text.hasSuffix(" "))
        XCTAssertEqual(text, source + " ")
    }
    @MainActor
    func testSpaceHoldMovesCursorWithoutInsertingAndDeleteCancelsOnHide() async throws {
        let keyboard = LocalKeyboardView(frame: CGRect(x: 0, y: 0, width: 390, height: 250))
        keyboard.layoutIfNeeded()
        var inserted = "", moves = 0, deletes = 0
        keyboard.insertText = { inserted += $0 }; keyboard.moveCursor = { moves += $0 }; keyboard.deleteText = { deletes += 1 }
        let token = NSObject(), id = ObjectIdentifier(token), space = try button("space", in: keyboard)
        keyboard.beginContact(id, at: space.center)
        try await Task.sleep(for: .milliseconds(450))
        keyboard.moveContact(id, to: CGPoint(x: space.center.x + 25, y: space.center.y))
        keyboard.endContact(id, at: space.center)
        XCTAssertEqual(moves, 2); XCTAssertEqual(inserted, "")
        let delete = try XCTUnwrap(keyboard.subviews.compactMap { $0 as? UIButton }.first { $0.accessibilityLabel == "Delete" })
        keyboard.beginContact(id, at: delete.center)
        XCTAssertEqual(deletes, 1)
        try await Task.sleep(for: .milliseconds(1150))
        XCTAssertGreaterThan(deletes, 1)
        keyboard.cancelTouches(); let count = deletes
        try await Task.sleep(for: .milliseconds(150))
        XCTAssertEqual(deletes, count)
    }
}

extension LocalKeyboardTouchTests {
    @MainActor
    func testStaleSpellingChoiceCannotReplaceSelectedTextOrChangedContext() throws {
        let keyboard = LocalKeyboardView()
        var context = "helo", selected = false, mutations = 0
        keyboard.contextBeforeInput = { context }; keyboard.hasSelection = { selected }
        keyboard.insertText = { _ in mutations += 1 }; keyboard.deleteText = { mutations += 1 }
        keyboard.synchronizeCapitalization()
        let row = try XCTUnwrap(keyboard.subviews.first { $0.accessibilityIdentifier == "SpellingSuggestions" })
        let choice = try XCTUnwrap(row.subviews.compactMap { $0 as? UIButton }.first)
        selected = true; choice.sendActions(for: .touchUpInside)
        XCTAssertEqual(mutations, 0)
        selected = false; context = "different helo"; choice.sendActions(for: .touchUpInside)
        XCTAssertEqual(mutations, 0)
    }
}
