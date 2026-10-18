import UIKit
import CoreImage.CIFilterBuiltins

final class AirKeyboardView: UIView {
    var insertText: ((String) -> Void)?
    var deleteText: (() -> Void)?
    var nextKeyboard: (() -> Void)?
    var contextBeforeInput: (() -> String?)?
    var moveCursor: ((Int) -> Void)?
    var hasSelection: (() -> Bool)?
    var spellCheckingEnabled = true
    private var localKeyboard: LocalKeyboardView?
    var autocapitalizationType: UITextAutocapitalizationType = .sentences
    var showsGlobe = true { didSet { if showsGlobe != oldValue { render() } } }
    var configureGlobe: ((UIButton) -> Void)? { didSet { render() } }
    var onReceiveModeChange: (() -> Void)?
    private var selectedReceiveMode: RemoteInputMode = .web
    var receiveMode: RemoteInputMode {
        get { selectedReceiveMode }
        set {
            let mode = AirTypeFeatures.availableInputMode(newValue)
            guard mode != selectedReceiveMode else { return }
            selectedReceiveMode = mode
            pairing = false; render(); onReceiveModeChange?()
        }
    }
    var onWebModeChange: ((Bool) -> Void)?
    var webMode = true { didSet { render(); onWebModeChange?(webMode) } }
    var dark = false { didSet { render() } }
    var returnTitle = L10n.text("return") { didSet { if !webMode { render() } } }
    var address: String? { didSet {
        if pairing && address != oldValue { render() } else { updateStatus() }
    } }
    var ipAddress: String? { didSet {
        if pairing && ipAddress != oldValue { render() } else { updateStatus() }
    } }
    var pairingCode: String? { didSet { updateStatus() } }
    var connectionStatus = L10n.text("Disconnected") { didSet { updateStatus() } }
    var connected = false { didSet { updateStatus() } }
    private let content = UIStackView()
    private var statusLabel: UILabel?
    private var addressLabel: UILabel?
    private var secondaryAddressLabel: UILabel?
    private var addressSwapSymbol: UIImageView?
    private weak var connectionAddressButton: UIButton?
    private var prefersIPAddress = false
    private var primaryAddress: String? { prefersIPAddress ? (ipAddress ?? address) : (address ?? ipAddress) }
    private var dot: UIView?
    private var codeLabel: UILabel?
    private var deleteTimer: Timer?
    private var deleting = false
    private var deleteOrigin: CGFloat = 0
    private var deleteDrag: CGFloat = 0
    private var compactPanel = false
    private var pairing = false
    private var ink: UIColor { dark ? .white : UIColor(white: 0.18, alpha: 1) }
    private let cyan = UIColor(red: 0.08, green: 0.75, blue: 0.79, alpha: 1)
    override init(frame: CGRect) {
        super.init(frame: frame)
        content.axis = .vertical; content.spacing = 0
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        NSLayoutConstraint.activate([content.topAnchor.constraint(equalTo: topAnchor), content.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor), content.leadingAnchor.constraint(equalTo: leadingAnchor), content.trailingAnchor.constraint(equalTo: trailingAnchor)])
        render()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    private func render() {
        stopRepeating()
        content.arrangedSubviews.forEach { content.removeArrangedSubview($0); $0.removeFromSuperview() }
        localKeyboard = nil
        statusLabel = nil; addressLabel = nil; secondaryAddressLabel = nil; addressSwapSymbol = nil; connectionAddressButton = nil; dot = nil; codeLabel = nil
        backgroundColor = .clear
        isOpaque = false
        if pairing && webMode { renderPairing(); return }
        if webMode { renderWeb() } else { renderKeys() }
        updateStatus()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        let compact = bounds.height > 0 && bounds.height < 200
        if compactPanel != compact { compactPanel = compact; render() }
    }
    private func renderWeb() {
        if AirTypeFeatures.nearbyTypingEnabled {
            let selector = UISegmentedControl(items: RemoteInputMode.allCases.map(\.rawValue))
            selector.selectedSegmentIndex = RemoteInputMode.allCases.firstIndex(of: receiveMode) ?? 0
            selector.accessibilityLabel = L10n.text("Computer connection mode")
            selector.addAction(UIAction { [weak self, weak selector] _ in
                guard let self, let selector else { return }
                self.receiveMode = RemoteInputMode.allCases[selector.selectedSegmentIndex]
            }, for: .valueChanged)
            selector.heightAnchor.constraint(equalToConstant: 30).isActive = true
            let selectorRow = UIView()
            selector.translatesAutoresizingMaskIntoConstraints = false
            selectorRow.addSubview(selector)
            NSLayoutConstraint.activate([
                selectorRow.heightAnchor.constraint(equalToConstant: 42),
                selector.leadingAnchor.constraint(equalTo: selectorRow.leadingAnchor, constant: 16),
                selector.trailingAnchor.constraint(equalTo: selectorRow.trailingAnchor, constant: -16),
                selector.centerYAnchor.constraint(equalTo: selectorRow.centerYAnchor)
            ])
            content.addArrangedSubview(selectorRow)
        }
        let panel = UIStackView(); panel.axis = .horizontal; panel.distribution = .fillEqually
        panel.accessibilityIdentifier = "AirTypeConnectionPanel"
        let logo = button("", symbol: nil, key: CircularAirTypeLogoButton(type: .custom)) { [weak self] in self?.webMode = false }
        logo.backgroundColor = .white
        logo.setImage(UIImage(named: "AirTypeLogo"), for: .normal)
        logo.imageView?.contentMode = .scaleAspectFit
        logo.clipsToBounds = true
        logo.accessibilityLabel = L10n.text("Switch to traditional keyboard")
        let title = label(receiveMode == .web ? L10n.text("Web Access") : receiveMode.rawValue, size: compactPanel ? 12 : 14)
        let status = label(connectionStatus, size: compactPanel ? 9 : 11); statusLabel = status
        status.adjustsFontSizeToFitWidth = true; status.minimumScaleFactor = 0.75
        let badge = UIStackView(arrangedSubviews: [logo, title, status])
        badge.axis = .vertical; badge.alignment = .center; badge.spacing = 4
        let statusHalf = UIView(); statusHalf.accessibilityIdentifier = "AirTypeStatusHalf"
        badge.translatesAutoresizingMaskIntoConstraints = false; statusHalf.addSubview(badge)
        panel.addArrangedSubview(statusHalf)
        NSLayoutConstraint.activate([
            logo.heightAnchor.constraint(equalTo: panel.heightAnchor, multiplier: compactPanel ? 0.40 : 0.48),
            logo.widthAnchor.constraint(equalTo: logo.heightAnchor),
            badge.leadingAnchor.constraint(equalTo: statusHalf.leadingAnchor, constant: 8),
            badge.trailingAnchor.constraint(equalTo: statusHalf.trailingAnchor, constant: -8),
            badge.centerYAnchor.constraint(equalTo: statusHalf.centerYAnchor),
            status.widthAnchor.constraint(lessThanOrEqualTo: badge.widthAnchor)
        ])
        let code = label("", size: receiveMode == .web ? 24 : 15)
        code.font = .monospacedSystemFont(ofSize: receiveMode == .web ? 24 : 15, weight: .medium)
        code.numberOfLines = 2
        code.textAlignment = .center
        code.adjustsFontSizeToFitWidth = true
        code.textColor = ink
        codeLabel = code
        let codeHint = label(receiveMode == .web ? L10n.text("Enter this code on the web page") : L10n.text("Enter this key in AirType Desktop"), size: 10)
        codeHint.numberOfLines = 0
        let connection = UIStackView(arrangedSubviews: [label(receiveMode == .web ? L10n.text("Pairing code") : L10n.text("Pairing key"), size: 12), code, codeHint])
        connection.axis = .vertical; connection.spacing = 6; connection.alignment = .center
        connection.alignment = .fill
        let codeHalf = UIView(); codeHalf.accessibilityIdentifier = "AirTypePairingHalf"
        connection.translatesAutoresizingMaskIntoConstraints = false; codeHalf.addSubview(connection)
        panel.addArrangedSubview(codeHalf)
        NSLayoutConstraint.activate([
            connection.leadingAnchor.constraint(equalTo: codeHalf.leadingAnchor, constant: 8),
            connection.trailingAnchor.constraint(equalTo: codeHalf.trailingAnchor, constant: -8),
            connection.centerYAnchor.constraint(equalTo: codeHalf.centerYAnchor)
        ])
        content.addArrangedSubview(panel)
        let bar = UIStackView(); bar.axis = .horizontal; bar.spacing = 8; bar.alignment = .center
        bar.isLayoutMarginsRelativeArrangement = true
        bar.layoutMargins = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        let back = button("", symbol: "keyboard") { [weak self] in self?.pairing = false; self?.webMode = false }
        back.accessibilityLabel = L10n.text("Back to keyboard")
        styleCircularControl(back, symbolPointSize: 12)
        bar.addArrangedSubview(back)
        if showsGlobe { let globe = globeButton(); styleCircularControl(globe); bar.addArrangedSubview(globe) }
        let addressButton = button("", symbol: nil) { [weak self] in
            guard let self else { return }
            if let address = self.address, let ip = self.ipAddress, address != ip {
                self.prefersIPAddress.toggle(); self.updateStatus()
            }
        }
        connectionAddressButton = addressButton
        addressButton.accessibilityIdentifier = "AirTypeAddressToggle"
        addressButton.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(showConnectionDetails(_:))))
        addressButton.accessibilityCustomActions = [UIAccessibilityCustomAction(name: L10n.text("Show computer connection address and QR code"), actionHandler: { [weak self] _ in
            self?.pairing = true; self?.render(); return true
        })]
        addressButton.backgroundColor = .clear
        addressButton.accessibilityLabel = L10n.text("Swap Bonjour and IP address")
        let addressRow = UIStackView(); addressRow.axis = .horizontal; addressRow.spacing = 5; addressRow.alignment = .center
        addressRow.isUserInteractionEnabled = false
        let indicator = UIView(); indicator.layer.cornerRadius = 3; dot = indicator
        let url = label("", size: 12); url.textAlignment = .left; url.adjustsFontSizeToFitWidth = true; addressLabel = url
        addressRow.addArrangedSubview(indicator); addressRow.addArrangedSubview(url)
        url.accessibilityIdentifier = "AirTypePrimaryAddress"
        let secondary = label("", size: 9); secondary.adjustsFontSizeToFitWidth = true
        secondary.accessibilityIdentifier = "AirTypeSecondaryAddress"; secondaryAddressLabel = secondary
        let swapSymbol = UIImageView(image: UIImage(systemName: "arrow.up.arrow.down", withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)))
        swapSymbol.tintColor = dark ? .lightGray : .gray
        swapSymbol.setContentCompressionResistancePriority(.required, for: .horizontal)
        addressSwapSymbol = swapSymbol
        let addressLines = UIStackView(arrangedSubviews: [addressRow, secondary])
        addressLines.axis = .vertical; addressLines.alignment = .center; addressLines.spacing = 2
        let addressWithSymbol = UIStackView(arrangedSubviews: [addressLines, swapSymbol])
        addressWithSymbol.axis = .horizontal; addressWithSymbol.alignment = .center; addressWithSymbol.spacing = 8
        let addresses = UIStackView(arrangedSubviews: [addressWithSymbol])
        addresses.axis = .vertical; addresses.alignment = .center; addresses.spacing = 2
        addresses.isUserInteractionEnabled = false; addresses.translatesAutoresizingMaskIntoConstraints = false
        addressButton.addSubview(addresses)
        NSLayoutConstraint.activate([indicator.widthAnchor.constraint(equalToConstant: 6),indicator.heightAnchor.constraint(equalToConstant: 6),addresses.centerXAnchor.constraint(equalTo: addressButton.centerXAnchor),addresses.centerYAnchor.constraint(equalTo: addressButton.centerYAnchor),addresses.leadingAnchor.constraint(greaterThanOrEqualTo: addressButton.leadingAnchor,constant: 4),addresses.trailingAnchor.constraint(lessThanOrEqualTo: addressButton.trailingAnchor,constant: -4),addressWithSymbol.widthAnchor.constraint(lessThanOrEqualTo: addresses.widthAnchor),addressRow.widthAnchor.constraint(lessThanOrEqualTo: addressLines.widthAnchor),secondary.widthAnchor.constraint(lessThanOrEqualTo: addressLines.widthAnchor)])
        let delete = deleteButton(); styleCircularControl(delete, symbolPointSize: 12)
        bar.addArrangedSubview(addressButton); bar.addArrangedSubview(delete)
        bar.heightAnchor.constraint(equalToConstant: 56).isActive = true
        addressButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        content.addArrangedSubview(bar)
    }
    @objc private func showConnectionDetails(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        pairing = true; render()
    }
    private func renderPairing() {
        let row = UIStackView(); row.axis = .horizontal; row.spacing = 12; row.alignment = .center
        row.isLayoutMarginsRelativeArrangement = true; row.layoutMargins = UIEdgeInsets(top: 12,left: 16,bottom: 8,right: 16)
        let details = UIStackView(); details.axis = .vertical; details.spacing = 8
        details.addArrangedSubview(label(receiveMode == .web ? L10n.text("Open on your computer") : L10n.text("Open AirType Desktop on Mac"),size: 17))
        let code = label("", size: 18); code.numberOfLines = 2; code.font = .monospacedSystemFont(ofSize: 16, weight: .medium); codeLabel = code; details.addArrangedSubview(code)
        let url = label(receiveMode == .web ? (primaryAddress ?? connectionStatus) : "Choose \(receiveMode.rawValue), select this keyboard, and enter its pairing key.",size: 11); url.numberOfLines = 0; url.font = .monospacedSystemFont(ofSize: 11,weight: .regular); details.addArrangedSubview(url)
        if receiveMode == .web, let alternate = prefersIPAddress ? address : ipAddress, alternate != primaryAddress {
            let fallback = label(String(alternate.split(separator: "#")[0]), size: 10)
            fallback.numberOfLines = 0
            details.addArrangedSubview(fallback)
        }
        let hint = label(receiveMode == .web ? L10n.text("Same Wi-Fi · Keep this keyboard open") : L10n.text("Keep this keyboard visible while receiving"),size: 11); hint.numberOfLines = 0; details.addArrangedSubview(hint)
        row.addArrangedSubview(details)
        if receiveMode == .web, let address = primaryAddress {
            let filter = CIFilter.qrCodeGenerator(); filter.message = Data(address.utf8)
            if let output = filter.outputImage,
               let image = CIContext().createCGImage(output.transformed(by: CGAffineTransform(scaleX: 6,y: 6)),from:output.extent.applying(CGAffineTransform(scaleX: 6,y: 6))) {
                let qr = UIImageView(image: UIImage(cgImage:image)); qr.contentMode = .scaleAspectFit; qr.backgroundColor = .white; qr.layer.magnificationFilter = .nearest
                qr.widthAnchor.constraint(equalToConstant: 112).isActive = true
                qr.heightAnchor.constraint(equalToConstant: 112).isActive = true
                qr.accessibilityLabel = L10n.text("QR code for AirType connection address")
                row.addArrangedSubview(qr)
            }
        }
        content.addArrangedSubview(row)
        let close = button(L10n.text("Back to connection"),symbol: nil) { [weak self] in self?.pairing = false; self?.render() }
        close.heightAnchor.constraint(equalToConstant: 44).isActive = true
        content.addArrangedSubview(close)
        updateStatus()
    }
    private func renderKeys() {
        let keys = LocalKeyboardView()
        keys.insertText = { [weak self] in self?.insertText?($0) }
        keys.deleteText = { [weak self] in self?.deleteText?() }
        keys.moveCursor = { [weak self] in self?.moveCursor?($0) }
        keys.openAirType = { [weak self] in self?.webMode = true }
        keys.configureGlobe = { [weak self] button in
            if let configure = self?.configureGlobe { configure(button) }
            else { button.addAction(UIAction { [weak self] _ in self?.nextKeyboard?() }, for: .touchUpInside) }
        }
        keys.hasSelection = { [weak self] in self?.hasSelection?() ?? false }
        keys.contextBeforeInput = { [weak self] in self?.contextBeforeInput?() }
        keys.autocapitalizationType = autocapitalizationType
        keys.spellCheckingEnabled = spellCheckingEnabled
        keys.dark = dark; keys.returnTitle = returnTitle; keys.showsGlobe = showsGlobe
        localKeyboard = keys
        content.addArrangedSubview(keys)
        keys.synchronizeCapitalization()
    }
    private func globeButton() -> UIButton {
        let key = button("",symbol:"globe") { [weak self] in self?.nextKeyboard?() }
        key.accessibilityLabel = L10n.text("Next keyboard"); configureGlobe?(key); return key
    }
    private func styleCircularControl(_ key: UIButton, symbolPointSize: CGFloat = 17) {
        key.widthAnchor.constraint(equalToConstant: 44).isActive = true
        key.heightAnchor.constraint(equalToConstant: 44).isActive = true
        let symbolSize = UIImage.SymbolConfiguration(pointSize: symbolPointSize, weight: .regular)
        let symbolImage = key.image(for: .normal)?.applyingSymbolConfiguration(symbolSize)
        key.setImage(symbolImage, for: .normal)
        key.setPreferredSymbolConfiguration(symbolSize, forImageIn: .normal)
        if #available(iOS 26, *) {
            var config = UIButton.Configuration.glass()
            config.preferredSymbolConfigurationForImage = symbolSize
            config.cornerStyle = .capsule
            config.image = symbolImage
            config.baseForegroundColor = ink
            key.backgroundColor = .clear
            key.configuration = config
        } else {
            key.layer.cornerRadius = 22
            key.backgroundColor = dark ? UIColor(white: 0.25, alpha: 1) : UIColor(white: 0.95, alpha: 0.8)
        }
    }
    private func deleteButton() -> UIButton {
        let key = KeyboardDeleteButton(type: .custom)
        _ = button("", symbol: "delete.left", key: key) {}
        key.onAccessibleDelete = { [weak self] in self?.deleteText?(); self?.synchronizeCapitalization() }
        key.accessibilityLabel = L10n.text("Delete")
        key.addTarget(self, action: #selector(beginDelete(_:event:)), for: .touchDown)
        key.addTarget(self, action: #selector(dragDelete(_:event:)), for: [.touchDragInside, .touchDragOutside])
        key.addTarget(self, action: #selector(endDelete), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        return key
    }
    @objc private func beginDelete(_ key: UIButton, event: UIEvent?) {
        stopRepeating(); deleting = true
        deleteOrigin = event?.allTouches?.first?.location(in: self).x ?? 0; deleteDrag = 0
        deleteText?()
        scheduleDelete(after: 1)
    }
    @objc private func dragDelete(_ key: UIButton, event: UIEvent?) {
        guard let touch = event?.allTouches?.first else { return }
        deleteDrag = deleteOrigin - touch.location(in: self).x
    }
    private func scheduleDelete(after delay: TimeInterval) {
        let timer = Timer(timeInterval: delay, repeats: false) { [weak self] _ in
            guard let self, self.deleting else { return }
            self.deleteText?()
            self.scheduleDelete(after: KeyboardTypingBehavior.deleteInterval(leftDrag: self.deleteDrag))
        }
        deleteTimer = timer; RunLoop.main.add(timer, forMode: .common)
    }
    @objc private func endDelete() { stopRepeating(); synchronizeCapitalization() }
    func synchronizeCapitalization() {
        localKeyboard?.autocapitalizationType = autocapitalizationType
        localKeyboard?.spellCheckingEnabled = spellCheckingEnabled
        localKeyboard?.synchronizeCapitalization()
    }
    private func label(_ text: String,size:CGFloat) -> UILabel {
        let label = UILabel(); label.text = L10n.text(text); label.font = .systemFont(ofSize:size,weight:.light); label.textColor = dark ? .lightGray : .gray; label.textAlignment = .center; return label
    }
    private func button(_ title:String,symbol:String?,key: UIButton = UIButton(type: .custom),action:@escaping ()->Void) -> UIButton {
        key.setTitle(title,for:.normal); key.setTitleColor(ink,for:.normal); key.tintColor = ink
        key.titleLabel?.font = .systemFont(ofSize:14); key.backgroundColor = dark ? UIColor(white:0.19,alpha:1) : UIColor(white:0.69,alpha:1)
        key.layer.cornerRadius = webMode ? 0 : 5
        if let symbol { key.setImage(UIImage(systemName:symbol,withConfiguration:UIImage.SymbolConfiguration(pointSize:21,weight:.regular)),for:.normal) }
        key.addAction(UIAction { _ in action() },for:.touchUpInside)
        key.addTarget(self,action:#selector(press(_:)),for:.touchDown)
        key.addTarget(self,action:#selector(releaseKey(_:)),for:[.touchUpInside,.touchUpOutside,.touchCancel,.touchDragExit])
        return key
    }
    @objc private func press(_ button:UIButton) { button.alpha = 0.55 }
    @objc private func releaseKey(_ button:UIButton) { button.alpha = 1 }
    private func updateStatus() {
        if receiveMode != .web, let pairingCode, pairingCode.count == 20 {
            let middle = pairingCode.index(pairingCode.startIndex, offsetBy: 10)
            codeLabel?.text = String(pairingCode[..<middle]) + "\n" + String(pairingCode[middle...])
        } else { codeLabel?.text = pairingCode ?? "— — —" }
        codeLabel?.accessibilityLabel = receiveMode == .web ? L10n.text("Pairing code") : L10n.text("Pairing key")
        codeLabel?.accessibilityValue = pairingCode
        statusLabel?.text = L10n.text(connectionStatus)
        addressLabel?.text = receiveMode == .web ? (primaryAddress.map { String($0.split(separator:"#")[0]) } ?? connectionStatus) : "\(receiveMode.rawValue) · Connection details"
        let alternate = prefersIPAddress ? address : ipAddress
        let secondary = receiveMode == .web && alternate != primaryAddress ? alternate.map { String($0.split(separator: "#")[0]) } : nil
        secondaryAddressLabel?.text = secondary
        secondaryAddressLabel?.isHidden = secondary == nil
        addressSwapSymbol?.isHidden = secondary == nil
        connectionAddressButton?.accessibilityHint = secondary == nil ? nil : L10n.text("Tap to swap addresses")
        connectionAddressButton?.accessibilityValue = [addressLabel?.text, secondary].compactMap { $0 }.joined(separator: ", ")
        dot?.backgroundColor = connected ? UIColor(red:0.5,green:0.95,blue:0.2,alpha:1) : .gray
    }
    func stopRepeating() { deleteTimer?.invalidate(); deleteTimer = nil; deleting = false; localKeyboard?.cancelTouches() }
    deinit { deleteTimer?.invalidate() }
}

private final class KeyboardDeleteButton: UIButton {
    var onAccessibleDelete: (() -> Void)?
    override func accessibilityActivate() -> Bool {
        onAccessibleDelete?()
        return true
    }
}

private final class CircularAirTypeLogoButton: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = min(bounds.width, bounds.height) / 2
    }
}
