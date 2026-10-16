import SwiftUI
import CoreBluetooth
import Combine

struct AirTypeHomeView: View {
    var body: some View {
        if AirTypeFeatures.nearbyTypingEnabled {
            TabView {
                KeyboardConnectionView().tabItem { Label("Connect", systemImage: "laptopcomputer.and.iphone") }
                SetupView().tabItem { Label("Keyboard setup", systemImage: "keyboard") }
            }.tint(Color(red: 0.35, green: 0.38, blue: 0.78))
        } else {
            SetupView()
        }
    }
}

struct KeyboardConnectionView: View {
    @State private var mode = NetworkPreferences.inputMode
    @StateObject private var bluetooth = KeyboardBluetoothPermission()
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("Computer → iPhone keyboard", systemImage: "keyboard").font(.headline)
                    Text("Type on your computer. The AirType keyboard receives the text and inserts it into the app you are using on your iPhone or iPad.")
                } header: { Text("AirType") }
                Section {
                    Picker("Connection", selection: $mode) {
                        ForEach(RemoteInputMode.allCases) { mode in Text(mode.rawValue).tag(mode) }
                    }.pickerStyle(.segmented)
                    Text(mode == .web
                        ? "Use a browser on your computer and the address shown on the keyboard. Both devices must be on the same Wi-Fi."
                        : "Use AirType Desktop on your Mac. Find this keyboard, then enter the 20-character pairing key displayed on it.")
                        .font(.footnote).foregroundStyle(.secondary)
                    if mode == .wifi {
                        Text("Direct Wi-Fi uses Apple's peer-to-peer networking. Keep Wi-Fi enabled on both devices. The keyboard must stay visible while receiving.")
                    }
                    if mode == .bluetooth {
                        Button("Enable Bluetooth access") { bluetooth.request() }
                        Text(bluetooth.status).font(.footnote).foregroundStyle(.secondary)
                        Text("Developer Bluetooth LE transport. It connects the Mac sender to the keyboard; it does not turn your iPhone into a Bluetooth keyboard for the Mac.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                } header: { Text("Keyboard connection") } footer: {
                    Text("Saved for the next time you open the keyboard. You can also change connection mode directly on the keyboard.")
                }
                Section {
                    Text("1. Add AirType in system keyboard settings and allow Full Access.")
                    Text("2. Open a text field in any supported app, switch to AirType, and keep its connection panel visible.")
                    Text("3. Connect from the computer using the code or key shown on the keyboard.")
                    NavigationLink("Try the installed keyboard") {
                        KeyboardTestScreen(useSystemKeyboard: true).ignoresSafeArea(.keyboard).navigationTitle("Try AirType")
                    }
                } header: { Text("Start typing into your phone") }
                Section {
                    Text("This app prepares settings and permissions. Receiving and text insertion run inside the visible keyboard extension; this app does not need to stay in the foreground.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }.navigationTitle("AirType")
                .onChange(of: mode) { NetworkPreferences.inputMode = mode }
                .onAppear { mode = NetworkPreferences.inputMode }
        }
    }
}

final class KeyboardBluetoothPermission: NSObject, ObservableObject, CBPeripheralManagerDelegate {
    @Published private(set) var status = "Allow Bluetooth here before trying Bluetooth in the keyboard."
    private var manager: CBPeripheralManager?
    func request() {
        if manager == nil { manager = CBPeripheralManager(delegate: self, queue: .main) }
        else if let manager { peripheralManagerDidUpdateState(manager) }
    }
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn: status = "Bluetooth is ready. Now open the AirType keyboard in a text field."
        case .poweredOff: status = "Turn on Bluetooth in Settings."
        case .unauthorized: status = "Allow AirType Bluetooth access in Settings → Privacy & Security → Bluetooth."
        case .unsupported: status = "Bluetooth requires a supported physical device."
        default: status = "Bluetooth is preparing. Try again when ready."
        }
    }
}
