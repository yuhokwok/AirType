import UIKit

/// The same prose-capitalization and delete cadence used by CInput's basic keys.
enum KeyboardTypingBehavior {
    static func automaticShift(type: UITextAutocapitalizationType, context: String?) -> Bool? {
        switch type {
        case .none: return false
        case .allCharacters: return true
        case .words:
            guard let context else { return nil }
            return context.isEmpty || context.last?.isWhitespace == true
        case .sentences:
            guard let context else { return nil }
            if context.isEmpty { return true }
            let whitespace = context.reversed().prefix { $0.isWhitespace }
            guard !whitespace.isEmpty else { return false }
            if whitespace.contains(where: { $0.isNewline }) { return true }
            let text = context.dropLast(whitespace.count)
            return text.isEmpty || text.last.map { ".!?。！？".contains($0) } == true
        @unknown default: return false
        }
    }

    static func deleteInterval(leftDrag: CGFloat) -> TimeInterval {
        let progress = min(1, max(0, leftDrag - 8) / 88)
        return (100 - 65 * progress).rounded() / 1000
    }
}
