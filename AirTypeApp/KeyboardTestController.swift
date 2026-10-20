import UIKit

final class KeyboardTestController: UIViewController, UITextViewDelegate {
    private let useSystemKeyboard: Bool
    private let field = UITextView()
    private let placeholder = UILabel()
    private let keyboard = AirKeyboardView()
    private let server = AirTypeServer()
    private let nearby = NearbyReceiver(displayName: "AirType preview")
    private var activeMode: RemoteInputMode?
    init(useSystemKeyboard:Bool) { self.useSystemKeyboard = useSystemKeyboard; super.init(nibName:nil,bundle:nil) }
    required init?(coder:NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor = .systemBackground
        let title = UILabel(); title.text = useSystemKeyboard ? L10n.text("Try your AirType keyboard") : L10n.text("AirType keyboard preview"); title.font = .systemFont(ofSize:25,weight:.light)
        let hint = UILabel(); hint.text = useSystemKeyboard ? L10n.text("Tap below, then use the globe key to select AirType.") : L10n.text("Type here or send text from your computer.\nUse the keyboard button to return to local typing."); hint.numberOfLines = 0; hint.textColor = .secondaryLabel; hint.font = .systemFont(ofSize:14)
        field.font = .systemFont(ofSize:24); field.backgroundColor = .secondarySystemBackground; field.layer.cornerRadius = 12
        field.textContainerInset = UIEdgeInsets(top:16,left:12,bottom:16,right:12)
        field.accessibilityLabel = L10n.text("AirType test text"); field.delegate = self
        let clear = UIButton(type:.system); clear.setTitle(L10n.text("Clear text"),for:.normal); clear.addAction(UIAction { [weak self] _ in self?.field.text = "" },for:.touchUpInside)
        let appearance = UISegmentedControl(items:[L10n.text("Light"),L10n.text("Dark")]); appearance.selectedSegmentIndex = 0
        appearance.addAction(UIAction { [weak self] _ in guard let self else { return }; self.keyboard.dark = appearance.selectedSegmentIndex == 1; self.field.keyboardAppearance = appearance.selectedSegmentIndex == 1 ? .dark : .light; self.field.reloadInputViews() },for:.valueChanged)
        let arranged: [UIView]
        if useSystemKeyboard {
            placeholder.text = L10n.text("Your text will appear here")
            placeholder.font = .preferredFont(forTextStyle: .body)
            placeholder.adjustsFontForContentSizeCategory = true; placeholder.textColor = .tertiaryLabel
            placeholder.numberOfLines = 0; placeholder.isUserInteractionEnabled = false
            placeholder.translatesAutoresizingMaskIntoConstraints = false; field.addSubview(placeholder)
            NSLayoutConstraint.activate([placeholder.topAnchor.constraint(equalTo: field.topAnchor, constant: 16), placeholder.leadingAnchor.constraint(equalTo: field.leadingAnchor, constant: 16), placeholder.trailingAnchor.constraint(equalTo: field.trailingAnchor, constant: -16)])
            hint.font = .preferredFont(forTextStyle: .body); hint.adjustsFontForContentSizeCategory = true
            field.font = .preferredFont(forTextStyle: .title2); field.adjustsFontForContentSizeCategory = true
            let connectionHint = UILabel()
            connectionHint.text = L10n.text("Keep AirType visible. On your computer, open the address shown on the keyboard and enter its six-digit code.")
            connectionHint.font = .preferredFont(forTextStyle: .subheadline); connectionHint.adjustsFontForContentSizeCategory = true
            connectionHint.textColor = .secondaryLabel; connectionHint.numberOfLines = 0
            arranged = [hint, field, connectionHint]
        } else {
            arranged = [title, hint, field, appearance, clear]
        }
        let stack = UIStackView(arrangedSubviews: arranged); stack.axis = .vertical; stack.spacing = 16; stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([stack.topAnchor.constraint(equalTo:view.safeAreaLayoutGuide.topAnchor,constant:24),stack.leadingAnchor.constraint(equalTo:view.safeAreaLayoutGuide.leadingAnchor,constant:24),stack.trailingAnchor.constraint(equalTo:view.safeAreaLayoutGuide.trailingAnchor,constant:-24),field.heightAnchor.constraint(equalToConstant:180)])
        if !useSystemKeyboard {
            if ProcessInfo.processInfo.arguments.contains("--native-keyboard-wifi") { keyboard.receiveMode = .wifi }
            if ProcessInfo.processInfo.arguments.contains("--native-keyboard-bluetooth") { keyboard.receiveMode = .bluetooth }
            let keyboardHeight: CGFloat = traitCollection.userInterfaceIdiom == .pad ? 332 : 284
            let input = UIInputView(frame:CGRect(x:0,y:0,width:0,height:keyboardHeight),inputViewStyle:.keyboard)
            input.allowsSelfSizing = true
            keyboard.translatesAutoresizingMaskIntoConstraints = false; input.addSubview(keyboard)
            NSLayoutConstraint.activate([keyboard.topAnchor.constraint(equalTo:input.topAnchor),keyboard.bottomAnchor.constraint(equalTo:input.bottomAnchor),keyboard.leadingAnchor.constraint(equalTo:input.leadingAnchor),keyboard.trailingAnchor.constraint(equalTo:input.trailingAnchor),input.heightAnchor.constraint(equalToConstant:keyboardHeight)])
            field.inputView = input
            keyboard.hasSelection = { [weak self] in self?.field.selectedTextRange?.isEmpty == false }
            keyboard.contextBeforeInput = { [weak self] in
                guard let field = self?.field, let position = field.selectedTextRange?.start,
                      let range = field.textRange(from: field.beginningOfDocument, to: position) else { return nil }
                return field.text(in: range)
            }
            if ProcessInfo.processInfo.arguments.contains("--keyboard-qwerty") { keyboard.webMode = false }
            keyboard.insertText = { [weak self] in self?.field.insertText($0) }
            keyboard.moveCursor = { [weak self] offset in
                guard let field = self?.field, let range = field.selectedTextRange,
                      let position = field.position(from: range.start, offset: offset) else { return }
                field.selectedTextRange = field.textRange(from: position, to: position)
            }
            keyboard.deleteText = { [weak self] in self?.field.deleteBackward() }
            keyboard.nextKeyboard = { [weak self] in self?.field.resignFirstResponder() }
            keyboard.onWebModeChange = { [weak self] _ in self?.updatePreviewTransport() }
            keyboard.onReceiveModeChange = { [weak self] in self?.updatePreviewTransport() }
            nearby.onStateChange = { [weak self] in self?.syncPreviewState() }
            nearby.onCommand = { [weak self] packet in
                guard let self, self.field.isFirstResponder, self.keyboard.webMode else { return L10n.text("Open the keyboard preview first.") }
                return NativeKeyboardInput(insert: { self.field.insertText($0) }, delete: { self.field.deleteBackward() }, move: { offset in
                    guard let range = self.field.selectedTextRange, let position = self.field.position(from: range.start, offset: offset) else { return }
                    self.field.selectedTextRange = self.field.textRange(from: position, to: position)
                }).execute(packet)
            }
            server.onStateChange = { [weak self] in self?.syncPreviewState() }
            server.onCommand = { [weak self] command in
                guard let self, self.field.isFirstResponder else { return }
                switch command.action { case .insert: self.field.insertText(command.text ?? ""); case .delete: self.field.deleteBackward(); case .newline: self.field.insertText("\n") }
            }
        }
    }
    override func viewDidAppear(_ animated:Bool) {
        super.viewDidAppear(animated)
        keyboard.showsGlobe = ProcessInfo.processInfo.arguments.contains("--keyboard-legacy-globe") || traitCollection.userInterfaceIdiom != .phone || (view.window?.safeAreaInsets.bottom ?? 0) == 0
        keyboard.autocapitalizationType = field.autocapitalizationType
        field.becomeFirstResponder(); keyboard.synchronizeCapitalization()
    }
    func textViewDidChange(_ textView: UITextView) {
        placeholder.isHidden = !textView.text.isEmpty
        keyboard.synchronizeCapitalization()
    }
    override func viewWillDisappear(_ animated:Bool) { super.viewWillDisappear(animated); stopPreviewTransport(); keyboard.stopRepeating(); field.resignFirstResponder() }
    func textViewDidBeginEditing(_ textView:UITextView) { updatePreviewTransport() }
    func textViewDidEndEditing(_ textView:UITextView) { stopPreviewTransport(); keyboard.stopRepeating() }
    private func stopPreviewTransport() {
        activeMode = nil; server.stop(); nearby.stopWiFi(); nearby.stopBluetooth()
    }
    private func updatePreviewTransport() {
        guard !useSystemKeyboard, field.isFirstResponder, keyboard.webMode else { stopPreviewTransport(); return }
        let mode = keyboard.receiveMode
        if activeMode != mode {
            stopPreviewTransport(); activeMode = mode
            switch mode {
            case .web: server.start()
            case .wifi: nearby.startWiFi()
            case .bluetooth: nearby.startBluetooth()
            }
        }
        syncPreviewState()
    }
    private func syncPreviewState() {
        if keyboard.receiveMode == .web {
            keyboard.legacyMode = server.legacyMode
            keyboard.pairingCode = server.pairingCode; keyboard.ipAddress = server.ipAddress; keyboard.address = server.address
            keyboard.connectionStatus = server.status; keyboard.connected = server.connected
        } else {
            keyboard.pairingCode = nearby.pairingKey; keyboard.ipAddress = nil; keyboard.address = nil
            keyboard.connectionStatus = nearby.connections > 0 ? L10n.text("Computer connected") : (keyboard.receiveMode == .wifi ? nearby.wifiStatus : nearby.bluetoothStatus)
            keyboard.connected = nearby.connections > 0
        }
    }
}
