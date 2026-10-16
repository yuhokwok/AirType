import UIKit
import CoreImage.CIFilterBuiltins

final class AirKeyboardView: UIView {
    var insertText: ((String) -> Void)?
    var deleteText: (() -> Void)?
    var nextKeyboard: (() -> Void)?
    var configureGlobe: ((UIButton) -> Void)? { didSet { render() } }
    var onWebModeChange: ((Bool) -> Void)?
    var webMode = true { didSet { render(); onWebModeChange?(webMode) } }
    var dark = false { didSet { render() } }
    var returnTitle = "return" { didSet { if !webMode { render() } } }
    var address: String? { didSet {
        if pairing && address != oldValue { render() } else { updateStatus() }
    } }
    var ipAddress: String? { didSet {
        if pairing && ipAddress != oldValue { render() }
    } }
    var pairingCode: String? { didSet { updateStatus() } }
    var connectionStatus = "Disconnected" { didSet { updateStatus() } }
    var connected = false { didSet { updateStatus() } }
    private let content = UIStackView()
    private var statusLabel: UILabel?
    private var addressLabel: UILabel?
    private var dot: UIView?
    private var codeLabel: UILabel?
    private var shifted = true
    private var capsLock = false
    private var lastShift: TimeInterval = 0
    private var page = 0
    private var deleteTimer: Timer?
    private var pairing = false
    private var bg: UIColor { dark ? UIColor(white: 0.13, alpha: 1) : UIColor(red: 0.82, green: 0.83, blue: 0.85, alpha: 1) }
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
        deleteTimer?.invalidate(); deleteTimer = nil
        content.arrangedSubviews.forEach { content.removeArrangedSubview($0); $0.removeFromSuperview() }
        statusLabel = nil; addressLabel = nil; dot = nil; codeLabel = nil
        backgroundColor = bg
        if pairing && webMode { renderPairing(); return }
        if webMode { renderWeb() } else { renderKeys() }
        updateStatus()
    }
    private func renderWeb() {
        let panel = UIView()
        let logo = button("", symbol: nil) { [weak self] in self?.webMode = false }
        logo.backgroundColor = .clear
        logo.setImage(UIImage(named: "AirTypeLogo"), for: .normal)
        logo.imageView?.contentMode = .scaleAspectFit
        logo.layer.cornerRadius = 42; logo.clipsToBounds = true
        logo.accessibilityLabel = "Switch to traditional keyboard"
        let title = label("Web Access", size: 14)
        let status = label(connectionStatus, size: 11); statusLabel = status
        let line = UIView(); line.backgroundColor = cyan
        let badge = UIStackView(arrangedSubviews: [logo, title, line, status])
        badge.axis = .vertical; badge.alignment = .center; badge.spacing = 4
        badge.translatesAutoresizingMaskIntoConstraints = false; panel.addSubview(badge)
        NSLayoutConstraint.activate([logo.widthAnchor.constraint(equalToConstant: 84), logo.heightAnchor.constraint(equalToConstant: 84), line.widthAnchor.constraint(equalToConstant: 24), line.heightAnchor.constraint(equalToConstant: 1),badge.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 26),badge.centerYAnchor.constraint(equalTo: panel.centerYAnchor)])
        let code = label("", size: 24)
        code.font = .monospacedDigitSystemFont(ofSize: 24, weight: .medium)
        code.textColor = ink
        codeLabel = code
        let codeHint = label("Enter this code on the web page", size: 10)
        codeHint.numberOfLines = 0
        let connection = UIStackView(arrangedSubviews: [label("Pairing code", size: 12), code, codeHint])
        connection.axis = .vertical; connection.spacing = 6; connection.alignment = .center
        connection.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(connection)
        NSLayoutConstraint.activate([
            connection.leadingAnchor.constraint(greaterThanOrEqualTo: badge.trailingAnchor, constant: 12),
            connection.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -16),
            connection.centerYAnchor.constraint(equalTo: panel.centerYAnchor),
            connection.widthAnchor.constraint(lessThanOrEqualTo: panel.widthAnchor, multiplier: 0.53)
        ])
        content.addArrangedSubview(panel)
        let bar = UIStackView(); bar.axis = .horizontal; bar.spacing = 1
        bar.backgroundColor = dark ? UIColor(white: 0.28, alpha: 1) : UIColor(white: 0.69, alpha: 1)
        let globe = globeButton()
        let addressButton = button("", symbol: nil) { [weak self] in self?.pairing = true; self?.render() }
        addressButton.backgroundColor = bg
        addressButton.accessibilityLabel = "Show computer connection address and QR code"
        let addressRow = UIStackView(); addressRow.axis = .horizontal; addressRow.spacing = 5; addressRow.alignment = .center
        addressRow.isUserInteractionEnabled = false; addressRow.translatesAutoresizingMaskIntoConstraints = false
        let indicator = UIView(); indicator.layer.cornerRadius = 3; dot = indicator
        let url = label("", size: 12); url.textAlignment = .left; url.adjustsFontSizeToFitWidth = true; addressLabel = url
        addressRow.addArrangedSubview(indicator); addressRow.addArrangedSubview(url)
        addressButton.addSubview(addressRow)
        NSLayoutConstraint.activate([indicator.widthAnchor.constraint(equalToConstant: 6),indicator.heightAnchor.constraint(equalToConstant: 6),addressRow.centerXAnchor.constraint(equalTo: addressButton.centerXAnchor),addressRow.centerYAnchor.constraint(equalTo: addressButton.centerYAnchor),addressRow.leadingAnchor.constraint(greaterThanOrEqualTo: addressButton.leadingAnchor,constant: 8),addressRow.trailingAnchor.constraint(lessThanOrEqualTo: addressButton.trailingAnchor,constant: -8)])
        let delete = deleteButton()
        for item in [globe,addressButton,delete] { bar.addArrangedSubview(item) }
        NSLayoutConstraint.activate([bar.heightAnchor.constraint(equalToConstant: 44),globe.widthAnchor.constraint(equalToConstant: 44),delete.widthAnchor.constraint(equalToConstant: 44)])
        content.addArrangedSubview(bar)
    }
    private func renderPairing() {
        let row = UIStackView(); row.axis = .horizontal; row.spacing = 12; row.alignment = .center
        row.isLayoutMarginsRelativeArrangement = true; row.layoutMargins = UIEdgeInsets(top: 12,left: 16,bottom: 8,right: 16)
        let details = UIStackView(); details.axis = .vertical; details.spacing = 8
        details.addArrangedSubview(label("Open on your computer",size: 17))
        let code = label("", size: 18); codeLabel = code; details.addArrangedSubview(code)
        let url = label(address ?? connectionStatus,size: 11); url.numberOfLines = 0; url.font = .monospacedSystemFont(ofSize: 11,weight: .regular); details.addArrangedSubview(url)
        if let ipAddress, ipAddress != address {
            let fallback = label("IP fallback: " + String(ipAddress.split(separator: "#")[0]), size: 10)
            fallback.numberOfLines = 0
            details.addArrangedSubview(fallback)
        }
        let hint = label("Same Wi-Fi · Keep this keyboard open",size: 11); hint.numberOfLines = 0; details.addArrangedSubview(hint)
        row.addArrangedSubview(details)
        if let address {
            let filter = CIFilter.qrCodeGenerator(); filter.message = Data(address.utf8)
            if let output = filter.outputImage,
               let image = CIContext().createCGImage(output.transformed(by: CGAffineTransform(scaleX: 6,y: 6)),from:output.extent.applying(CGAffineTransform(scaleX: 6,y: 6))) {
                let qr = UIImageView(image: UIImage(cgImage:image)); qr.contentMode = .scaleAspectFit; qr.backgroundColor = .white; qr.layer.magnificationFilter = .nearest
                qr.widthAnchor.constraint(equalToConstant: 112).isActive = true
                qr.heightAnchor.constraint(equalToConstant: 112).isActive = true
                qr.accessibilityLabel = "QR code for AirType connection address"
                row.addArrangedSubview(qr)
            }
        }
        content.addArrangedSubview(row)
        let close = button("Back to Web Access",symbol: nil) { [weak self] in self?.pairing = false; self?.render() }
        close.heightAnchor.constraint(equalToConstant: 44).isActive = true
        content.addArrangedSubview(close)
        updateStatus()
    }
    private func renderKeys() {
        let grid = UIStackView(); grid.axis = .vertical; grid.spacing = 8; grid.distribution = .fillEqually
        grid.isLayoutMarginsRelativeArrangement = true; grid.layoutMargins = UIEdgeInsets(top: 5,left: 3,bottom: 5,right: 3)
        let rows: [[String]]
        switch page {
        case 1: rows = [Array("1234567890").map(String.init),["-","/",":",";","(",")","$","&","@","\""],[".",",","?","!","'"]]
        case 2: rows = [["[","]","{","}","#","%","^","*","+","="],["_","\\","|","~","<",">","€","£","¥","•"],[".",",","?","!","'"]]
        default: rows = [Array("qwertyuiop").map(String.init),Array("asdfghjkl").map(String.init),Array("zxcvbnm").map(String.init)]
        }
        for (index, letters) in rows.enumerated() {
            let row = UIStackView(); row.axis = .horizontal; row.spacing = 5; row.distribution = .fillEqually
            if index == 1 && page == 0 { row.isLayoutMarginsRelativeArrangement = true; row.layoutMargins = UIEdgeInsets(top:0,left:18,bottom:0,right:18) }
            if index == 2 {
                let shift = button(page == 0 ? "" : (page == 1 ? "#+=" : "123"),symbol: page == 0 ? (capsLock ? "capslock.fill" : (shifted ? "shift.fill" : "shift")) : nil) { [weak self] in
                    guard let self else { return }
                    if self.page > 0 { self.page = self.page == 1 ? 2 : 1 }
                    else {
                        let now = Date.timeIntervalSinceReferenceDate
                        if now - self.lastShift < 0.35 { self.capsLock = true; self.shifted = true }
                        else { self.capsLock = false; self.shifted.toggle() }
                        self.lastShift = now
                    }
                    self.render()
                }
                shift.accessibilityLabel = page == 0 ? (capsLock ? "Caps lock on" : "Shift") : "More symbols"
                row.addArrangedSubview(shift)
            }
            for letter in letters {
                let display = page == 0 && shifted ? letter.uppercased() : letter
                let key = button(display,symbol:nil) { [weak self] in
                    guard let self else { return }; self.insertText?(display)
                    if self.page == 0 && self.shifted && !self.capsLock { self.shifted = false; self.render() }
                }
                key.backgroundColor = dark ? UIColor(white:0.23,alpha:1) : .white
                key.titleLabel?.font = .systemFont(ofSize:22)
                row.addArrangedSubview(key)
            }
            if index == 2 { row.addArrangedSubview(deleteButton()) }
            grid.addArrangedSubview(row)
        }
        let bottom = UIStackView(); bottom.axis = .horizontal; bottom.spacing = 5
        let numeric = button(page == 0 ? "123" : "ABC",symbol:nil) { [weak self] in guard let self else { return }; self.page = self.page == 0 ? 1 : 0; self.render() }
        let globe = globeButton()
        let space = button("space",symbol:nil) { [weak self] in self?.insertText?(" ") }
        space.backgroundColor = dark ? UIColor(white:0.23,alpha:1) : .white
        let wifi = button("",symbol:"wifi") { [weak self] in self?.webMode = true }
        wifi.tintColor = cyan; wifi.accessibilityLabel = "Switch to Web Access"
        let enter = button(returnTitle,symbol:nil) { [weak self] in self?.insertText?("\n") }
        enter.backgroundColor = .systemBlue; enter.setTitleColor(.white,for:.normal)
        [numeric,globe,space,wifi,enter].forEach { bottom.addArrangedSubview($0) }
        NSLayoutConstraint.activate([numeric.widthAnchor.constraint(equalTo:bottom.widthAnchor,multiplier:0.105),globe.widthAnchor.constraint(equalTo:bottom.widthAnchor,multiplier:0.105),wifi.widthAnchor.constraint(equalTo:bottom.widthAnchor,multiplier:0.11),enter.widthAnchor.constraint(equalTo:bottom.widthAnchor,multiplier:0.21)])
        grid.addArrangedSubview(bottom); content.addArrangedSubview(grid)
    }
    private func globeButton() -> UIButton {
        let key = button("",symbol:"globe") { [weak self] in self?.nextKeyboard?() }
        key.accessibilityLabel = "Next keyboard"; configureGlobe?(key); return key
    }
    private func deleteButton() -> UIButton {
        let key = button("",symbol:"delete.left.fill") { [weak self] in self?.deleteText?() }
        key.accessibilityLabel = "Delete"
        key.addGestureRecognizer(UILongPressGestureRecognizer(target:self,action:#selector(repeatDelete(_:))))
        return key
    }
    @objc private func repeatDelete(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            deleteText?()
            deleteTimer = Timer.scheduledTimer(withTimeInterval:0.09,repeats:true) { [weak self] _ in self?.deleteText?() }
        } else if gesture.state != .changed { deleteTimer?.invalidate(); deleteTimer = nil }
    }
    private func label(_ text: String,size:CGFloat) -> UILabel {
        let label = UILabel(); label.text = text; label.font = .systemFont(ofSize:size,weight:.light); label.textColor = dark ? .lightGray : .gray; label.textAlignment = .center; return label
    }
    private func button(_ title:String,symbol:String?,action:@escaping ()->Void) -> UIButton {
        let key = UIButton(type:.custom); key.setTitle(title,for:.normal); key.setTitleColor(ink,for:.normal); key.tintColor = ink
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
        codeLabel?.text = pairingCode ?? "— — —"
        codeLabel?.accessibilityLabel = "Pairing code"
        codeLabel?.accessibilityValue = pairingCode
        statusLabel?.text = connectionStatus
        addressLabel?.text = address.map { String($0.split(separator:"#")[0]) } ?? connectionStatus
        dot?.backgroundColor = connected ? UIColor(red:0.5,green:0.95,blue:0.2,alpha:1) : .gray
    }
    func stopRepeating() { deleteTimer?.invalidate(); deleteTimer = nil }
    deinit { deleteTimer?.invalidate() }
}
