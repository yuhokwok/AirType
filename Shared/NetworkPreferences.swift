import Foundation

/// Temporarily keep the shipping app and keyboard on browser-based AirType.
enum AirTypeFeatures {
    static let nearbyTypingEnabled = false
    static func availableInputMode(_ requested: RemoteInputMode) -> RemoteInputMode {
        nearbyTypingEnabled ? requested : .web
    }
}

/// Shared by the containing app and keyboard extension through their App Group.
enum RemoteInputMode: String, CaseIterable, Identifiable {
    case web = "Web", wifi = "Direct Wi-Fi", bluetooth = "Bluetooth"
    var id: String { rawValue }
}

enum NetworkPreferences {
    static let appGroup = "group.com.invivo.AirTypeReplica"
    static var inputMode: RemoteInputMode {
        get { AirTypeFeatures.availableInputMode(RemoteInputMode(rawValue: UserDefaults(suiteName: appGroup)?.string(forKey: "AirTypeInputMode") ?? "") ?? .web) }
        set { UserDefaults(suiteName: appGroup)?.set(newValue.rawValue, forKey: "AirTypeInputMode") }
    }
    static let nameKey = "AirTypeBonjourHostname"
    static var hostname: String {
        normalizedHostname(UserDefaults(suiteName: appGroup)?.string(forKey: nameKey) ?? "airtype")
    }
    static func saveHostname(_ name: String) {
        UserDefaults(suiteName: appGroup)?.set(normalizedHostname(name), forKey: nameKey)
    }
    static func normalizedHostname(_ input: String) -> String {
        var value = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if value.hasSuffix(".local") { value.removeLast(6) }
        let allowed = Set("abcdefghijklmnopqrstuvwxyz0123456789")
        let parts = value.split(whereSeparator: { !allowed.contains($0) }).map(String.init)
        let name = String(parts.joined(separator: "-").prefix(50)).trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return name.isEmpty ? "airtype" : name
    }
    static func candidate(_ base: String, attempt: Int) -> String {
        let name = normalizedHostname(base)
        return (attempt == 1 ? name : "\(name)-\(attempt)") + ".local"
    }
}
