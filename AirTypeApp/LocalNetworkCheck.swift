import Combine
import Network
import Foundation

/// A foreground Bonjour round trip, rather than treating NWBrowser.ready as permission approval.
final class LocalNetworkCheck: ObservableObject {
    enum State: Equatable {
        case idle, checking, available, blocked, failed(String)
    }
    @Published private(set) var state: State = .idle
    private var listener: NWListener?
    private var browser: NWBrowser?
    private var timeout: DispatchWorkItem?
    private(set) var hasRequested = false

    func start() {
        stop()
        hasRequested = true
        state = .checking
        let name = "airtype-check-" + UUID().uuidString
        do {
            let listener = try NWListener(using: .tcp, on: .any)
            self.listener = listener
            listener.service = NWListener.Service(name: name, type: "_airtype._tcp")
            listener.newConnectionHandler = { $0.cancel() }
            listener.stateUpdateHandler = { [weak self, weak listener] state in
                guard let self, let listener, self.listener === listener else { return }
                switch state {
                case .waiting(let error): self.report(error)
                case .failed(let error): self.report(error); self.stop()
                default: break
                }
            }
            let browser = NWBrowser(for: .bonjour(type: "_airtype._tcp", domain: "local."), using: .tcp)
            self.browser = browser
            browser.stateUpdateHandler = { [weak self, weak browser] state in
                guard let self, let browser, self.browser === browser else { return }
                switch state {
                case .waiting(let error): self.report(error)
                case .failed(let error): self.report(error); self.stop()
                default: break
                }
            }
            browser.browseResultsChangedHandler = { [weak self, weak browser] results, _ in
                guard let self, let browser, self.browser === browser else { return }
                guard results.contains(where: {
                    if case .service(let found, _, _, _) = $0.endpoint { return found == name }
                    return false
                }) else { return }
                self.state = .available
                self.stop()
            }
            let timeout = DispatchWorkItem { [weak self] in
                guard let self else { return }
                if self.state == .checking {
                    self.state = .failed(L10n.text("No Bonjour response. Check Wi-Fi, allow the permission prompt, then try again."))
                }
                self.stop()
            }
            self.timeout = timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + 30, execute: timeout)
            listener.start(queue: .main)
            browser.start(queue: .main)
        } catch {
            state = .failed(error.localizedDescription)
            stop()
        }
    }

    private func report(_ error: NWError) {
        state = LocalNetworkFailure.isPermissionDenied(error)
            ? .blocked : .failed(error.localizedDescription)
    }

    func stop() {
        timeout?.cancel(); timeout = nil
        listener?.cancel(); listener = nil
        browser?.cancel(); browser = nil
        if state == .checking { state = .idle }
    }

    deinit { timeout?.cancel(); listener?.cancel(); browser?.cancel() }
}
