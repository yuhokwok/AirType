import UIKit

final class KeyboardViewController: UIInputViewController {
    private let keyboard = AirKeyboardView()
    private let server = AirTypeServer()
    private lazy var nearby = NearbyReceiver(displayName: "AirType " + NetworkPreferences.hostname)
    private var activeMode: RemoteInputMode?
    private var height: NSLayoutConstraint?
    override func viewDidLoad() {
        super.viewDidLoad()
        keyboard.configureGlobe = { [weak self] button in
            button.removeTarget(nil,action:nil,for:.touchUpInside)
            // UIAction-based nextKeyboard is nil in the extension; the system owns the globe menu.
            button.addTarget(self,action:#selector(UIInputViewController.handleInputModeList(from:with:)),for:.allTouchEvents)
        }
        keyboard.contextBeforeInput = { [weak self] in self?.textDocumentProxy.documentContextBeforeInput }
        keyboard.insertText = { [weak self] in self?.textDocumentProxy.insertText($0) }
        keyboard.deleteText = { [weak self] in self?.textDocumentProxy.deleteBackward() }
        keyboard.onWebModeChange = { [weak self] _ in self?.updateServer() }
        keyboard.onReceiveModeChange = { [weak self] in
            guard let self else { return }
            if self.hasFullAccess { NetworkPreferences.inputMode = self.keyboard.receiveMode }
            self.updateServer()
        }
        nearby.onStateChange = { [weak self] in self?.syncState() }
        nearby.onCommand = { [weak self] packet in
            guard let self, self.hasFullAccess, self.keyboard.webMode, self.view.window != nil else {
                return "Open the AirType keyboard in a text field first."
            }
            return NativeKeyboardInput(
                insert: { self.textDocumentProxy.insertText($0) },
                delete: { self.textDocumentProxy.deleteBackward() },
                move: { self.textDocumentProxy.adjustTextPosition(byCharacterOffset: $0) }
            ).execute(packet)
        }
        server.onCommand = { [weak self] command in
            guard let self else { return }
            switch command.action {
            case .insert: self.textDocumentProxy.insertText(command.text ?? "")
            case .delete: self.textDocumentProxy.deleteBackward()
            case .newline: self.textDocumentProxy.insertText("\n")
            }
        }
        server.onStateChange = { [weak self] in self?.syncState() }
        keyboard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(keyboard)
        NSLayoutConstraint.activate([keyboard.leadingAnchor.constraint(equalTo:view.leadingAnchor),keyboard.trailingAnchor.constraint(equalTo:view.trailingAnchor),keyboard.topAnchor.constraint(equalTo:view.topAnchor),keyboard.bottomAnchor.constraint(equalTo:view.bottomAnchor)])
        let constraint = view.heightAnchor.constraint(equalToConstant:216); constraint.priority = .init(999); constraint.isActive = true; height = constraint
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if hasFullAccess { keyboard.receiveMode = NetworkPreferences.inputMode }
        keyboard.showsGlobe = needsInputModeSwitchKey
        updateAppearance(); keyboard.synchronizeCapitalization(); updateServer()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated); stopReceivers(); keyboard.stopRepeating()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateAppearance()
        let landscape = view.bounds.width > 600 && traitCollection.userInterfaceIdiom == .phone
        height?.constant = traitCollection.userInterfaceIdiom == .pad ? 264 : (landscape ? 162 : 216)
    }
    override func textDidChange(_ textInput: UITextInput?) { updateAppearance(); keyboard.synchronizeCapitalization() }
    private func updateAppearance() {
        keyboard.showsGlobe = needsInputModeSwitchKey
        keyboard.autocapitalizationType = textDocumentProxy.autocapitalizationType ?? .sentences
        let dark = textDocumentProxy.keyboardAppearance == .dark || traitCollection.userInterfaceStyle == .dark
        if keyboard.dark != dark { keyboard.dark = dark }
        let title: String
        switch textDocumentProxy.returnKeyType {
        case .search: title = "Search"
        case .go: title = "Go"
        case .send: title = "Send"
        case .done: title = "Done"
        case .next: title = "Next"
        default: title = "return"
        }
        if keyboard.returnTitle != title { keyboard.returnTitle = title }
    }
    private func stopReceivers() {
        activeMode = nil
        server.stop(); nearby.stopWiFi(); nearby.stopBluetooth()
    }
    private func updateServer() {
        guard keyboard.webMode, hasFullAccess else { stopReceivers(); syncState(); return }
        let mode = keyboard.receiveMode
        if activeMode != mode {
            stopReceivers(); activeMode = mode
            switch mode {
            case .web: server.start()
            case .wifi: nearby.startWiFi()
            case .bluetooth: nearby.startBluetooth()
            }
        }
        syncState()
    }
    private func syncState() {
        if keyboard.receiveMode == .web {
            keyboard.pairingCode = server.pairingCode
            keyboard.ipAddress = server.ipAddress
            keyboard.address = server.address
            keyboard.connected = server.connected
            keyboard.connectionStatus = hasFullAccess ? server.status : "Enable Full Access to connect"
        } else {
            keyboard.pairingCode = hasFullAccess && keyboard.webMode ? nearby.pairingKey : nil
            keyboard.ipAddress = nil; keyboard.address = nil
            keyboard.connected = nearby.connections > 0
            keyboard.connectionStatus = hasFullAccess ? (nearby.connections > 0 ? "Computer connected" :
                (keyboard.receiveMode == .wifi ? nearby.wifiStatus : nearby.bluetoothStatus)) : "Enable Full Access to connect"
        }
    }
}
