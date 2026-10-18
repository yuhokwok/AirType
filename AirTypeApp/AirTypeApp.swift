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
    @State private var destination: AirTypeGuide?
    @State private var showTutorial = false
    @State private var showConnectionName = false
    @State private var showTry = false
    @State private var settingsUnavailable = false
    private let accent = Color(red: 0.04, green: 0.68, blue: 0.73)

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 22) {
                    AirTypeWirelessMark()
                        .fill(LinearGradient(colors: [Color(red: 0.035, green: 0.68, blue: 0.83), Color(red: 0, green: 0.92, blue: 0.79)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 112, height: 66).accessibilityHidden(true)
                    Text(L10n.text("Type, over the air"))
                        .font(.title3.weight(.regular)).foregroundStyle(.gray)
                        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 20)
                }.frame(maxWidth: .infinity).padding(.vertical, 24)
                    .padding(.horizontal, -20).padding(.top, -20)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("AirType. " + L10n.text("Type, over the air"))


                homeCard(.addKeyboard, title: "Set up the keyboard", message: L10n.text("Enable AirType and Allow Full Access in Settings."), actionTitle: "Open Keyboard Settings", symbol: "keyboard", action: openSettings)
                homeCard(.connection, title: "Allow Local Network", message: networkCheck.state.setupMessage,
                         actionTitle: networkCheck.state == .blocked ? "Open Settings" : networkCheck.state.setupAction,
                         symbol: networkCheck.state == .available ? "checkmark.circle" : "wifi") {
                    if networkCheck.state == .blocked { openSettings() }
                    else { networkCheck.start() }
                }
                homeCard(.typing, title: "Try AirType", message: L10n.text("Open a text field and use the globe key to select AirType."), actionTitle: "Try AirType", symbol: "text.cursor") { showTry = true }

                VStack(spacing: 0) {
                    homeLink("Privacy", destination: .privacy)
                }.background(.white, in: .rect(cornerRadius: 18))
                AirTypeContactLinks().padding(.top, 4)
            }.padding(20).frame(maxWidth: 560).frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .preferredColorScheme(.light)
        .fullScreenCover(item: $destination) { guide in AirTypeGuideScreen(guide: guide) }
        .sheet(isPresented: $showConnectionName) {
            AirTypeGuideScreen(guide: .settings)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showTutorial) {
            AirTypeTutorialPopup()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showTry) {
            AirTypeHomeDestination {
                KeyboardTestScreen(useSystemKeyboard: true).ignoresSafeArea(.keyboard)
                    .navigationTitle(L10n.text("Try AirType")).navigationBarTitleDisplayMode(.inline)
            }
        }
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
    private func homeCard(_ step: AirTypeGuide, title: String, message: String, actionTitle: String, symbol: String, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    AirTypeMosaic(colors: step.colors).clipShape(.rect(cornerRadius: 8))
                    Text(verbatim: String(step.number)).font(.subheadline.weight(.semibold))
                        .frame(width: 24, height: 24).background(.white, in: .circle)
                }.frame(width: 34, height: 34).foregroundStyle(step.tint).accessibilityHidden(true)
                Text(L10n.text(title)).font(.headline).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                AirTypeInfoButton(guide: step)
            }
            Text(message).font(.subheadline).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: action) {
                Label(L10n.text(actionTitle), systemImage: symbol)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, minHeight: 44).padding(.horizontal, 12).padding(.vertical, 4)
                    .foregroundStyle(step == .addKeyboard ? .white : step.tint)
                    .background(step == .addKeyboard ? step.tint : step.tint.opacity(0.13), in: .capsule)
            }.buttonStyle(.plain).accessibilityIdentifier("HomeStep\(step.number)")
                .disabled(step == .connection && networkCheck.state == .checking)
            if step == .connection {
                Button { showConnectionName = true } label: {
                    Label(L10n.text("Setup for connection name"), systemImage: "slider.horizontal.3")
                        .font(.subheadline).multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }.buttonStyle(.plain).foregroundStyle(step.tint)
                    .accessibilityIdentifier("HomeConnectionName")
            } else if step == .typing {
                Button { showTutorial = true } label: {
                    Label(L10n.text("Watch the typing guide"), systemImage: "play.circle")
                        .font(.subheadline).multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }.buttonStyle(.plain).foregroundStyle(step.tint)
                    .accessibilityIdentifier("HomeTypingGuide")
            }
        }.padding(16).background(.white, in: .rect(cornerRadius: 18))
    }
    private func homeLink(_ title: String, destination: AirTypeGuide) -> some View {
        Button { self.destination = destination } label: {
            HStack {
                Text(L10n.text(title)).fixedSize(horizontal: false, vertical: true)
                Spacer()
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
            }.padding(16).frame(minHeight: 52).contentShape(.rect)
        }.buttonStyle(.plain).foregroundStyle(accent)
    }
    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url) { settingsUnavailable = !$0 }
    }
}

private struct AirTypeHomeDestination<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    @ViewBuilder var content: Content
    var body: some View {
        NavigationStack {
            content.toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel(L10n.text("Close"))
                }
            }
        }.preferredColorScheme(.light)
    }
}

private struct AirTypeInfoButton: View {
    let guide: AirTypeGuide
    @State private var isPresented = false

    var body: some View {
        Button { isPresented = true } label: {
            Image(systemName: "info.circle").frame(width: 44, height: 44)
        }.buttonStyle(.plain).foregroundStyle(guide.tint)
            .accessibilityLabel(L10n.text(guide.title))
            .popover(isPresented: $isPresented, attachmentAnchor: .rect(.bounds)) {
                AirTypeGuideScreen(guide: guide)
                    .frame(idealWidth: 320, idealHeight: 460)
                    .presentationCompactAdaptation(.popover)
            }
    }
}

private struct AirTypeSectionHeading: View {
    let title: String
    let theme: AirTypeGuide
    var body: some View {
        HStack(spacing: 10) {
            AirTypeMosaic(colors: theme.colors).frame(width: 48, height: 105)
            Text(L10n.text(title)).font(.system(.largeTitle, design: .rounded).weight(.light))
                .foregroundStyle(theme.tint).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 12)
        }
    }
}

private struct AirTypeTutorialPopup: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 24, weight: .light))
                        .frame(width: 44, height: 44)
                }.foregroundStyle(Color(white: 0.6)).accessibilityLabel(L10n.text("Close"))
            }.padding(8)
            TypingTutorialView()
        }.background(Color.white.ignoresSafeArea())
            .preferredColorScheme(.light).tint(AirTypeGuide.typing.tint)
    }
}

private struct AirTypePaper<Content: View>: View {
    var verticalInset: CGFloat? = nil
    @ViewBuilder var content: Content
    var body: some View {
        GeometryReader { geometry in
            let inset = verticalInset ?? (geometry.size.height < 400 ? 4.0 : 8.0)
            ScrollView {
                content.environment(\.colorScheme, .light)
                    .frame(maxWidth: 900, minHeight: max(0, geometry.size.height - inset * 2), alignment: .top)
                    .background(.white, in: .rect(cornerRadius: 5))
                    .padding(.vertical, inset).frame(maxWidth: .infinity)
            }.scrollDismissesKeyboard(.interactively).clipped()
                .background(.white).preferredColorScheme(.light)
        }
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
        case .settings: "Setup for\nconnection name."
        }
    }
    var tint: Color {
        switch self {
        case .addKeyboard: Color(red: 0.02, green: 0.78, blue: 0.84)
        case .connection, .settings: Color(red: 0.17, green: 0.50, blue: 0.84)
        case .typing: Color(red: 0.62, green: 0.18, blue: 0.93)
        case .privacy: Color(white: 0.48)
        }
    }
    var colors: [Color] {
        switch self {
        case .addKeyboard: [Color(red: 0.60, green: 0.99, blue: 0.90), Color(red: 0.56, green: 0.95, blue: 0.98), Color(red: 0.55, green: 0.99, blue: 0.91), Color(red: 0.53, green: 0.95, blue: 0.98)]
        case .connection, .settings: [Color(red: 0.53, green: 0.75, blue: 0.99), Color(red: 0.48, green: 0.35, blue: 1), Color(red: 0.46, green: 0.72, blue: 0.98), Color(red: 0.44, green: 0.30, blue: 1)]
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

/// Reference artwork: three rounded circular arcs, with heavier inner strokes.
/// The 300 × 176 coordinate space matches the proportions of the owner's header.
private struct AirTypeWirelessMark: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width / 300, rect.height / 176)
        let offset = CGPoint(x: rect.midX - 150 * scale, y: rect.midY - 88 * scale)
        var silhouette = Path()
        for (centerY, radius, thickness) in [(171.0, 160.0, 22.0), (181.0, 110.0, 28.0), (192.0, 62.0, 28.0)] {
            let center = CGPoint(x: offset.x + 150 * scale, y: offset.y + centerY * scale)
            let r = radius * scale
            var arc = Path()
            let start = 210.0 * Double.pi / 180
            arc.move(to: CGPoint(x: center.x + r * cos(start), y: center.y + r * sin(start)))
            // Two 60-degree cubic segments keep the arc circular at every rendered size.
            for degrees in [210.0, 270.0] {
                let a = degrees * Double.pi / 180
                let b = (degrees + 60) * Double.pi / 180
                let k = 4.0 / 3.0 * tan((b - a) / 4)
                arc.addCurve(to: CGPoint(x: center.x + r * cos(b), y: center.y + r * sin(b)),
                             control1: CGPoint(x: center.x + r * (cos(a) - k * sin(a)), y: center.y + r * (sin(a) + k * cos(a))),
                             control2: CGPoint(x: center.x + r * (cos(b) + k * sin(b)), y: center.y + r * (sin(b) - k * cos(b))))
            }
            silhouette.addPath(arc.strokedPath(StrokeStyle(lineWidth: thickness * scale, lineCap: .round, lineJoin: .round)))
        }
        return silhouette
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
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.system(size: 24, weight: .light))
                            .frame(width: 44, height: 44)
                    }.foregroundStyle(Color(white: 0.6))
                        .accessibilityLabel(L10n.text("Close"))
                }.padding(8).frame(maxWidth: 900).background(.white, ignoresSafeAreaEdges: [])
                AirTypePaper(verticalInset: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    AirTypeSectionHeading(title: guide.title, theme: guide)
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
                }
            }
            }.background(Color.white.ignoresSafeArea())
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
            VStack(spacing: 0) {
                AirTypeSectionHeading(title: "Typing guide", theme: .typing)
                VStack(alignment: .leading, spacing: 24) {
                Text(L10n.format("Step %1$@ of 4", String(step + 1)))
                    .font(.subheadline).foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { number in
                        Capsule().fill(number <= step ? AirTypeGuide.typing.tint : Color.secondary.opacity(0.15))
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
            }.frame(maxWidth: 900).frame(maxWidth: .infinity)
        }
        .background(.white).clipped().tint(AirTypeGuide.typing.tint)
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
                .overlay { RoundedRectangle(cornerRadius: 20).stroke(AirTypeGuide.typing.tint.opacity(sent ? 1 : 0.2), lineWidth: 2) }
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
