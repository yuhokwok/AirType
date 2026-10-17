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
    @State private var bonjourName = NetworkPreferences.hostname
    @State private var nameSaved = false
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
                            Text(L10n.text("Type, from your computer."))
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
                        TypingTutorialView()
                    } label: {
                        Label(L10n.text("Watch the typing guide"), systemImage: "play.circle")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }.buttonStyle(.bordered)
                    VStack(alignment: .leading, spacing: 16) {
                        DisclosureGroup(L10n.text("Connection name")) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    TextField("airtype", text: $bonjourName)
                                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                                        .accessibilityLabel(L10n.text("Connection name"))
                                        .onChange(of: bonjourName) { nameSaved = false }
                                    Text(".local").foregroundStyle(.secondary)
                                }.textFieldStyle(.roundedBorder)
                                Button(L10n.text("Save connection name")) {
                                    NetworkPreferences.saveHostname(bonjourName)
                                    bonjourName = NetworkPreferences.hostname
                                    nameSaved = true
                                }.frame(minHeight: 44)
                                if nameSaved {
                                    Label(L10n.text("Saved. Reopen the keyboard to apply."), systemImage: "checkmark.circle")
                                }
                                Text(L10n.text("Use the address shown on your keyboard. Reopen the keyboard after changing its name."))
                                    .font(.footnote).foregroundStyle(.secondary)
                            }.padding(.top, 10)
                        }
                        Divider()
                        DisclosureGroup(L10n.text("Privacy")) {
                            Text(L10n.text("Full Access lets the keyboard connect to your computer. AirType uses your local network, has no cloud service and does not store your typing. Use a trusted Wi-Fi network."))
                                .font(.subheadline).foregroundStyle(.secondary).padding(.top, 8)
                        }
                    }.padding(16)
                        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))
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

private extension LocalNetworkCheck.State {
    var setupMessage: String {
        switch self {
        case .idle: L10n.text("Let your computer reach AirType over the same Wi-Fi.")
        case .checking: L10n.text("Choose Allow if iOS asks for Local Network access.")
        case .available: L10n.text("Network check complete. Now try AirType below.")
        case .blocked: L10n.text("Allow AirType under Settings → Privacy & Security → Local Network.")
        case .failed: L10n.text("Check Wi-Fi and try again. Keep both devices on the same network.")
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

}

struct KeyboardTestScreen: UIViewControllerRepresentable {
    let useSystemKeyboard: Bool
    func makeUIViewController(context: Context) -> KeyboardTestController { KeyboardTestController(useSystemKeyboard:useSystemKeyboard) }
    func updateUIViewController(_ controller: KeyboardTestController,context:Context) {}
}

private struct TypingTutorialView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var step = 0
    @State private var tick = 0
    @State private var playing = true
    private let titles = ["Open AirType", "Open the address", "Enter the pairing code", "Type and send"]
    private let instructions = [
        "Open a text field, select the AirType keyboard, then tap Wi-Fi. Keep the keyboard visible.",
        "On your computer, open the exact address shown on the keyboard. Connect both devices to the same Wi-Fi.",
        "Enter the six-digit code shown on your keyboard in the browser, then choose Connect.",
        "Type on your computer and press Enter or Send. Your text appears in the active field on your iPhone or iPad."
    ]
    private var sample: String { L10n.text("Hello, AirType!") }
    private var computerText: String {
        step == 3 ? String(sample.prefix(reduceMotion ? sample.count : tick)) : ""
    }
    private var sent: Bool { step == 3 && (reduceMotion || tick > sample.count + 5) }
    private var shouldPlay: Bool { playing && !reduceMotion && scenePhase == .active }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(L10n.format("Step %1$@ of 4", String(step + 1)))
                    .font(.subheadline).foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { number in
                        Capsule().fill(number <= step ? Color.accentColor : Color.secondary.opacity(0.15))
                            .frame(height: 5)
                    }
                }.accessibilityHidden(true)
                Text(L10n.text(titles[step])).font(.title2.bold())
                demonstration
                Text(L10n.text(instructions[step])).font(.body).frame(maxWidth: .infinity, alignment: .leading)
                Text(L10n.text("Example only. Use your keyboard’s address and code."))
                    .font(.footnote).foregroundStyle(.secondary)
                HStack {
                    Button { move(to: step - 1) } label: {
                        Label(L10n.text("Previous"), systemImage: "chevron.left")
                    }.disabled(step == 0)
                    Spacer()
                    if !reduceMotion && !(step == 3 && tick >= 40) {
                        Button {
                            if !playing && tick == 39 { tick = 0 }
                            playing.toggle()
                        } label: {
                            Label(L10n.text(playing ? "Pause" : "Play"),
                                  systemImage: playing ? "pause.fill" : "play.fill")
                        }
                    }
                    Spacer()
                    Button {
                        if step == 3 { step = 0; tick = 0; playing = !reduceMotion }
                        else { move(to: step + 1) }
                    } label: {
                        Label(L10n.text(step == 3 ? "Replay" : "Next step"), systemImage: step == 3 ? "arrow.counterclockwise" : "chevron.right")
                    }
                }.buttonStyle(.bordered).frame(minHeight: 44)
            }.padding(24).frame(maxWidth: 560).frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(L10n.text("Typing guide")).navigationBarTitleDisplayMode(.inline)
        .task(id: shouldPlay) {
            guard shouldPlay else { return }
            while !Task.isCancelled {
                do { try await Task.sleep(for: .milliseconds(150)) } catch { return }
                tick += 1
                if tick >= 40 {
                    if step == 3 { playing = false; return }
                    withAnimation(.easeInOut(duration: 0.3)) { step += 1; tick = 0 }
                }
            }
        }
    }

    private var demonstration: some View {
        VStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 12) {
                Label("AirType", systemImage: "laptopcomputer").font(.headline)
                Text(verbatim: step >= 1 ? "airtype.local:8307" : " ")
                    .font(.system(.caption, design: .monospaced)).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(10)
                    .background(Color(.tertiarySystemGroupedBackground), in: .rect(cornerRadius: 8))
                HStack {
                    if step == 2 {
                        Text(verbatim: String("123456".prefix(reduceMotion ? 6 : tick / 3)))
                            .font(.system(.title2, design: .monospaced))
                    } else {
                        Text(verbatim: computerText).font(.body)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: step == 2 ? "link" : "paperplane.fill")
                        .foregroundStyle(.tint).scaleEffect(sent ? 1.2 : 1)
                }.frame(minHeight: 36)
            }.padding(16)
                .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
                .opacity(step == 0 ? 0.45 : 1)
            Image(systemName: "arrow.down").font(.title2).foregroundStyle(.tint)
                .offset(y: sent ? 4 : 0)
            VStack(alignment: .leading, spacing: 14) {
                Label("iPhone / iPad", systemImage: "iphone").font(.headline)
                Text(verbatim: sent ? sample : " ")
                    .font(.body).frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
                    .padding(10).background(Color(.tertiarySystemGroupedBackground), in: .rect(cornerRadius: 8))
                HStack {
                    Image(systemName: "wifi").font(.title2).foregroundStyle(.tint)
                    Text("AirType").font(.headline)
                    Spacer()
                    Text(verbatim: "123456").monospacedDigit().font(.headline)
                }
                Text(verbatim: "airtype.local:8307").font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }.padding(16)
                .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
                .overlay { RoundedRectangle(cornerRadius: 20).stroke(Color.accentColor.opacity(sent ? 1 : 0.2), lineWidth: 2) }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: step)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: sent)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.text(instructions[step]))
    }
    private func move(to next: Int) {
        playing = false
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
            step = next; tick = 39
        }
    }
}
