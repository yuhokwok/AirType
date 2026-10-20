import Foundation

enum L10n {
    static func text(_ key: String) -> String { NSLocalizedString(key, comment: "") }
    static func format(_ key: String, _ value: String) -> String {
        String(format: text(key), value)
    }
    static var language: String { language(for: Bundle.main.preferredLocalizations) }
    static func language(for preferences: [String]) -> String {
        Bundle.preferredLocalizations(from: ["en", "zh-Hant", "zh-Hans"], forPreferences: preferences).first ?? "en"
    }
    /// Browser language never participates: the serving app/extension chooses the UI language.
    static func portalHTML(_ source: String, language: String = language, legacyToken: String? = nil) -> String {
        let selected = self.language(for: [language])
        let url = Bundle.main.url(forResource: "PortalLocales", withExtension: "json")
        let locales = url.flatMap { try? Data(contentsOf: $0) }
            .flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: [String: String]] }
        let translations = locales?[selected] ?? [:]
        let data = (try? JSONSerialization.data(withJSONObject: translations, options: [.sortedKeys])) ?? Data("{}".utf8)
        // Prevent localized content from ending the inline script element.
        let json = String(decoding: data, as: UTF8.self).replacingOccurrences(of: "<", with: "\\u003c")
            .replacingOccurrences(of: "\u{2028}", with: "\\u2028").replacingOccurrences(of: "\u{2029}", with: "\\u2029")
        let bootstrapData = (try? JSONEncoder().encode(legacyToken ?? "")) ?? Data("\"\"".utf8)
        let bootstrap = String(decoding: bootstrapData, as: UTF8.self).replacingOccurrences(of: "<", with: "\\u003c")
        return source.replacingOccurrences(of: "<html lang=\"en\">", with: "<html lang=\"\(selected)\">")
            .replacingOccurrences(of: "/*AIRTYPE_I18N*/{}", with: json)
            .replacingOccurrences(of: "/*AIRTYPE_LEGACY_TOKEN*/\"\"", with: bootstrap)
    }
}
