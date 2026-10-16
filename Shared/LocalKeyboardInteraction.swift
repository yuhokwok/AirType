import Foundation

enum LocalKeyboardPage: Int { case letters, numbers, symbols }
enum LocalKeyboardKey: Equatable {
    case character(String), shift, layout(LocalKeyboardPage), space, delete, enter, wifi, globe
    var isInput: Bool { if case .character = self { return true }; return self == .space }
}

/// One owner per contact, matching CInput's press-order rollover and temporary modifiers.
struct LocalKeyboardInteraction<ID: Hashable> {
    enum Shift { case off, once, locked }
    enum Action: Equatable { case insert(String), delete, beginDelete, endDelete, wifi, enter }
    struct Contact {
        let origin: LocalKeyboardKey
        var current: LocalKeyboardKey?
        let uppercase: Bool
        let shiftBefore: Shift
        let pageBefore: LocalKeyboardPage
        let tapCount: Int
        var committed = false
        var used = false
    }
    private(set) var page = LocalKeyboardPage.letters
    private(set) var shift = Shift.once
    private(set) var contacts: [ID: Contact] = [:]
    private var order: [ID] = []
    private var manualAnchor: String?
    private var hasManualShift = false
    var uppercase: Bool { shift != .off || contacts.values.contains { $0.origin == .shift } }
    var hasContacts: Bool { !contacts.isEmpty }
    var heldShift: Bool { contacts.values.contains { $0.origin == .shift } }

    mutating func synchronizeShift(_ value: Bool?, context: String?) {
        guard !heldShift, shift != .locked, !(hasManualShift && manualAnchor == context), let value else { return }
        hasManualShift = false; shift = value ? .once : .off
    }
    mutating func begin(_ id: ID, key: LocalKeyboardKey, tapCount: Int = 1, context: String? = nil) -> [Action] {
        guard contacts[id] == nil else { return [] }
        var actions: [Action] = []
        if key.isInput {
            for older in order {
                guard let old = contacts[older], old.origin.isInput, !old.committed else { continue }
                actions += commit(old.origin, uppercase: old.uppercase)
                contacts[older]?.committed = true
            }
        }
        if key.isInput {
            for owner in order where isLayout(contacts[owner]?.origin) { contacts[owner]?.used = true }
        }
        let contact = Contact(origin: key, current: key, uppercase: uppercase, shiftBefore: shift, pageBefore: page, tapCount: tapCount)
        contacts[id] = contact; order.append(id)
        switch key {
        case .shift: if shift == .off { shift = .once }
        case .layout(let destination): page = destination
        case .delete: actions += [.delete, .beginDelete]
        default: break
        }
        return actions
    }
    mutating func move(_ id: ID, to key: LocalKeyboardKey?) { contacts[id]?.current = key }
    mutating func end(_ id: ID, on destination: LocalKeyboardKey?, context: String? = nil) -> [Action] {
        guard let contact = contacts[id] else { return [] }
        var actions: [Action] = []
        switch contact.origin {
        case .shift:
            if case .character = destination, !contact.committed, let destination {
                actions += commit(destination, uppercase: true)
                shift = contact.shiftBefore == .locked ? .locked : .off
            } else if destination == .shift && !contact.used {
                if contact.tapCount == 2 { shift = .locked }
                else { shift = contact.shiftBefore == .off ? .once : .off }
                hasManualShift = true; manualAnchor = context
            } else if contact.used && shift != .locked { shift = .off }
            else { shift = contact.shiftBefore }
        case .layout:
            if case .character = destination, !contact.committed, let destination {
                actions += commit(destination, uppercase: false); page = contact.pageBefore
            } else if contact.used { page = contact.pageBefore }
        case .delete: actions.append(.endDelete)
        case .wifi: if destination == .wifi { actions.append(.wifi) }
        case .enter: if destination == .enter { actions.append(.enter) }
        case .globe: break
        default:
            if !contact.committed, let destination, destination.isInput {
                let key = contact.pageBefore == page ? destination : contact.origin
                actions += commit(key, uppercase: contact.uppercase)
            }
        }
        contacts.removeValue(forKey: id); order.removeAll { $0 == id }
        return actions
    }
    mutating func cancel(_ id: ID) -> [Action] {
        guard let contact = contacts.removeValue(forKey: id) else { return [] }
        order.removeAll { $0 == id }
        switch contact.origin {
        case .shift: shift = contact.used && contact.shiftBefore != .locked ? .off : contact.shiftBefore
        case .layout: page = contact.pageBefore
        case .delete: return [.endDelete]
        default: break
        }
        return []
    }
    mutating func cancelAll() {
        // Reverse order restores the exact source of nested temporary switches.
        for id in order.reversed() { _ = cancel(id) }
    }
    private mutating func commit(_ key: LocalKeyboardKey, uppercase: Bool) -> [Action] {
        let text: String
        switch key {
        case .character(let value): text = uppercase ? value.uppercased() : value
        case .space: text = " "
        default: return []
        }
        for id in order where contacts[id]?.origin == .shift || isLayout(contacts[id]?.origin) { contacts[id]?.used = true }
        if case .character = key, shift == .once && !heldShift { shift = .off }
        hasManualShift = false
        return [.insert(text)]
    }
    private func isLayout(_ key: LocalKeyboardKey?) -> Bool { if case .layout = key { return true }; return false }
}
