import Foundation
import Combine
import Darwin
let name = "AirType integration " + UUID().uuidString.prefix(8)
let receiver = MacReceiver(displayName: name)
let sender = NearbyController()
sender.pairingKey = receiver.pairingKey
let sample = "Native Wi-Fi integration — 你好 👋"
var subscriptions = Set<AnyCancellable>()
var didConnect = false
var didSend = false
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
        if receiver.receivedText == sample && sender.draft.isEmpty {
            print("PASS: native Bonjour discovery, encrypted pairing, Unicode command, receiver preview, acknowledgement and draft clearing")
            sender.disconnect(); receiver.stopWiFi(); exit(0)
        }
    }
}.store(in: &subscriptions)
DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
    print("FAIL: \(sender.status); receiver: \(receiver.wifiStatus)")
    sender.disconnect(); receiver.stopWiFi(); exit(1)
}
receiver.startWiFi(); sender.discover()
dispatchMain()
