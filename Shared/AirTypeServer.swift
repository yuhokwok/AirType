import Foundation
import Network
import Darwin

/// All state and text callbacks live on the main queue, including NWConnection callbacks.
final class AirTypeServer {
    var onCommand: ((RemoteCommand) -> Void)?
    var onStateChange: (() -> Void)?
    private(set) var address: String?
    private(set) var status = "Disconnected"
    private var listener: NWListener?
    private var connections: [ObjectIdentifier: NWConnection] = [:]
    private var deadlines: [ObjectIdentifier: DispatchWorkItem] = [:]
    private var seen: Set<UUID> = []
    private var order: [UUID] = []
    private var lastContact: Date?
    private var timer: Timer?
    private var pairing = PairingCode()
    var pairingCode: String? { listener == nil ? nil : pairing.value }
    private let token: String
    var connected: Bool { lastContact.map { Date().timeIntervalSince($0) < 5 } ?? false }

    init() {
        let key = "AirTypePairingToken"
        token = UserDefaults.standard.string(forKey: key) ?? UUID().uuidString.replacingOccurrences(of: "-", with: "")
        UserDefaults.standard.set(token, forKey: key)
    }
    func start(useDynamicPort: Bool = false) {
        guard listener == nil else { return }
        pairing = PairingCode()
        let parameters = NWParameters.tcp
        parameters.prohibitedInterfaceTypes = [.cellular]
        do {
            let server: NWListener
            do { server = try NWListener(using: parameters, on: useDynamicPort ? .any : 8307) }
            catch { server = try NWListener(using: parameters, on: .any) }
            listener = server
            status = "Starting…"
            server.service = NWListener.Service(name: "AirType", type: "_airtype._tcp")
            server.stateUpdateHandler = { [weak self, weak server] state in
                guard let self, let server, self.listener === server else { return }
                switch state {
                case .ready:
                    self.updateAddress()
                    self.status = self.address == nil ? "Connect to Wi-Fi" : "Waiting for computer"
                case .waiting: self.status = "Allow Local Network in Settings"
                case .failed(let error):
                    self.stop()
                    if case .posix(.EADDRINUSE) = error, !useDynamicPort {
                        self.start(useDynamicPort: true)
                    } else { self.status = "Connection unavailable. Try again." }
                default: break
                }
                self.onStateChange?()
            }
            server.newConnectionHandler = { [weak self] connection in self?.accept(connection) }
            server.start(queue: .main)
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                guard let self, self.listener?.state == .ready else { return }
                self.updateAddress()
                self.status = self.connected ? "Connected" : (self.address == nil ? "Connect to Wi-Fi" : "Waiting for computer")
                self.onStateChange?()
            }
        } catch { status = "Unable to start Web Access"; onStateChange?() }
    }
    func stop() {
        timer?.invalidate(); timer = nil
        listener?.cancel(); listener = nil
        for connection in connections.values { connection.cancel() }
        for deadline in deadlines.values { deadline.cancel() }
        connections.removeAll(); deadlines.removeAll()
        address = nil; lastContact = nil; status = "Disconnected"
        onStateChange?()
    }
    private func updateAddress() {
        guard let port = listener?.port, let ip = Self.localAddress() else { address = nil; return }
        address = "http://\(ip):\(port.rawValue)/#\(token)"
    }
    static func localAddress() -> String? {
        var list: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&list) == 0 else { return nil }
        defer { freeifaddrs(list) }
        var cursor = list
        while let item = cursor {
            defer { cursor = item.pointee.ifa_next }
            guard let addr = item.pointee.ifa_addr,
                  addr.pointee.sa_family == UInt8(AF_INET),
                  item.pointee.ifa_flags & UInt32(IFF_UP) != 0,
                  String(cString: item.pointee.ifa_name).hasPrefix("en") else { continue }
            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(addr, socklen_t(addr.pointee.sa_len), &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST) == 0 {
                return String(cString: host)
            }
        }
        return nil
    }
    private func accept(_ connection: NWConnection) {
        guard connections.count < 16 else { connection.cancel(); return }
        let id = ObjectIdentifier(connection)
        connections[id] = connection
        let timeout = DispatchWorkItem { [weak self, weak connection] in
            connection?.cancel(); self?.finish(id)
        }
        deadlines[id] = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 8, execute: timeout)
        connection.start(queue: .main)
        receive(connection, data: Data())
    }
    private func finish(_ id: ObjectIdentifier) {
        deadlines.removeValue(forKey: id)?.cancel()
        connections.removeValue(forKey: id)
    }
    private func receive(_ connection: NWConnection, data: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [weak self] chunk, _, complete, error in
            guard let self, self.connections[ObjectIdentifier(connection)] != nil else { return }
            var buffer = data
            if let chunk { buffer.append(chunk) }
            do {
                if let request = try HTTPRequest.parse(buffer) { self.handle(request, on: connection) }
                else if complete || error != nil { connection.cancel(); self.finish(ObjectIdentifier(connection)) }
                else { self.receive(connection, data: buffer) }
            } catch { self.respond(connection, code: "400 Bad Request", body: "Invalid request") }
        }
    }
    private func handle(_ request: HTTPRequest, on connection: NWConnection) {
        if request.method == "GET", request.path == "/" {
            let url = Bundle.main.url(forResource: "Portal", withExtension: "html")
            let html = url.flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? "Portal unavailable"
            respond(connection, body: html, contentType: "text/html; charset=utf-8"); return
        }
        if let origin = request.headers["origin"], origin != "http://" + (request.headers["host"] ?? "") {
            respond(connection, code: "403 Forbidden", body: "Invalid origin"); return
        }
        if request.method == "POST", request.path == "/pair" {
            guard let payload = try? JSONDecoder().decode([String: String].self, from: request.body),
                  let code = payload["code"] else {
                respond(connection, code: "400 Bad Request", body: "Enter the code shown on your keyboard."); return
            }
            switch pairing.verify(code) {
            case .accepted:
                let data = try! JSONEncoder().encode(["token": token])
                respond(connection, body: String(decoding: data, as: UTF8.self), contentType: "application/json")
            case .incorrect:
                respond(connection, code: "403 Forbidden", body: "Incorrect pairing code. Check the code on your keyboard.")
            case .rateLimited:
                respond(connection, code: "429 Too Many Requests", body: "Too many pairing attempts. Wait one minute and try again.")
            }
            return
        }
        guard request.headers["authorization"] == "Bearer \(token)" else {
            respond(connection, code: "403 Forbidden", body: "Pair with the code shown on your AirType keyboard."); return
        }
        if request.method == "GET", request.path == "/status" {
            lastContact = Date(); status = "Connected"; onStateChange?()
            respond(connection, body: "{\"connected\":true}", contentType: "application/json"); return
        }
        guard request.method == "POST", request.path == "/command",
              let command = try? JSONDecoder().decode(RemoteCommand.self, from: request.body), command.isValid,
              let onCommand else { respond(connection, code: "400 Bad Request", body: "Invalid command"); return }
        if !seen.contains(command.id) {
            seen.insert(command.id); order.append(command.id)
            if order.count > 512 { seen.remove(order.removeFirst()) }
            onCommand(command)
        }
        lastContact = Date(); status = "Connected"; onStateChange?()
        respond(connection, body: "{\"ok\":true}", contentType: "application/json")
    }
    private func respond(_ connection: NWConnection, code: String = "200 OK", body: String, contentType: String = "text/plain; charset=utf-8") {
        let payload = Data(body.utf8)
        let headers = "HTTP/1.1 \(code)\r\nContent-Type: \(contentType)\r\nContent-Length: \(payload.count)\r\nConnection: close\r\nCache-Control: no-store\r\nX-Content-Type-Options: nosniff\r\nContent-Security-Policy: default-src 'self'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; connect-src 'self'; frame-ancestors 'none'\r\n\r\n"
        connection.send(content: Data(headers.utf8) + payload, completion: .contentProcessed { [weak self] _ in
            connection.cancel(); self?.finish(ObjectIdentifier(connection))
        })
    }
    deinit { timer?.invalidate(); listener?.cancel(); connections.values.forEach { $0.cancel() } }
}
