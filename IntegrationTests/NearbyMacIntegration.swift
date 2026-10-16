import Foundation
import Combine
import Darwin

let externalKeyboard = CommandLine.arguments.contains("--keyboard-preview")
let name = externalKeyboard ? "AirType preview" : "AirType keyboard check " + UUID().uuidString.prefix(8)
let receiver = NearbyReceiver(displayName: name)
let sender = NearbyController()
var inputText = ""
receiver.onCommand = { packet in
    NativeKeyboardInput(insert: { inputText += $0 }, delete: { if !inputText.isEmpty { inputText.removeLast() } }, move: { _ in }).execute(packet)
}
if externalKeyboard {
    print("Enter the pairing key shown in the running iOS keyboard preview:")
    var original = termios()
    let hasTerminal = tcgetattr(STDIN_FILENO, &original) == 0
    if hasTerminal { var hidden = original; hidden.c_lflag &= ~tcflag_t(ECHO); tcsetattr(STDIN_FILENO, TCSANOW, &hidden) }
    sender.pairingKey = readLine() ?? ""
    if hasTerminal { tcsetattr(STDIN_FILENO, TCSANOW, &original); print("") }
} else { sender.pairingKey = receiver.pairingKey }
let sample = "Mac → AirType keyboard — 你好 👋"
var subscriptions = Set<AnyCancellable>()
var didConnect = false, didSend = false
sender.$peers.sink { peers in
    if let peer = peers.first(where: { $0.name == name }), !didConnect {
        didConnect = true
        DispatchQueue.main.async { sender.connect(peer) }
    }
}.store(in: &subscriptions)
sender.$connected.sink { connected in
    if connected && !didSend {
        didSend = true
        DispatchQueue.main.async { sender.draft = sample; sender.send(.insert) }
    }
}.store(in: &subscriptions)
sender.$busy.sink { busy in
    guard !busy, didSend else { return }
    DispatchQueue.main.async {
        if sender.draft.isEmpty && (externalKeyboard || inputText == sample) {
            print("PASS: Mac sender discovered the keyboard receiver, paired, sent Unicode, received acknowledgement, and cleared its confirmed draft")
            sender.disconnect(); receiver.stopWiFi(); exit(0)
        }
    }
}.store(in: &subscriptions)
DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
    print("FAIL: \(sender.status); receiver: \(receiver.wifiStatus)")
    sender.disconnect(); receiver.stopWiFi(); exit(1)
}
if !externalKeyboard { receiver.startWiFi() }
sender.discover()
dispatchMain()
