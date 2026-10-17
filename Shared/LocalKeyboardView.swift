import UIKit

/// A stable UIKit touch surface: changing Shift or a symbol page never replaces touch ownership.
final class LocalKeyboardView: UIView {
    var insertText: ((String) -> Void)?
    var deleteText: (() -> Void)?
    var moveCursor: ((Int) -> Void)?
    var openAirType: (() -> Void)?
    var configureGlobe: ((UIButton) -> Void)?
    var contextBeforeInput: (() -> String?)?
    var hasSelection: (() -> Bool)?
    var autocapitalizationType: UITextAutocapitalizationType = .sentences
    var spellCheckingEnabled = true
    var dark = false { didSet { refresh() } }
    var showsGlobe = false { didSet { if showsGlobe != oldValue { rebuildKeys() } } }
    var returnTitle = "return" { didSet { refresh() } }
    private(set) var interaction = LocalKeyboardInteraction<ObjectIdentifier>()
    private var rows: [[LocalKeyButton]] = []
    private var renderedPage: LocalKeyboardPage?
    private let suggestions = UIStackView()
    private let checker = UITextChecker()
    private var checkedWord = ""
    private var points: [ObjectIdentifier: CGPoint] = [:]
    private var popups: [ObjectIdentifier: LocalKeyPreview] = [:]
    private var deleteOwner: ObjectIdentifier?
    private var deleteTimer: Timer?
    private var deleteOrigin: CGFloat = 0
    private var spaceOwner: ObjectIdentifier?
    private var spaceTimer: Timer?
    private var spaceCursorActive = false
    private var spaceLastX: CGFloat = 0
    private var spaceRemainder: CGFloat = 0
    private var ink: UIColor { dark ? .white : .label }
    private var keyColor: UIColor { dark ? UIColor(white: 0.23, alpha: 1) : .white }
    private var controlColor: UIColor { dark ? UIColor(white: 0.18, alpha: 1) : UIColor(white: 0.69, alpha: 1) }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true; clipsToBounds = false
        suggestions.axis = .horizontal; suggestions.distribution = .fillEqually; suggestions.spacing = 1
        suggestions.accessibilityIdentifier = "SpellingSuggestions"
        addSubview(suggestions)
        rebuildKeys(); updateSuggestions()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        suggestions.frame = CGRect(x: 8, y: 0, width: max(0, bounds.width - 16), height: 34)
        let gap: CGFloat = 5, verticalGap: CGFloat = 7
        let top: CGFloat = 39, bottom: CGFloat = 5
        let height = max(0, (bounds.height - top - bottom - verticalGap * 3) / 4)
        for (index, row) in rows.enumerated() {
            let inset: CGFloat = index == 1 && interaction.page == .letters ? bounds.width / 20 : 3
            let available = bounds.width - inset * 2 - gap * CGFloat(max(0, row.count - 1))
            var widths = Array(repeating: available / CGFloat(max(1, row.count)), count: row.count)
            if index == 3 {
                widths = row.map { button in
                    switch button.key {
                    case .space: return 0
                    case .enter: return bounds.width * 0.21
                    default: return bounds.width * 0.105
                    }
                }
                if let space = row.firstIndex(where: { $0.key == .space }) { widths[space] = available - widths.reduce(0, +) }
            }
            var x = inset
            for (column, button) in row.enumerated() {
                button.frame = CGRect(x: x, y: top + CGFloat(index) * (height + verticalGap), width: max(0, widths[column]), height: height)
                button.layer.cornerRadius = traitCollection.userInterfaceIdiom == .pad && bounds.width >= 600 ? 14 : 10
                button.layer.cornerCurve = .continuous
                x += widths[column] + gap
            }
        }
        refreshPopups()
    }
    // All typing contacts stay on this surface; system globe and spelling buttons remain native controls.
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !isHidden, alpha > 0.01, bounds.contains(point) else { return nil }
        if suggestions.frame.contains(point) { return suggestions.hitTest(convert(point, to: suggestions), with: event) }
        if let globe = rows.flatMap({ $0 }).first(where: { $0.key == .globe }), globe.frame.contains(point) {
            return globe.hitTest(convert(point, to: globe), with: event)
        }
        return self
    }
    private func rebuildKeys() {
        rows.flatMap { $0 }.forEach { $0.removeFromSuperview() }; rows.removeAll()
        renderedPage = interaction.page
        let characters: [[String]]
        switch interaction.page {
        case .letters: characters = [Array("qwertyuiop").map(String.init), Array("asdfghjkl").map(String.init), Array("zxcvbnm").map(String.init)]
        case .numbers: characters = [Array("1234567890").map(String.init), ["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""], [".", ",", "?", "!", "'"]]
        case .symbols: characters = [["[", "]", "{", "}", "#", "%", "^", "*", "+", "="], ["_", "\\", "|", "~", "<", ">", "€", "£", "¥", "•"], [".", ",", "?", "!", "'"]]
        }
        for (index, letters) in characters.enumerated() {
            var keys = letters.map { LocalKeyboardKey.character($0) }
            if index == 2 {
                keys.insert(interaction.page == .letters ? .shift : .layout(interaction.page == .numbers ? .symbols : .numbers), at: 0)
                keys.append(.delete)
            }
            rows.append(keys.map(makeKey))
        }
        var bottom: [LocalKeyboardKey] = [.layout(interaction.page == .letters ? .numbers : .letters)]
        if showsGlobe { bottom.append(.globe) }
        bottom += [.wifi, .space, .character("."), .enter]
        rows.append(bottom.map(makeKey))
        refresh(); setNeedsLayout()
    }
    private func makeKey(_ key: LocalKeyboardKey) -> LocalKeyButton {
        let button = LocalKeyButton(type: .custom); button.key = key
        button.onActivate = { [weak self] in self?.activate(key) }
        button.addAction(UIAction { [weak button] _ in button?.onActivate?() }, for: .touchUpInside)
        button.isExclusiveTouch = false
        if key == .globe { configureGlobe?(button) }
        addSubview(button)
        return button
    }
    private func refresh() {
        if renderedPage != interaction.page { rebuildKeys(); return }
        for button in rows.flatMap({ $0 }) {
            button.setImage(nil, for: .normal); button.setTitle(nil, for: .normal)
            button.tintColor = ink; button.setTitleColor(ink, for: .normal)
            button.backgroundColor = controlColor
            button.titleLabel?.font = .systemFont(ofSize: 14)
            var title: String?, symbol: String?, accessibility: String?
            switch button.key {
            case .character(let character):
                title = interaction.uppercase ? character.uppercased() : character
                button.backgroundColor = keyColor; button.titleLabel?.font = .systemFont(ofSize: 22)
            case .shift:
                symbol = interaction.shift == .locked ? "capslock.fill" : (interaction.uppercase ? "shift.fill" : "shift")
                accessibility = interaction.shift == .locked ? "Caps lock on" : "Shift"
            case .layout(let page):
                title = page == .letters ? "ABC" : (page == .symbols ? "#+=" : "123")
                accessibility = "Switch to \(title!)"
            case .space: title = "space"; button.backgroundColor = keyColor
            case .delete: symbol = "delete.left"; accessibility = "Delete"
            case .enter:
                title = returnTitle; button.backgroundColor = .systemBlue; button.setTitleColor(.white, for: .normal)
            case .wifi: symbol = "wifi"; accessibility = "Switch to AirType"; button.tintColor = .systemTeal; button.accessibilityIdentifier = "AirTypeModeButton"
            case .globe: symbol = "globe"; accessibility = "Next keyboard"
            }
            button.setTitle(title, for: .normal)
            if let symbol { button.setImage(UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 21)), for: .normal) }
            button.accessibilityLabel = accessibility ?? title
            button.alpha = interaction.contacts.values.contains { !$0.committed && $0.current == button.key } ? 0.6 : 1
        }
        refreshPopups()
    }
    func synchronizeCapitalization() {
        interaction.synchronizeShift(KeyboardTypingBehavior.automaticShift(type: autocapitalizationType, context: contextBeforeInput?()), context: contextBeforeInput?())
        refresh(); updateSuggestions()
    }
    private func activate(_ key: LocalKeyboardKey) {
        // Accessibility and programmatic control activation use the same reducer.
        let token = NSObject()
        let id = ObjectIdentifier(token)
        apply(interaction.begin(id, key: key, context: contextBeforeInput?()))
        apply(interaction.end(id, on: key, context: contextBeforeInput?()))
        synchronizeCapitalization()
        withExtendedLifetime(token) {}
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches.sorted(by: { $0.timestamp < $1.timestamp }) {
            beginContact(ObjectIdentifier(touch), at: touch.location(in: self), tapCount: touch.tapCount)
        }
        refresh()
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            moveContact(ObjectIdentifier(touch), to: touch.location(in: self))
        }
        refresh()
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches.sorted(by: { $0.timestamp < $1.timestamp }) {
            endContact(ObjectIdentifier(touch), at: touch.location(in: self))
        }
        synchronizeCapitalization()
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches { let id = ObjectIdentifier(touch); apply(interaction.cancel(id)); finishTouch(id) }
        refresh()
    }
    func beginContact(_ id: ObjectIdentifier, at point: CGPoint, tapCount: Int = 1) {
        guard let key = key(at: point) else { return }
        points[id] = point
        apply(interaction.begin(id, key: key, tapCount: tapCount, context: contextBeforeInput?()))
        if key == .delete { deleteOwner = id; deleteOrigin = point.x }
        if key == .space { beginSpace(id, at: point.x) }
        refresh(); layoutIfNeeded()
    }
    func moveContact(_ id: ObjectIdentifier, to point: CGPoint) {
        points[id] = point
        if id == spaceOwner, spaceCursorActive {
            let distance = point.x - spaceLastX + spaceRemainder
            let offset = Int(distance / 12)
            spaceRemainder = distance - CGFloat(offset) * 12; spaceLastX = point.x
            if offset != 0 { moveCursor?(offset); updateSuggestions() }
        } else {
            if id == spaceOwner, key(at: point) != .space { spaceTimer?.invalidate(); spaceTimer = nil }
            interaction.move(id, to: key(at: point))
        }
        refresh()
    }
    func endContact(_ id: ObjectIdentifier, at point: CGPoint) {
        if id == spaceOwner && spaceCursorActive { apply(interaction.cancel(id)) }
        else { apply(interaction.end(id, on: key(at: point), context: contextBeforeInput?())) }
        finishTouch(id); synchronizeCapitalization(); layoutIfNeeded()
    }
    private func finishTouch(_ id: ObjectIdentifier) {
        points.removeValue(forKey: id)
        popups.removeValue(forKey: id)?.removeFromSuperview()
        if deleteOwner == id { deleteOwner = nil; deleteTimer?.invalidate(); deleteTimer = nil }
        if spaceOwner == id { stopSpace() }
    }
    private func key(at point: CGPoint) -> LocalKeyboardKey? {
        // Small gaps belong to the nearest key in the same row, like CInput's coordinate hit testing.
        guard let row = rows.first(where: { $0.first.map { point.y >= $0.frame.minY - 3.5 && point.y <= $0.frame.maxY + 3.5 } ?? false }),
              point.x >= 0, point.x <= bounds.width else { return nil }
        return row.min(by: { abs($0.frame.midX - point.x) < abs($1.frame.midX - point.x) })?.key
    }
    private func apply(_ actions: [LocalKeyboardInteraction<ObjectIdentifier>.Action]) {
        for action in actions {
            switch action {
            case .insert(let text): insertText?(text)
            case .delete: deleteText?()
            case .beginDelete: scheduleDelete(after: 1)
            case .endDelete: deleteTimer?.invalidate(); deleteTimer = nil
            case .wifi: cancelTouches(); openAirType?()
            case .enter: insertText?("\n")
            }
        }
        if let owner = spaceOwner, interaction.contacts[owner]?.committed == true { stopSpace() }
    }
    private func scheduleDelete(after delay: TimeInterval) {
        deleteTimer?.invalidate()
        let timer = Timer(timeInterval: delay, repeats: false) { [weak self] _ in
            guard let self, let owner = self.deleteOwner, self.interaction.contacts[owner] != nil else { return }
            self.deleteText?()
            self.scheduleDelete(after: KeyboardTypingBehavior.deleteInterval(leftDrag: self.deleteOrigin - (self.points[owner]?.x ?? self.deleteOrigin)))
        }
        deleteTimer = timer; RunLoop.main.add(timer, forMode: .common)
    }
    private func beginSpace(_ id: ObjectIdentifier, at x: CGFloat) {
        stopSpace(); spaceOwner = id; spaceLastX = x
        let timer = Timer(timeInterval: 0.4, repeats: false) { [weak self] _ in
            guard let self, self.spaceOwner == id, self.interaction.contacts[id]?.committed == false else { return }
            self.spaceCursorActive = true; self.spaceLastX = self.points[id]?.x ?? x
            self.refreshPopups()
        }
        spaceTimer = timer; RunLoop.main.add(timer, forMode: .common)
    }
    private func stopSpace() { spaceTimer?.invalidate(); spaceTimer = nil; spaceOwner = nil; spaceCursorActive = false; spaceRemainder = 0 }
    func cancelTouches() {
        interaction.cancelAll(); points.removeAll()
        deleteTimer?.invalidate(); deleteTimer = nil; deleteOwner = nil; stopSpace()
        popups.values.forEach { $0.removeFromSuperview() }; popups.removeAll()
        refresh()
    }
    override func didMoveToWindow() { super.didMoveToWindow(); if window == nil { cancelTouches() } }

    private func refreshPopups() {
        var visible: Set<ObjectIdentifier> = []
        for (id, contact) in interaction.contacts where !contact.committed {
            guard case .character(let text) = contact.current,
                  contact.origin != .delete,
                  let button = rows.flatMap({ $0 }).first(where: { $0.key == contact.current }) else { continue }
            visible.insert(id)
            let popup = popups[id] ?? LocalKeyPreview()
            popup.accessibilityIdentifier = "KeyPreview"
            let width = max(54, button.bounds.width + 20)
            let x = min(max(2, button.frame.midX - width / 2), bounds.width - width - 2)
            let y = max(0, button.frame.minY - 58)
            popup.frame = CGRect(x: x, y: y, width: width, height: button.frame.maxY - y)
            popup.update(text: contact.uppercase || contact.origin == .shift ? text.uppercased() : text,
                         color: keyColor, ink: ink,
                         stem: CGRect(x: button.frame.minX - x, y: button.frame.minY - y, width: button.bounds.width, height: button.bounds.height))
            if popup.superview == nil { addSubview(popup) }
            bringSubviewToFront(popup); popups[id] = popup
        }
        for id in Array(popups.keys) where !visible.contains(id) { popups.removeValue(forKey: id)?.removeFromSuperview() }
    }
    private func updateSuggestions() {
        suggestions.arrangedSubviews.forEach { suggestions.removeArrangedSubview($0); $0.removeFromSuperview() }
        let context = contextBeforeInput?() ?? ""
        checkedWord = String(context.reversed().prefix { $0.isLetter && $0.isASCII }.reversed())
        var values: [String] = []
        if spellCheckingEnabled, hasSelection?() != true, !checkedWord.isEmpty, checkedWord.count <= 40 {
            let range = NSRange(checkedWord.startIndex..., in: checkedWord)
            let misspelled = checker.rangeOfMisspelledWord(in: checkedWord, range: range, startingAt: 0, wrap: false, language: "en_US").location != NSNotFound
            let guesses = misspelled ? (checker.guesses(forWordRange: range, in: checkedWord, language: "en_US") ?? []) : []
            let completions = checker.completions(forPartialWordRange: range, in: checkedWord, language: "en_US") ?? []
            for word in [checkedWord] + guesses + completions where !values.contains(word) { values.append(word); if values.count == 3 { break } }
        }
        if values.isEmpty {
            let label = UILabel(); label.text = spellCheckingEnabled ? "Spell check" : ""; label.textAlignment = .center
            label.font = .systemFont(ofSize: 13); label.textColor = .secondaryLabel; suggestions.addArrangedSubview(label)
        } else {
            for word in values {
                let button = UIButton(type: .system); button.setTitle(word, for: .normal); button.tintColor = ink
                button.titleLabel?.font = .systemFont(ofSize: 16); button.titleLabel?.adjustsFontSizeToFitWidth = true
                button.accessibilityLabel = "Spelling suggestion: \(word)"
                let source = checkedWord
                button.addAction(UIAction { [weak self] _ in
                    guard let self, !self.interaction.hasContacts, self.hasSelection?() != true, self.contextBeforeInput?() == context else { return }
                    for _ in source { self.deleteText?() }
                    self.insertText?(word + " "); self.synchronizeCapitalization()
                }, for: .touchUpInside)
                suggestions.addArrangedSubview(button)
            }
        }
    }
    deinit { deleteTimer?.invalidate(); spaceTimer?.invalidate() }
}

private final class LocalKeyButton: UIButton {
    var key: LocalKeyboardKey = .space
    var onActivate: (() -> Void)?
    override func accessibilityActivate() -> Bool { onActivate?(); return true }
}

private final class LocalKeyPreview: UIView {
    private let shape = CAShapeLayer()
    private let label = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false; isAccessibilityElement = false
        layer.addSublayer(shape); addSubview(label)
        label.textAlignment = .center; label.font = .systemFont(ofSize: 34)
        layer.shadowColor = UIColor.black.cgColor; layer.shadowOpacity = 0.18
        layer.shadowRadius = 2; layer.shadowOffset = CGSize(width: 0, height: 1)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func update(text: String, color: UIColor, ink: UIColor, stem: CGRect) {
        let capHeight = stem.minY + 8
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: bounds.width, height: capHeight), cornerRadius: 12)
        path.append(UIBezierPath(roundedRect: CGRect(x: stem.minX, y: max(0, stem.minY - 8), width: stem.width, height: stem.height + 8), cornerRadius: 10))
        shape.path = path.cgPath; shape.fillColor = color.cgColor
        layer.shadowPath = path.cgPath
        label.frame = CGRect(x: 0, y: 0, width: bounds.width, height: max(0, capHeight - 6))
        label.text = text; label.textColor = ink
    }
}
