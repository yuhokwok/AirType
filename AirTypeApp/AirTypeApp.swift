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
    @State private var destination: AirTypeGuide?
    var body: some View {
        GeometryReader { geometry in
            let width = min(geometry.size.width, 900)
            let header = min(230.0, max(160.0, width * 0.46))
            let band = min(150.0, width / 3)
            AirTypePaper {
                VStack(spacing: 0) {
                    ZStack(alignment: .topTrailing) {
                        VStack(spacing: 20) {
                            Spacer(minLength: 12)
                            AirTypeWirelessMark().stroke(LinearGradient(colors: [Color(red: 0.02, green: 0.68, blue: 0.84), Color(red: 0, green: 0.88, blue: 0.78)], startPoint: .top, endPoint: .bottom), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .frame(width: 104, height: 60).accessibilityHidden(true)
                            Text(L10n.text("Type, with your computer."))
                                .font(.title3.weight(.regular)).foregroundStyle(.gray)
                                .multilineTextAlignment(.center).padding(.horizontal, 20)
                            HStack {
                                Spacer()
                                Button(L10n.text("Privacy Policy")) { destination = .privacy }
                                    .font(.subheadline).foregroundStyle(.gray).frame(minHeight: 44)
                            }.padding(.horizontal, 12)
                        }
                        Button { destination = .settings } label: {
                            Image(systemName: "gearshape").font(.title3).frame(width: 44, height: 44)
                        }.foregroundStyle(.gray).padding(8)
                            .accessibilityLabel(L10n.text("Settings"))
                    }.frame(height: header)
                    HStack(spacing: 0) {
                        ForEach(AirTypeGuide.steps) { step in
                            Button { destination = step } label: {
                                VStack(spacing: 0) {
                                    ZStack {
                                        AirTypeMosaic(colors: step.colors)
                                        Text(verbatim: String(step.number)).font(.system(size: min(52, band * 0.46), weight: .light))
                                            .foregroundStyle(step.tint)
                                            .frame(width: band * 0.62, height: band * 0.62)
                                            .background(.white, in: .circle)
                                    }.frame(height: band)
                                    VStack(spacing: 22) {
                                        Spacer(minLength: 30)
                                        AirTypeStepSymbol(step: step).frame(height: 72)
                                        Spacer(minLength: 18)
                                        Text(L10n.text(step.title)).font(.title3.weight(.regular))
                                            .multilineTextAlignment(.center).lineLimit(3).minimumScaleFactor(0.75)
                                            .frame(maxWidth: .infinity, minHeight: 74, alignment: .top)
                                        Image(systemName: "arrow.right.square").font(.system(size: 29, weight: .regular))
                                        Spacer(minLength: 38)
                                    }.padding(.horizontal, 8)
                                        .frame(maxWidth: .infinity, minHeight: max(280, geometry.size.height - header - band - 40))
                                        .background(LinearGradient(colors: [step.tint.opacity(0.07), .white], startPoint: .top, endPoint: .bottom))
                                }.foregroundStyle(step.tint)
                            }.buttonStyle(.plain).frame(maxWidth: .infinity)
                                .accessibilityLabel("\(step.number). \(L10n.text(step.title))")
                                .accessibilityIdentifier("HomeStep\(step.number)")
                        }
                    }
                }
            }.frame(width: width).frame(maxWidth: .infinity)
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(item: $destination) { guide in AirTypeGuideScreen(guide: guide) }
    }
}

private struct AirTypePaper<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        ScrollView {
            content.environment(\.colorScheme, .light).frame(maxWidth: 900)
                .background(.white, in: .rect(cornerRadius: 5))
                .padding(.vertical, 18).frame(maxWidth: .infinity)
        }.background(.black).preferredColorScheme(.dark)
    }
}

private enum AirTypeGuide: String, Identifiable {
    case addKeyboard, connection, typing, privacy, settings
    var id: String { rawValue }
    static let steps: [Self] = [.addKeyboard, .connection, .typing]
    var number: Int { self == .addKeyboard ? 1 : self == .connection ? 2 : 3 }
    var title: String {
        switch self {
        case .addKeyboard: "Add New\nKeyboard."
        case .connection: "Setup for\nAirType."
        case .typing: "Type."
        case .privacy: "Privacy Policy."
        case .settings: "Settings"
        }
    }
    var tint: Color {
        switch self {
        case .addKeyboard: Color(red: 0.02, green: 0.78, blue: 0.84)
        case .connection: Color(red: 0.17, green: 0.50, blue: 0.84)
        case .typing: Color(red: 0.62, green: 0.18, blue: 0.93)
        case .privacy, .settings: Color(white: 0.48)
        }
    }
    var colors: [Color] {
        switch self {
        case .addKeyboard: [Color(red: 0.60, green: 0.99, blue: 0.90), Color(red: 0.56, green: 0.95, blue: 0.98), Color(red: 0.55, green: 0.99, blue: 0.91), Color(red: 0.53, green: 0.95, blue: 0.98)]
        case .connection: [Color(red: 0.53, green: 0.75, blue: 0.99), Color(red: 0.48, green: 0.35, blue: 1), Color(red: 0.46, green: 0.72, blue: 0.98), Color(red: 0.44, green: 0.30, blue: 1)]
        case .typing: [Color(red: 0.73, green: 0.36, blue: 0.98), Color(red: 0.85, green: 0.36, blue: 0.98), Color(red: 0.70, green: 0.27, blue: 0.97), Color(red: 0.84, green: 0.28, blue: 0.97)]
        default: [Color(white: 0.70), Color(white: 0.70), Color(white: 0.65), Color(white: 0.65)]
        }
    }
    var paragraphs: [String] {
        switch self {
        case .addKeyboard: [
            "Open `Settings` on your iPhone or iPad.",
            "Choose `General` → `Keyboard` → `Keyboards` → `Add New Keyboard…`.",
            "Select `AirType` under third-party keyboards.",
            "Open `AirType` and turn on `Allow Full Access` for network typing."
        ]
        case .connection: [
            "Connect your iPhone or iPad and computer to the same Wi-Fi network.",
            "Open a text field, switch to the `AirType` keyboard and tap `Wi-Fi`.",
            "Keep Web Access visible and open the exact address shown on the keyboard in your computer browser.",
            "Enter the six-digit pairing code shown on the keyboard, then choose `Connect`."
        ]
        case .typing: [
            "On your computer, type the text you want to send using AirType Web Access.",
            "Press `Enter / Return` or the send button to insert the text on your iPhone or iPad.",
            "With an empty draft, `Enter / Return` inserts a new line and `Backspace / Delete` deletes a character on your device.",
            "Use `Shift + Enter` to add a line to the browser draft."
        ]
        default: []
        }
    }
}

private struct AirTypeMosaic: View {
    let colors: [Color]
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) { colors[0]; colors[1] }
            HStack(spacing: 0) { colors[2]; colors[3] }
        }.accessibilityHidden(true)
    }
}

private struct AirTypeStepSymbol: View {
    let step: AirTypeGuide
    var body: some View {
        Group {
            if step == .addKeyboard {
                Image(systemName: "keyboard.fill").font(.system(size: 27, weight: .light))
                    .frame(width: 62, height: 62)
                    .overlay { Circle().stroke(lineWidth: 2.5) }
            } else if step == .connection {
                VStack(spacing: 0) {
                    Rectangle().frame(height: 6)
                    Color.white
                    Image(systemName: "wifi").font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white).frame(height: 22).frame(maxWidth: .infinity)
                        .background(Color(white: 0.83))
                    Rectangle().frame(height: 6)
                }.frame(width: 34, height: 70)
                    .overlay { RoundedRectangle(cornerRadius: 2).stroke(lineWidth: 1.5) }
                    .clipShape(.rect(cornerRadius: 2))
            } else {
                HStack(spacing: 3) {
                    Text("ab").font(.system(size: 43, weight: .ultraLight))
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0)); path.addLine(to: CGPoint(x: 8, y: 0))
                        path.move(to: CGPoint(x: 4, y: 0)); path.addLine(to: CGPoint(x: 4, y: 48))
                        path.move(to: CGPoint(x: 0, y: 48)); path.addLine(to: CGPoint(x: 8, y: 48))
                    }.stroke(lineWidth: 1).frame(width: 8, height: 48)
                }
            }
        }.foregroundStyle(step.tint.opacity(0.55)).accessibilityHidden(true)
    }
}

private struct AirTypeWirelessMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for (left, top, bottom) in [(0.08, -0.12, 0.54), (0.21, 0.28, 0.73), (0.35, 0.66, 0.94)] {
            path.move(to: CGPoint(x: rect.width * left, y: rect.height * bottom))
            path.addCurve(to: CGPoint(x: rect.width * (1-left), y: rect.height * bottom),
                          control1: CGPoint(x: rect.width * (left + (1 - 2 * left) * 0.24), y: rect.height * top),
                          control2: CGPoint(x: rect.width * (1 - left - (1 - 2 * left) * 0.24), y: rect.height * top))
        }
        return path
    }
}

private struct AirTypeGuideScreen: View {
    let guide: AirTypeGuide
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var networkCheck = LocalNetworkCheck()
    @State private var bonjourName = NetworkPreferences.hostname
    @State private var nameSaved = false
    @State private var savedName: String?
    @FocusState private var editingBonjour: Bool
    @State private var settingsUnavailable = false

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
            AirTypePaper {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark").font(.system(size: 24, weight: .light)).frame(width: 44, height: 44)
                        }.foregroundStyle(Color(white: 0.68)).accessibilityLabel(L10n.text("Close"))
                    }.padding(12)
                    HStack(spacing: 10) {
                        AirTypeMosaic(colors: guide.colors).frame(width: 48, height: 105)
                        Text(L10n.text(guide.title)).font(.system(.largeTitle, design: .rounded).weight(.light))
                            .foregroundStyle(guide.tint).fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 12)
                    }
                    VStack(alignment: .leading, spacing: 26) {
                        if guide == .settings { bonjourSettings }
                        else if guide == .privacy { privacyPolicy }
                        else {
                            ForEach(guide.paragraphs, id: \.self) { paragraph in
                                HStack(alignment: .firstTextBaseline, spacing: 12) {
                                    Text("•").font(.title2)
                                    Text(styled(paragraph)).font(.title3).lineSpacing(8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            actions
                        }
                    }.padding(22)
                    Spacer(minLength: 60)
                }.frame(minHeight: max(620, geometry.size.height - 36), alignment: .top)
            }
            }
            .tint(guide.tint)
            .onDisappear { networkCheck.stop() }
            .onChange(of: scenePhase) {
                if scenePhase == .active && networkCheck.hasRequested { networkCheck.start() }
            }
            .alert(L10n.text("Open Settings manually"), isPresented: $settingsUnavailable) {
                Button(L10n.text("OK"), role: .cancel) {}
            } message: {
                Text(L10n.text("Settings → General → Keyboard → Keyboards → Add New Keyboard → AirType. Then enable Allow Full Access."))
            }
        }
    }
    private func styled(_ key: String) -> AttributedString {
        var text = (try? AttributedString(markdown: L10n.text(key), options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(L10n.text(key))
        for run in text.runs where run.inlinePresentationIntent?.contains(.code) == true {
            text[run.range].foregroundColor = .white
            text[run.range].backgroundColor = Color(white: 0.23)
            text[run.range].font = .system(.title3, design: .monospaced)
        }
        return text
    }
    @ViewBuilder private var actions: some View {
        if guide == .addKeyboard {
            Button(L10n.text("Open Keyboard Settings"), action: openSettings).buttonStyle(.borderedProminent).frame(minHeight: 44)
        } else if guide == .connection {
            Text(networkCheck.state.setupMessage).font(.subheadline).foregroundStyle(.secondary)
            if networkCheck.state == .blocked {
                Button(L10n.text("Open Settings"), action: openSettings).buttonStyle(.bordered)
            } else {
                Button(networkCheck.state.setupAction) { networkCheck.start() }
                    .buttonStyle(.bordered).disabled(networkCheck.state == .checking)
            }
        } else {
            NavigationLink(L10n.text("Watch the typing guide")) { TypingTutorialView() }
            NavigationLink(L10n.text("Try AirType")) {
                KeyboardTestScreen(useSystemKeyboard: true).ignoresSafeArea(.keyboard)
                    .navigationTitle(L10n.text("Try AirType")).navigationBarTitleDisplayMode(.inline)
            }
        }
    }
    private var bonjourSettings: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(L10n.text("Bonjour name")).font(.headline)
            HStack {
                TextField("airtype", text: $bonjourName)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                    .accessibilityLabel(L10n.text("Bonjour name"))
                    .focused($editingBonjour)
                    .submitLabel(.done).onSubmit(saveName)
                    .onChange(of: bonjourName) { if bonjourName != savedName { nameSaved = false } }
                Text(".local").foregroundStyle(.secondary)
            }.textFieldStyle(.roundedBorder)
            Button(L10n.text("Save connection name"), action: saveName).buttonStyle(.borderedProminent).frame(minHeight: 44)
            if nameSaved { Label(L10n.text("Saved. Reopen the keyboard to apply."), systemImage: "checkmark.circle") }
            Text(L10n.text("Use the address shown on your keyboard. Reopen the keyboard after changing its name."))
                .font(.subheadline).foregroundStyle(.secondary)
            Divider().padding(.vertical, 12)
            AirTypeContactLinks()
        }
    }
    private var privacyPolicy: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(L10n.text("Original policy last updated: September 27, 2014")).font(.footnote).foregroundStyle(.secondary)
            ForEach(AirTypePrivacyContent.sections, id: \.self) { section in
                VStack(alignment: .leading, spacing: 14) {
                    Text(L10n.text(section[0])).font(.headline)
                    ForEach(section.dropFirst(), id: \.self) { key in Text(L10n.text(key)).lineSpacing(5) }
                }
            }
        }
    }
    private func saveName() {
        NetworkPreferences.saveHostname(bonjourName)
        savedName = NetworkPreferences.hostname
        bonjourName = NetworkPreferences.hostname
        nameSaved = true
        editingBonjour = false
    }
    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url) { settingsUnavailable = !$0 }
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

private enum AirTypePrivacyContent {
    static let sections: [[String]] = [
        [
                "policy.1.0",
                "policy.1.1",
                "policy.1.2"
        ],
        [
                "policy.2.0",
                "policy.2.1",
                "policy.2.2",
                "policy.2.3",
                "policy.2.4",
                "policy.2.5"
        ],
        [
                "policy.3.0",
                "policy.3.1"
        ],
        [
                "policy.4.0",
                "policy.4.1",
                "policy.4.2",
                "policy.4.3"
        ],
        [
                "policy.5.0",
                "policy.5.1"
        ],
        [
                "policy.6.0",
                "policy.6.1",
                "policy.6.2",
                "policy.6.3",
                "policy.6.4"
        ],
        [
                "policy.7.0",
                "policy.7.1"
        ],
        [
                "policy.8.0",
                "policy.8.1",
                "policy.8.2"
        ],
        [
                "policy.9.0",
                "policy.9.1"
        ]
]
}
