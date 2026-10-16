import SwiftUI

@main
struct AirTypeMacApp: App {
    @StateObject private var sender = NearbyController()
    var body: some Scene {
        WindowGroup("AirType Desktop") {
            DesktopSenderView(sender: sender).frame(minWidth: 570, minHeight: 650)
        }.defaultSize(width: 630, height: 740)
    }
}

struct DesktopSenderView: View {
    @ObservedObject var sender: NearbyController
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Label("AirType Desktop", systemImage: "laptopcomputer.and.iphone").font(.largeTitle)
                Text("Mac → iPhone / iPad keyboard").font(.headline)
                Text("Open a text field on your phone, switch to AirType, and choose Direct Wi-Fi or Bluetooth on the keyboard. This Mac sends text into that active field.")
                    .foregroundStyle(.secondary)
                GroupBox("Connect to your keyboard") {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Connection", selection: $sender.transport) {
                            ForEach(NearbyTransport.allCases) { mode in Text(mode.rawValue).tag(mode) }
                        }.pickerStyle(.segmented)
                        TextField("20-character pairing key shown on the keyboard", text: $sender.pairingKey)
                            .textFieldStyle(.roundedBorder).font(.system(.body, design: .monospaced))
                            .disabled(sender.connected || sender.busy)
                        HStack {
                            Button("Find keyboards") { sender.discover() }.disabled(sender.busy)
                            if sender.connected || sender.busy { Button("Disconnect") { sender.disconnect() } }
                            if sender.searching { ProgressView().controlSize(.small) }
                        }
                        ForEach(sender.peers) { peer in
                            Button { sender.connect(peer) } label: {
                                Label(peer.name, systemImage: "iphone")
                            }.disabled(sender.busy || sender.connected)
                        }
                        Text(sender.status).font(.caption).foregroundStyle(.secondary)
                    }.padding(8)
                }
                GroupBox("Type on your Mac, send to your phone") {
                    VStack(alignment: .leading, spacing: 12) {
                        TextEditor(text: $sender.draft).frame(minHeight: 140)
                            .font(.system(size: 18)).accessibilityLabel("Text to send to iPhone keyboard")
                        HStack {
                            Button("Send text", systemImage: "paperplane.fill") { sender.send(.insert) }
                                .buttonStyle(.borderedProminent).disabled(!sender.connected || sender.busy || sender.draft.isEmpty)
                            Spacer()
                            key("Delete", "delete.left", .delete)
                            key("Return", "return", .newline)
                            key("Tab", "arrow.right.to.line", .tab)
                            key("Move left", "arrow.left", .left)
                            key("Move right", "arrow.right", .right)
                        }
                        Text("Keep the phone's AirType keyboard visible. Unconfirmed drafts are kept and never automatically resent. Arrow controls adjust the phone's insertion point where the host app permits.")
                            .font(.caption).foregroundStyle(.secondary)
                    }.padding(8)
                }
                Text("Developer build · Direct Wi-Fi uses Apple peer-to-peer-enabled networking; Bluetooth uses a custom BLE service. The browser Web mode remains available separately. No Mac Accessibility permission is needed.")
                    .font(.caption).foregroundStyle(.secondary)
            }.padding(28)
        }.tint(Color(red: 0.35, green: 0.38, blue: 0.78))
            .onChange(of: sender.transport) { _, _ in sender.disconnect(); sender.discover() }
    }
    private func key(_ title: String, _ symbol: String, _ action: NearbyPacket.Action) -> some View {
        Button { sender.send(action) } label: { Image(systemName: symbol) }
            .help(title).accessibilityLabel(title).disabled(!sender.connected || sender.busy)
    }
}
