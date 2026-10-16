import Foundation

/// The only native command destination is the active keyboard's document proxy.
/// The closures also let the host preview use a real UITextView for development.
struct NativeKeyboardInput {
    var insert: (String) -> Void
    var delete: () -> Void
    var move: (Int) -> Void
    func execute(_ packet: NearbyPacket) -> String? {
        guard packet.validCommand, let action = packet.action else { return "Invalid keyboard command." }
        switch action {
        case .insert: insert(packet.text ?? "")
        case .delete: delete()
        case .newline: insert("\n")
        case .tab: insert("\t")
        case .left: move(-1)
        case .right: move(1)
        case .up, .down, .escape:
            return "This key is not supported by the iOS keyboard text interface."
        }
        return nil
    }
}
