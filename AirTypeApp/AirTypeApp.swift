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
    @State private var networkBrowser: NWBrowser?
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
                        step("3", "Connect your computer", "Switch to AirType with the globe key. Tap the address bar and open the complete address on a computer using the same Wi-Fi.")
                    }
                    Button("Enable local network connection") { enableNetwork() }.buttonStyle(.bordered).tint(cyan)
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
        }
    }
    private func step(_ number:String,_ title:String,_ detail:String) -> some View {
        HStack(alignment:.top,spacing:14) {
            Text(number).font(.headline).foregroundStyle(cyan).frame(width:28,height:28).background(cyan.opacity(0.1),in:.circle)
            VStack(alignment:.leading,spacing:5) { Text(title).font(.headline); Text(detail).font(.subheadline).foregroundStyle(.secondary) }
        }
    }
    private func enableNetwork() {
        networkBrowser?.cancel()
        let browser = NWBrowser(for:.bonjour(type:"_airtype._tcp",domain:nil),using:.tcp)
        browser.start(queue:.main); networkBrowser = browser
    }
}

struct KeyboardTestScreen: UIViewControllerRepresentable {
    let useSystemKeyboard: Bool
    func makeUIViewController(context: Context) -> KeyboardTestController { KeyboardTestController(useSystemKeyboard:useSystemKeyboard) }
    func updateUIViewController(_ controller: KeyboardTestController,context:Context) {}
}
