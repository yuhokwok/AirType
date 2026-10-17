import SwiftUI
import Network

@main
struct AirTypeApp: App {
    var body: some Scene {
        WindowGroup {
            if ProcessInfo.processInfo.arguments.contains("--keyboard-demo") || ProcessInfo.processInfo.arguments.contains("--keyboard-qwerty") || ProcessInfo.processInfo.arguments.contains("--native-keyboard-wifi") || ProcessInfo.processInfo.arguments.contains("--native-keyboard-bluetooth") {
                KeyboardTestScreen(useSystemKeyboard: false).ignoresSafeArea(.keyboard)
            } else if ProcessInfo.processInfo.arguments.contains("--system-test") {
                KeyboardTestScreen(useSystemKeyboard: true).ignoresSafeArea(.keyboard)
            } else { AirTypeHomeView() }
        }
    }
}

struct SetupView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var networkCheck = LocalNetworkCheck()
    @State private var settingsUnavailable = false
    private let accent = Color(red: 0.08, green: 0.67, blue: 0.72)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack(spacing: 14) {
                        Image("AirTypeLogo").resizable().scaledToFit()
                            .frame(width: 56, height: 56).clipShape(.rect(cornerRadius: 14))
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AirType").font(.title2.weight(.semibold))
                            Text(L10n.text("Type on your computer. Send to your iPhone."))
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }.padding(.bottom, 4)

                    SetupStepCard(number: "1", title: L10n.text("Set up the keyboard")) {
                        Text(L10n.text("Enable AirType and Allow Full Access in Settings."))
                            .font(.subheadline).foregroundStyle(.secondary)
                        Button(action: openAppSettings) {
                            Label(L10n.text("Open Keyboard Settings"), systemImage: "keyboard")
                                .frame(maxWidth: .infinity, minHeight: 32)
                        }.buttonStyle(.borderedProminent)
                    }
                    SetupStepCard(number: "2", title: L10n.text("Allow Local Network")) {
                        Text(networkCheck.state.setupMessage)
                            .font(.subheadline).foregroundStyle(.secondary)
                            .accessibilityIdentifier("NetworkSetupMessage")
                        if networkCheck.state == .blocked {
                            Button(action: openAppSettings) {
                                Label(L10n.text("Open Settings"), systemImage: "gearshape")
                                    .frame(maxWidth: .infinity, minHeight: 32)
                            }.buttonStyle(.bordered)
                        } else {
                            Button { networkCheck.start() } label: {
                                Label(networkCheck.state.setupAction, systemImage: networkCheck.state == .available ? "checkmark.circle" : "wifi")
                                    .frame(maxWidth: .infinity, minHeight: 32)
                            }.buttonStyle(.bordered).disabled(networkCheck.state == .checking)
                        }
                    }
                    SetupStepCard(number: "3", title: L10n.text("Try AirType")) {
                        Text(L10n.text("Open a text field and use the globe key to select AirType."))
                            .font(.subheadline).foregroundStyle(.secondary)
                        NavigationLink {
                            KeyboardTestScreen(useSystemKeyboard: true).ignoresSafeArea(.keyboard)
                                .navigationTitle(L10n.text("Try AirType")).navigationBarTitleDisplayMode(.inline)
                        } label: {
                            Label(L10n.text("Try AirType"), systemImage: "text.cursor")
                                .frame(maxWidth: .infinity, minHeight: 32)
                        }.buttonStyle(.bordered)
                    }
                    NavigationLink {
                        AdvancedSetupView(networkCheck: networkCheck)
                    } label: {
                        Label(L10n.text("Advanced settings"), systemImage: "slider.horizontal.3")
                            .font(.subheadline).frame(minHeight: 44)
                    }
                    AirTypeContactLinks()
                }
                .padding(20).frame(maxWidth: 560).frame(maxWidth: .infinity)
            }
            .background(Color(.systemGroupedBackground))
            .tint(accent)
            .onChange(of: scenePhase) {
                if scenePhase == .active && networkCheck.hasRequested { networkCheck.start() }
            }
            .onDisappear { networkCheck.stop() }
            .alert(L10n.text("Open Settings manually"), isPresented: $settingsUnavailable) {
                Button(L10n.text("OK"), role: .cancel) {}
            } message: {
                Text(L10n.text("Settings → General → Keyboard → Keyboards → Add New Keyboard → AirType. Then enable Allow Full Access."))
            }
        }
    }
    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url) { settingsUnavailable = !$0 }
    }
}

private struct SetupStepCard<Content: View>: View {
    let number: String
    let title: String
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(number).font(.subheadline.weight(.semibold))
                    .frame(width: 26, height: 26)
                    .background(Color.accentColor.opacity(0.12), in: .circle)
                    .foregroundStyle(.tint)
                Text(title).font(.headline)
            }.accessibilityElement(children: .combine)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))
    }
}

private struct AirTypeContactLinks: View {
    var body: some View {
        VStack(spacing: 4) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 20) { links }
                VStack(spacing: 0) { links }
            }.font(.subheadline).buttonStyle(.plain)
            Text("invivo").font(.caption).foregroundStyle(.secondary)
        }
    }
    @ViewBuilder private var links: some View {
        Link(destination: URL(string: "https://www.threads.com/@invivointeractive")!) {
            Label(L10n.text("Threads"), systemImage: "at").frame(minHeight: 44)
        }.accessibilityLabel(L10n.text("Threads: @invivointeractive"))
        Link(destination: URL(string: "http://www.invivointeractive.com/airtype")!) {
            Label(L10n.text("Website"), systemImage: "globe").frame(minHeight: 44)
        }.accessibilityLabel(L10n.text("AirType website"))
        Link(destination: URL(string: "mailto:info@invivovinteractive.com")!) {
            Label(L10n.text("Email"), systemImage: "envelope").frame(minHeight: 44)
        }.accessibilityLabel(L10n.text("Email info@invivovinteractive.com"))
    }
}

private struct AdvancedSetupView: View {
    @ObservedObject var networkCheck: LocalNetworkCheck
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @State private var bonjourName = NetworkPreferences.hostname
    @State private var nameSaved = false
    @State private var settingsUnavailable = false

    var body: some View {
        Form {
            Section {
                HStack {
                    TextField("airtype", text: $bonjourName)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .accessibilityLabel(L10n.text("Connection name"))
                        .onChange(of: bonjourName) { nameSaved = false }
                    Text(".local").foregroundStyle(.secondary)
                }
                Button(L10n.text("Save connection name")) {
                    NetworkPreferences.saveHostname(bonjourName)
                    bonjourName = NetworkPreferences.hostname; nameSaved = true
                }
                if nameSaved { Label(L10n.text("Saved. Reopen the keyboard to apply."), systemImage: "checkmark.circle").font(.footnote) }
            } header: {
                Text(L10n.text("Connection name"))
            } footer: {
                Text(L10n.text("Default: airtype.local:8307. If the name is already taken, AirType adds -2, -3, and so on. Use the address shown on the keyboard; its IP address is also available there."))
            }
            Section {
                Text(networkCheck.state.diagnosticMessage).font(.subheadline).textSelection(.enabled)
                Button(networkCheck.state == .checking ? L10n.text("Checking…") : L10n.text("Run network check")) { networkCheck.start() }
                    .disabled(networkCheck.state == .checking)
                Button(L10n.text("Open AirType Settings"), action: openAppSettings)
            } header: {
                Text(L10n.text("Network diagnostics"))
            } footer: {
                Text(L10n.text("This checks Bonjour on this device. A successful check does not confirm that your computer is connected."))
            }
            Section(L10n.text("Connection help")) {
                Text(L10n.text("Keep your computer and iPhone on the same Wi-Fi, and keep the AirType keyboard visible. Open the address displayed on the keyboard in your computer browser and enter its six-digit pairing code."))
                Text(L10n.text("If the name does not open, tap the keyboard’s address bar and try its IP fallback. Guest Wi-Fi, client isolation or a VPN may prevent the connection."))
            }
            Section(L10n.text("Keyboard setup help")) {
                Text(L10n.text("Settings → General → Keyboard → Keyboards → Add New Keyboard → AirType. Open AirType’s keyboard entry and enable Allow Full Access for networking."))
                Text(L10n.text("Local Network permission and keyboard Full Access are separate. The app cannot confirm your Full Access setting; check it in Settings if connection fails."))
            }
            Section {
                NavigationLink(L10n.text("Preview keyboard & Web Access")) {
                    KeyboardTestScreen(useSystemKeyboard: false).ignoresSafeArea(.keyboard)
                        .navigationTitle(L10n.text("Keyboard preview")).navigationBarTitleDisplayMode(.inline)
                }
            } header: {
                Text(L10n.text("Keyboard preview"))
            } footer: {
                Text(L10n.text("Preview works inside this app. It does not confirm that the system keyboard is enabled. Use Try AirType on the home screen to test the installed keyboard."))
            }
            Section(L10n.text("Privacy")) {
                Text(L10n.text("Full Access lets the keyboard connect to your computer. AirType uses your local network, has no cloud service and does not store your typing. Use a trusted Wi-Fi network."))
            }
        }
        .navigationTitle(L10n.text("Advanced settings")).navigationBarTitleDisplayMode(.inline)
        .onChange(of: scenePhase) {
            if scenePhase == .active && networkCheck.hasRequested { networkCheck.start() }
        }
        .onDisappear { networkCheck.stop() }
        .alert(L10n.text("Open Settings manually"), isPresented: $settingsUnavailable) {
            Button(L10n.text("OK"), role: .cancel) {}
        } message: {
            Text(L10n.text("Open Settings → Privacy & Security → Local Network to allow AirType."))
        }
    }
    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url) { settingsUnavailable = !$0 }
    }
}

private extension LocalNetworkCheck.State {
    var setupMessage: String {
        switch self {
        case .idle: L10n.text("Let your computer reach AirType over the same Wi-Fi.")
        case .checking: L10n.text("Choose Allow if iOS asks for Local Network access.")
        case .available: L10n.text("Network check complete. Now try AirType below.")
        case .blocked: L10n.text("Allow AirType under Settings → Privacy & Security → Local Network.")
        case .failed: L10n.text("Check Wi-Fi and try again. More help is in Advanced settings.")
        }
    }
    var setupAction: String {
        switch self {
        case .checking: L10n.text("Checking…")
        case .available: L10n.text("Check again")
        case .failed: L10n.text("Try again")
        default: L10n.text("Allow Local Network")
        }
    }
    var diagnosticMessage: String {
        switch self {
        case .idle: L10n.text("No network check has run yet.")
        case .checking: L10n.text("Checking local Bonjour discovery. Choose Allow if iOS requests access.")
        case .available: L10n.text("Bonjour check passed on this device. Connect from your computer using the address on the visible AirType keyboard.")
        case .blocked: L10n.text("Local Network access is blocked or awaiting approval. Allow the prompt, or enable AirType in Settings → Privacy & Security → Local Network.")
        case .failed(let message): message
        }
    }
}

struct KeyboardTestScreen: UIViewControllerRepresentable {
    let useSystemKeyboard: Bool
    func makeUIViewController(context: Context) -> KeyboardTestController { KeyboardTestController(useSystemKeyboard:useSystemKeyboard) }
    func updateUIViewController(_ controller: KeyboardTestController,context:Context) {}
}
