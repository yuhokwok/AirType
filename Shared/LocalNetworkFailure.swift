import Network
import dnssd

enum LocalNetworkFailure {
    static func isPermissionDenied(_ error: NWError) -> Bool {
        if case .dns(let code) = error { return code == kDNSServiceErr_PolicyDenied }
        return false
    }

    static func message(for error: NWError) -> String {
        if isPermissionDenied(error) { return "Open AirType app → enable Local Network" }
        return "Network unavailable (\(error)). Retry Web Access."
    }
}
