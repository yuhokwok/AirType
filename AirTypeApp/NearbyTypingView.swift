import SwiftUI

struct AirTypeHomeView: View {
    var body: some View {
        TabView {
            NearbyTypingView().tabItem { Label("Type to Mac", systemImage: "laptopcomputer.and.iphone") }
            SetupView().tabItem { Label("Keyboard setup", systemImage: "keyboard") }
        }.tint(Color(red: 0.35, green: 0.38, blue: 0.78))
    }
}

struct NearbyTypingView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var controller = NearbyController()
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("iPhone → Mac", systemImage: "laptopcomputer.and.iphone").font(.headline)
                    Text("Open AirType Receiver on your Mac. Choose a connection, enter its pairing key, then select your Mac.")
                        .foregroundStyle(.secondary)
                } header: { Text("Nearby typing · Developer version") }
                Section {
                    Picker("Connection", selection: $controller.transport) {
                        ForEach(NearbyTransport.allCases) { transport in Text(transport.rawValue).tag(transport) }
                    }.pickerStyle(.segmented)
                    Text(controller.transport == .wifi
                        ? "Apple peer-to-peer Wi-Fi. Keep Wi-Fi enabled on both devices. A shared router is not required; macOS may use your existing network when available."
                        : "Custom Bluetooth LE connection to AirType Receiver. This version does not pair as a standard Bluetooth keyboard.")
                        .font(.footnote).foregroundStyle(.secondary)
                    TextField("Pairing key shown on Mac", text: $controller.pairingKey)
                        .textInputAutocapitalization(.characters).autocorrectionDisabled()
                        .font(.system(.body, design: .monospaced))
                        .disabled(controller.connected || controller.busy)
                    Button(controller.searching ? "Find receivers again" : "Find receivers", systemImage: "antenna.radiowaves.left.and.right") { controller.discover() }
                        .disabled(controller.busy)
                    ForEach(controller.peers) { peer in
                        Button { controller.connect(peer) } label: {
                            Label(peer.name, systemImage: "desktopcomputer")
                        }.disabled(controller.busy || controller.connected)
                    }
                    if controller.connected || controller.busy {
                        Button("Disconnect", role: .destructive) { controller.disconnect() }
                    }
                } header: { Text("Connect") }
                Section {
                    Text(controller.status).accessibilityLabel("Connection status: " + controller.status)
                    if controller.busy { ProgressView() }
                } header: { Text(controller.connected ? "Connected" : "Status") }
                Section {
                    TextEditor(text: $controller.draft).frame(minHeight: 125)
                        .accessibilityLabel("Text to send to Mac")
                    Button("Send text", systemImage: "paperplane.fill") { controller.send(.insert) }
                        .disabled(!controller.connected || controller.busy || controller.draft.isEmpty)
                    HStack {
                        key("Delete", "delete.left", .delete)
                        Spacer(); key("Return", "return", .newline)
                        Spacer(); key("Tab", "arrow.right.to.line", .tab)
                    }
                    HStack {
                        key("Escape", "escape", .escape)
                        Spacer(); key("Left", "arrow.left", .left)
                        key("Up", "arrow.up", .up)
                        key("Down", "arrow.down", .down)
                        key("Right", "arrow.right", .right)
                    }
                } header: { Text("Type") } footer: {
                    Text("The Mac receiver starts in preview mode. Enable typing into other apps there when ready. Keep AirType open on your iPhone. If delivery is not confirmed, the draft is kept and is not automatically resent.")
                }
            }.navigationTitle("AirType")
                .onChange(of: controller.transport) { controller.disconnect(); controller.discover() }
                .onChange(of: controller.connected) { UIApplication.shared.isIdleTimerDisabled = controller.connected }
                .onChange(of: scenePhase) {
                    if scenePhase == .background { controller.disconnect(); UIApplication.shared.isIdleTimerDisabled = false }
                }
                .onDisappear { controller.disconnect(); UIApplication.shared.isIdleTimerDisabled = false }
        }
    }
    private func key(_ title: String, _ symbol: String, _ action: NearbyPacket.Action) -> some View {
        Button { controller.send(action) } label: { Image(systemName: symbol).frame(minWidth: 30, minHeight: 36) }
            .buttonStyle(.bordered).accessibilityLabel(title)
            .disabled(!controller.connected || controller.busy)
    }
}
