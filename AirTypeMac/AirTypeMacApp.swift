import SwiftUI

@main
struct AirTypeMacApp: App {
    @StateObject private var receiver = MacReceiver()
    var body: some Scene {
        WindowGroup("AirType Receiver") {
            ReceiverView(receiver: receiver).frame(minWidth: 580, minHeight: 620)
        }.defaultSize(width: 650, height: 730)
    }
}

struct ReceiverView: View {
    @ObservedObject var receiver: MacReceiver
    private var formattedKey: String {
        stride(from: 0, to: receiver.pairingKey.count, by: 5).map { offset in
            let start = receiver.pairingKey.index(receiver.pairingKey.startIndex, offsetBy: offset)
            return String(receiver.pairingKey[start..<receiver.pairingKey.index(start, offsetBy: 5)])
        }.joined(separator: "-")
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Label("AirType Receiver", systemImage: "laptopcomputer.and.iphone").font(.largeTitle)
                Text("Type from your iPhone or iPad to this Mac. Start a transport, then find this receiver in the AirType host app.")
                    .foregroundStyle(.secondary)
                GroupBox("Pairing key") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(formattedKey).font(.system(.title2, design: .monospaced)).textSelection(.enabled)
                        HStack {
                            ShareLink(item: receiver.pairingKey) { Label("Share key", systemImage: "square.and.arrow.up") }
                            Button("New key & disconnect") { receiver.rotateKey() }
                        }
                        Text("Enter this key on your iPhone. Commands are authenticated and encrypted over both transports.")
                            .font(.caption).foregroundStyle(.secondary)
                    }.padding(8).frame(maxWidth: .infinity, alignment: .leading)
                }
                GroupBox("Connections") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Direct Wi-Fi", systemImage: "wifi"); Spacer()
                            Button(receiver.wifiRunning ? "Stop Wi-Fi" : "Start Wi-Fi") {
                                if receiver.wifiRunning { receiver.stopWiFi() } else { receiver.startWiFi() }
                            }
                        }
                        Text(receiver.wifiStatus).font(.caption).foregroundStyle(.secondary)
                        Divider()
                        HStack {
                            Label("Bluetooth LE", systemImage: "antenna.radiowaves.left.and.right"); Spacer()
                            Button(receiver.bluetoothRunning ? "Stop Bluetooth" : "Start Bluetooth") {
                                if receiver.bluetoothRunning { receiver.stopBluetooth() } else { receiver.startBluetooth() }
                            }
                        }
                        Text(receiver.bluetoothStatus).font(.caption).foregroundStyle(.secondary)
                        Text("Connections: \(receiver.connections)").font(.caption)
                    }.padding(8)
                }
                Toggle("Type into the focused Mac app", isOn: $receiver.typeIntoApps)
                if receiver.typeIntoApps {
                    HStack {
                        Text("Allow Accessibility, then focus the destination app on this Mac.").font(.caption).foregroundStyle(.secondary)
                        Button("Allow Accessibility…") { receiver.requestAccessibility() }
                    }
                } else {
                    Text("Preview mode: received text appears below. Nothing is typed into other apps.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                GroupBox("Received preview") {
                    VStack(alignment: .leading) {
                        Text(receiver.receivedText.isEmpty ? "Waiting for text…" : receiver.receivedText)
                            .textSelection(.enabled).frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
                            .accessibilityLabel("Received text: " + receiver.receivedText)
                        HStack { Text(receiver.lastAction).font(.caption).foregroundStyle(.secondary); Spacer(); Button("Clear") { receiver.clearPreview() } }
                    }.padding(8)
                }
                Text("Developer build · Apple peer-to-peer Wi-Fi and custom BLE require native apps at both ends. Bluetooth HID emulation is not included. Validate both transports on physical devices.")
                    .font(.caption).foregroundStyle(.secondary)
            }.padding(28)
        }.tint(Color(red: 0.35, green: 0.38, blue: 0.78))
    }
}
