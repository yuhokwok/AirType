import Foundation
import CoreGraphics

/// Called only after explicit receiver opt-in and Accessibility permission.
enum MacInputInjector {
    static func post(_ packet: NearbyPacket) -> Bool {
        guard let action = packet.action else { return false }
        if action == .insert {
            for chunk in NearbyTextChunks.utf16(packet.text ?? "") {
                guard let down = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true),
                      let up = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) else { return false }
                chunk.withUnsafeBufferPointer { down.keyboardSetUnicodeString(stringLength: $0.count, unicodeString: $0.baseAddress) }
                down.post(tap: .cghidEventTap); up.post(tap: .cghidEventTap)
            }
            return true
        }
        let codes: [NearbyPacket.Action: CGKeyCode] = [.delete: 51, .newline: 36, .tab: 48, .escape: 53, .left: 123, .right: 124, .down: 125, .up: 126]
        guard let code = codes[action], let down = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: true),
              let up = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: false) else { return false }
        down.post(tap: .cghidEventTap); up.post(tap: .cghidEventTap); return true
    }
}
