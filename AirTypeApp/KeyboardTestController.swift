import UIKit

final class KeyboardTestController: UIViewController, UITextViewDelegate {
    private let useSystemKeyboard: Bool
    private let field = UITextView()
    private let keyboard = AirKeyboardView()
    private let server = AirTypeServer()
    init(useSystemKeyboard:Bool) { self.useSystemKeyboard = useSystemKeyboard; super.init(nibName:nil,bundle:nil) }
    required init?(coder:NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor = .systemBackground
        let title = UILabel(); title.text = useSystemKeyboard ? "Try your AirType keyboard" : "AirType keyboard preview"; title.font = .systemFont(ofSize:25,weight:.light)
        let hint = UILabel(); hint.text = useSystemKeyboard ? "Tap below, then use the globe key to select AirType." : "Type here or send text from the browser portal.\nTap the AirType icon to use the traditional keyboard."; hint.numberOfLines = 0; hint.textColor = .secondaryLabel; hint.font = .systemFont(ofSize:14)
        field.font = .systemFont(ofSize:24); field.backgroundColor = .secondarySystemBackground; field.layer.cornerRadius = 12
        field.textContainerInset = UIEdgeInsets(top:16,left:12,bottom:16,right:12)
        field.accessibilityLabel = "AirType test text"; field.delegate = self
        let clear = UIButton(type:.system); clear.setTitle("Clear text",for:.normal); clear.addAction(UIAction { [weak self] _ in self?.field.text = "" },for:.touchUpInside)
        let appearance = UISegmentedControl(items:["Light","Dark"]); appearance.selectedSegmentIndex = 0
        appearance.addAction(UIAction { [weak self] _ in guard let self else { return }; self.keyboard.dark = appearance.selectedSegmentIndex == 1; self.field.keyboardAppearance = appearance.selectedSegmentIndex == 1 ? .dark : .light; self.field.reloadInputViews() },for:.valueChanged)
        let stack = UIStackView(arrangedSubviews:[title,hint,field,appearance,clear]); stack.axis = .vertical; stack.spacing = 16; stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([stack.topAnchor.constraint(equalTo:view.safeAreaLayoutGuide.topAnchor,constant:24),stack.leadingAnchor.constraint(equalTo:view.safeAreaLayoutGuide.leadingAnchor,constant:24),stack.trailingAnchor.constraint(equalTo:view.safeAreaLayoutGuide.trailingAnchor,constant:-24),field.heightAnchor.constraint(equalToConstant:180)])
        if !useSystemKeyboard {
            let keyboardHeight: CGFloat = traitCollection.userInterfaceIdiom == .pad ? 298 : 250
            let input = UIInputView(frame:CGRect(x:0,y:0,width:0,height:keyboardHeight),inputViewStyle:.keyboard)
            input.allowsSelfSizing = true
            keyboard.translatesAutoresizingMaskIntoConstraints = false; input.addSubview(keyboard)
            NSLayoutConstraint.activate([keyboard.topAnchor.constraint(equalTo:input.topAnchor),keyboard.bottomAnchor.constraint(equalTo:input.bottomAnchor),keyboard.leadingAnchor.constraint(equalTo:input.leadingAnchor),keyboard.trailingAnchor.constraint(equalTo:input.trailingAnchor),input.heightAnchor.constraint(equalToConstant:keyboardHeight)])
            field.inputView = input
            keyboard.insertText = { [weak self] in self?.field.insertText($0) }
            keyboard.deleteText = { [weak self] in self?.field.deleteBackward() }
            keyboard.nextKeyboard = { [weak self] in self?.field.resignFirstResponder() }
            keyboard.onWebModeChange = { [weak self] web in if web { self?.server.start() } else { self?.server.stop() } }
            server.onStateChange = { [weak self] in guard let self else { return }; self.keyboard.pairingCode = self.server.pairingCode; self.keyboard.ipAddress = self.server.ipAddress; self.keyboard.address = self.server.address; self.keyboard.connectionStatus = self.server.status; self.keyboard.connected = self.server.connected }
            server.onCommand = { [weak self] command in
                guard let self, self.field.isFirstResponder else { return }
                switch command.action { case .insert: self.field.insertText(command.text ?? ""); case .delete: self.field.deleteBackward(); case .newline: self.field.insertText("\n") }
            }
        }
    }
    override func viewDidAppear(_ animated:Bool) { super.viewDidAppear(animated); field.becomeFirstResponder() }
    override func viewWillDisappear(_ animated:Bool) { super.viewWillDisappear(animated); server.stop(); keyboard.stopRepeating(); field.resignFirstResponder() }
    func textViewDidBeginEditing(_ textView:UITextView) { if !useSystemKeyboard && keyboard.webMode { server.start() } }
    func textViewDidEndEditing(_ textView:UITextView) { server.stop(); keyboard.stopRepeating() }
}
