import SwiftUI
import Network

@main
struct AirTypeApp: App {
    var body: some Scene {
        WindowGroup {
            if ProcessInfo.processInfo.arguments.contains("--keyboard-demo") {
                KeyboardTestScreen(useSystemKeyboard: false).ignoresSafeArea(.keyboard)
            } else if ProcessInfo.processInfo.arguments.contains("--system-test") {
                KeyboardTestScreen(useSystemKeyboard: true).ignoresSafeArea(.keyboard)
            } else { SetupView() }
        }
    }
}

struct SetupView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var networkCheck = LocalNetworkCheck()
    @State private var bonjourName = NetworkPreferences.hostname
    @State private var nameSaved = false
    @State private var settingsUnavailable = false
    private let cyan = Color(red:0.08,green:0.75,blue:0.79)
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing:24) {
                    Image("AirTypeLogo").resizable().frame(width:104,height:104).clipShape(.rect(cornerRadius:24))
                    VStack(spacing:8) {
                        Text("AirType").font(.system(size:36,weight:.light))
                        Text("Type from the computer\nyou’re working on.").font(.title3).foregroundStyle(cyan).multilineTextAlignment(.center)
                    }
                    VStack(alignment:.leading,spacing:20) {
                        step("1", "Add the keyboard", "Settings → General → Keyboard → Keyboards → Add New Keyboard → AirType.")
                        step("2", "Allow Full Access", "Tap AirType in Keyboards and enable Allow Full Access for the Wi-Fi connection. Local typing works without it.")
                        step("3", "Connect your computer", "Switch to AirType with the globe key. Open its address on a computer using the same Wi-Fi, then enter the six-digit code shown on the keyboard.")
                    }
                    Button {
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        openURL(url) { accepted in settingsUnavailable = !accepted }
                    } label: {
                        Label("Open Keyboard Settings", systemImage: "keyboard")
                            .frame(maxWidth: .infinity).padding(6)
                    }.buttonStyle(.borderedProminent).tint(cyan)
                    Text("In AirType settings, choose Keyboards, enable AirType, then Allow Full Access. If Keyboards is unavailable, use Settings → General → Keyboard → Keyboards → Add New Keyboard.")
                        .font(.footnote).foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Bonjour address").font(.headline)
                        HStack {
                            TextField("airtype", text: $bonjourName)
                                .textInputAutocapitalization(.never).autocorrectionDisabled()
                                .textFieldStyle(.roundedBorder)
                                .accessibilityLabel("Bonjour name")
                                .onChange(of: bonjourName) { nameSaved = false }
                            Text(".local").foregroundStyle(.secondary)
                        }
                        Button("Save Bonjour Name") {
                            NetworkPreferences.saveHostname(bonjourName)
                            bonjourName = NetworkPreferences.hostname
                            nameSaved = true
                        }.buttonStyle(.bordered).tint(cyan)
                        Text(nameSaved ? "Saved. Reopen the AirType keyboard to apply." : "Default: airtype.local:8307. Name conflicts automatically use -2, -3, and so on. Use the final address shown on the keyboard; its IP address remains available as a fallback.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Button(networkCheck.state == .checking ? "Checking local network…" : "Enable local network connection") {
                            networkCheck.start()
                        }.buttonStyle(.bordered).tint(cyan)
                            .disabled(networkCheck.state == .checking)
                        Text(networkMessage).font(.footnote).foregroundStyle(.secondary)
                        if networkCheck.state == .blocked {
                            Button("Open AirType Settings") { openAppSettings() }
                                .buttonStyle(.bordered).tint(cyan)
                        }
                        Text("Local Network permission and keyboard Full Access are separate. Keep the AirType keyboard’s Web Access screen visible while connecting from your computer.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    NavigationLink { KeyboardTestScreen(useSystemKeyboard:true).ignoresSafeArea(.keyboard).navigationTitle("Try AirType") } label: {
                        Text("Try the installed keyboard").frame(maxWidth:.infinity).padding(6)
                    }.buttonStyle(.borderedProminent).tint(cyan)
                    NavigationLink("Preview keyboard & Web Access") { KeyboardTestScreen(useSystemKeyboard:false).ignoresSafeArea(.keyboard).navigationTitle("Keyboard preview") }
                    Text("Text travels over your local network. AirType has no cloud service and does not store your typing. Keep the keyboard visible while sending. Use a trusted Wi-Fi network.").font(.footnote).foregroundStyle(.secondary)
                    HStack(spacing:0) {
                        ForEach(0..<6) { index in Rectangle().fill([Color(red:0.6,green:1,blue:0.89),Color(red:0.59,green:0.96,blue:1),Color(red:0.53,green:0.76,blue:1),Color(red:0.48,green:0.35,blue:1),Color(red:0.71,green:0.35,blue:0.98),Color(red:0.85,green:0.35,blue:0.99)][index]) }
                    }.frame(height:12)
                    Text("invivo").font(.footnote).foregroundStyle(.secondary)
                }.padding(28).frame(maxWidth:600).frame(maxWidth:.infinity)
            }.background(Color(.systemBackground))
                .onChange(of: scenePhase) {
                    if scenePhase == .active && networkCheck.hasRequested { networkCheck.start() }
                }
                .onDisappear { networkCheck.stop() }
                .alert("Open Settings manually", isPresented: $settingsUnavailable) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Open Settings → General → Keyboard → Keyboards → Add New Keyboard → AirType.")
                }
        }
    }
    private func step(_ number:String,_ title:String,_ detail:String) -> some View {
        HStack(alignment:.top,spacing:14) {
            Text(number).font(.headline).foregroundStyle(cyan).frame(width:28,height:28).background(cyan.opacity(0.1),in:.circle)
            VStack(alignment:.leading,spacing:5) { Text(title).font(.headline); Text(detail).font(.subheadline).foregroundStyle(.secondary) }
        }
    }
    private var networkMessage: String {
        switch networkCheck.state {
        case .idle: return "Tap to request Local Network access in this app before using the keyboard."
        case .checking: return "Choose Allow if iOS asks for Local Network access. Checking Bonjour…"
        case .available: return "Bonjour check passed on this device. Now switch to the AirType keyboard, keep Web Access visible, and open its full http:// address on your computer."
        case .blocked: return "Local Network access is blocked or awaiting approval. Choose Allow on the prompt, or enable AirType in Settings → Privacy & Security → Local Network, then return here."
        case .failed(let message): return message
        }
    }
    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url) { accepted in settingsUnavailable = !accepted }
    }
}

struct KeyboardTestScreen: UIViewControllerRepresentable {
    let useSystemKeyboard: Bool
    func makeUIViewController(context: Context) -> KeyboardTestController { KeyboardTestController(useSystemKeyboard:useSystemKeyboard) }
    func updateUIViewController(_ controller: KeyboardTestController,context:Context) {}
}
