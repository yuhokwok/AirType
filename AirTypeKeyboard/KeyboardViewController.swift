import UIKit

final class KeyboardViewController: UIInputViewController {
    private let keyboard = AirKeyboardView()
    private let server = AirTypeServer()
    private var height: NSLayoutConstraint?
    override func viewDidLoad() {
        super.viewDidLoad()
        keyboard.configureGlobe = { [weak self] button in
            button.removeTarget(nil,action:nil,for:.touchUpInside)
            // UIAction-based nextKeyboard is nil in the extension; the system owns the globe menu.
            button.addTarget(self,action:#selector(UIInputViewController.handleInputModeList(from:with:)),for:.allTouchEvents)
        }
        keyboard.insertText = { [weak self] in self?.textDocumentProxy.insertText($0) }
        keyboard.deleteText = { [weak self] in self?.textDocumentProxy.deleteBackward() }
        keyboard.onWebModeChange = { [weak self] _ in self?.updateServer() }
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
        super.viewWillAppear(animated); updateAppearance(); updateServer()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated); server.stop(); keyboard.stopRepeating()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateAppearance()
        let landscape = view.bounds.width > 600 && traitCollection.userInterfaceIdiom == .phone
        height?.constant = traitCollection.userInterfaceIdiom == .pad ? 264 : (landscape ? 162 : 216)
    }
    override func textDidChange(_ textInput: UITextInput?) { updateAppearance() }
    private func updateAppearance() {
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
    private func updateServer() {
        if keyboard.webMode && hasFullAccess { server.start() }
        else { server.stop() }
        syncState()
    }
    private func syncState() {
        keyboard.pairingCode = server.pairingCode
        keyboard.address = server.address
        keyboard.connected = server.connected
        keyboard.connectionStatus = hasFullAccess ? server.status : "Enable Full Access for Wi-Fi"
    }
}
