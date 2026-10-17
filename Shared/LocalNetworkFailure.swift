import Foundation
import Network
import dnssd

enum LocalNetworkFailure {
    static func isPermissionDenied(_ error: NWError) -> Bool {
        if case .dns(let code) = error { return code == kDNSServiceErr_PolicyDenied }
        return false
    }

    static func message(for error: NWError) -> String {
        if isPermissionDenied(error) { return NSLocalizedString("Open AirType app → enable Local Network", comment: "") }
        return String(format: NSLocalizedString("Network unavailable (%@). Retry Web Access.", comment: ""), String(describing: error))
    }
}
