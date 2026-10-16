import Foundation
import Combine
import Network
import CoreBluetooth
import CryptoKit

enum NearbyTransport: String, CaseIterable, Identifiable {
    case wifi = "Direct Wi-Fi", bluetooth = "Bluetooth LE"
    var id: String { rawValue }
}
struct NearbyPeer: Identifiable {
    let id: String
    let name: String
    var endpoint: NWEndpoint? = nil
    var peripheral: CBPeripheral? = nil
}

/// Delegates and Network callbacks are owned by the main queue.
final class NearbyController: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var transport: NearbyTransport = .wifi
    @Published var pairingKey = ""
    @Published var draft = ""
    @Published private(set) var peers: [NearbyPeer] = []
    @Published private(set) var status = "Open the AirType keyboard on your iPhone or iPad, then find it here."
    @Published private(set) var connected = false
    @Published private(set) var busy = false
    @Published private(set) var searching = false
    private var browser: NWBrowser?
    private var connection: NWConnection?
    private var central: CBCentralManager?
    private var peripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    private var decoder = NearbyFrameDecoder()
    private var key: SymmetricKey?
    private var challenge: String?
    private var sequence: UInt64 = 0
    private var pending: NearbyPacket?
    private var timeout: DispatchWorkItem?
    private var writeChunks: [Data] = []
    private var writeInFlight = false
    private var peerName = "keyboard"

    func discover() {
        disconnect(); peers = []; searching = true
        status = transport == .wifi ? "Looking for nearby keyboards…" : "Looking for AirType Bluetooth keyboards…"
        if transport == .wifi {
            let parameters = NWParameters.tcp
            parameters.includePeerToPeer = true
            parameters.prohibitedInterfaceTypes = [.cellular]
            let browser = NWBrowser(for: .bonjour(type: NearbyProtocol.serviceType, domain: nil), using: parameters)
            self.browser = browser
            browser.stateUpdateHandler = { [weak self, weak browser] state in
                guard let self, let browser, self.browser === browser else { return }
                if case .failed(let error) = state { self.fail(error.localizedDescription) }
                if case .waiting(let error) = state { self.status = LocalNetworkFailure.message(for: error) }
            }
            browser.browseResultsChangedHandler = { [weak self, weak browser] results, _ in
                guard let self, let browser, self.browser === browser else { return }
                self.peers = results.compactMap { result in
                    if case .service(let name, _, _, _) = result.endpoint {
                        return NearbyPeer(id: String(describing: result.endpoint), name: name, endpoint: result.endpoint)
                    }
                    return nil
                }.sorted { $0.name < $1.name }
            }
            browser.start(queue: .main)
        } else {
            if central == nil { central = CBCentralManager(delegate: self, queue: .main) }
            else { beginBLEScan() }
        }
    }
    func connect(_ peer: NearbyPeer) {
        let secret: SymmetricKey
        do { secret = try NearbyProtocol.key(code: pairingKey) }
        catch { status = error.localizedDescription; return }
        disconnect()
        key = secret; peerName = peer.name; busy = true; status = "Connecting to \(peer.name)…"
        armTimeout("Connection timed out. Check the receiver and pairing key, then connect again.")
        if let endpoint = peer.endpoint {
            let parameters = NWParameters.tcp
            parameters.includePeerToPeer = true
            parameters.prohibitedInterfaceTypes = [.cellular]
            let connection = NWConnection(to: endpoint, using: parameters)
            self.connection = connection
            connection.stateUpdateHandler = { [weak self, weak connection] state in
                guard let self, let connection, self.connection === connection else { return }
                switch state {
                case .ready: self.receiveWiFi(connection)
                case .failed(let error): self.fail(error.localizedDescription)
                case .waiting(let error): self.status = "Waiting: \(error.localizedDescription)"
                default: break
                }
            }
            connection.start(queue: .main)
        } else if let peripheral = peer.peripheral {
            self.peripheral = peripheral; peripheral.delegate = self
            central?.connect(peripheral)
        } else { fail("Receiver no longer available. Find receivers again.") }
    }
    func disconnect() {
        browser?.cancel(); browser = nil; central?.stopScan(); searching = false
        let previous = peripheral; peripheral = nil
        if let previous { central?.cancelPeripheralConnection(previous) }
        connection?.cancel(); connection = nil
        timeout?.cancel(); timeout = nil
        key = nil; challenge = nil; pending = nil; sequence = 0
        decoder = NearbyFrameDecoder(); writeChunks = []; writeInFlight = false; writeCharacteristic = nil
        connected = false; busy = false
        status = "Disconnected. Your unsent draft is kept."
    }
    func send(_ action: NearbyPacket.Action) {
        guard connected, !busy, let challenge else { return }
        guard action != .insert || (!draft.isEmpty && draft.utf8.count <= 4096) else {
            status = "Enter up to 4 KB of text per send."; return
        }
        sequence += 1
        let packet = NearbyPacket(kind: .command, id: UUID(), challenge: challenge, sequence: sequence,
            action: action, text: action == .insert ? draft : nil)
        transmit(packet)
    }
    private func transmit(_ packet: NearbyPacket) {
        guard let key else { return }
        do {
            let frame = try NearbyProtocol.seal(packet, key: key)
            pending = packet; busy = true
            armTimeout("Delivery not confirmed. Draft kept; check your keyboard before sending again.")
            if let connection {
                connection.send(content: frame, completion: .contentProcessed { [weak self, weak connection] error in
                    guard let self, let connection, self.connection === connection else { return }
                    if let error { self.fail(error.localizedDescription) }
                })
            } else if let peripheral, writeCharacteristic != nil {
                let size = max(1, peripheral.maximumWriteValueLength(for: .withResponse))
                writeChunks = stride(from: 0, to: frame.count, by: size).map { Data(frame[$0..<min($0 + size, frame.count)]) }
                flushBLEWrite()
            } else { fail("Receiver disconnected. Your draft is kept.") }
        } catch { fail(error.localizedDescription) }
    }
    private func receiveWiFi(_ connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { [weak self, weak connection] data, _, complete, error in
            guard let self, let connection, self.connection === connection else { return }
            if let data { self.received(data) }
            guard self.connection === connection else { return }
            if complete || error != nil { self.fail("Keyboard disconnected. Your draft is kept.") }
            else { self.receiveWiFi(connection) }
        }
    }
    private func received(_ data: Data) {
        do {
            for envelope in try decoder.append(data) {
                if let value = envelope.challenge {
                    guard challenge == nil, value.count <= 64, envelope.sealed == nil else { throw NearbyError.invalidFrame }
                    challenge = value
                    transmit(NearbyPacket(kind: .authenticate, id: UUID(), challenge: value, sequence: 0))
                } else {
                    guard let key, let pending else { throw NearbyError.invalidFrame }
                    let ack = try NearbyProtocol.open(envelope, key: key)
                    guard ack.kind == .acknowledgement, ack.id == pending.id,
                          ack.challenge == challenge, ack.sequence == pending.sequence else { throw NearbyError.replay }
                    timeout?.cancel(); timeout = nil; self.pending = nil; busy = false
                    guard ack.accepted == true else { status = ack.message ?? "Keyboard rejected the command."; return }
                    connected = true
                    if pending.action == .insert && draft == pending.text { draft = "" }
                    status = pending.kind == .authenticate ? "Connected to \(peerName)" : "Keyboard acknowledged the command."
                }
            }
        } catch { fail("Pairing or message validation failed. Check the keyboard's key.") }
    }
    private func armTimeout(_ message: String) {
        timeout?.cancel()
        let item = DispatchWorkItem { [weak self] in self?.fail(message) }
        timeout = item; DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: item)
    }
    private func fail(_ message: String) { disconnect(); status = message }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard transport == .bluetooth else { return }
        if central.state == .poweredOn { if searching { beginBLEScan() } }
        else {
            let message: String
            switch central.state {
            case .unsupported: message = "Bluetooth LE requires a supported physical device; Simulator does not provide this transport."
            case .unauthorized: message = "Allow Bluetooth for AirType in Settings."
            case .poweredOff: message = "Turn on Bluetooth to find receivers."
            default: message = "Bluetooth is not ready. Try finding receivers again."
            }
            fail(message)
        }
    }
    private func beginBLEScan() {
        guard central?.state == .poweredOn else { return }
        central?.scanForPeripherals(withServices: [CBUUID(string: NearbyProtocol.bleService)])
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard searching, transport == .bluetooth, !peers.contains(where: { $0.id == peripheral.identifier.uuidString }) else { return }
        let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? peripheral.name ?? "AirType keyboard"
        peers.append(NearbyPeer(id: peripheral.identifier.uuidString, name: name, peripheral: peripheral))
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard self.peripheral === peripheral else { return }
        peripheral.discoverServices([CBUUID(string: NearbyProtocol.bleService)])
    }
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        guard self.peripheral === peripheral else { return }; fail(error?.localizedDescription ?? "Bluetooth connection failed.")
    }
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        guard self.peripheral === peripheral else { return }; fail("Bluetooth disconnected. Your draft is kept.")
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard self.peripheral === peripheral else { return }
        guard error == nil, let service = peripheral.services?.first(where: { $0.uuid == CBUUID(string: NearbyProtocol.bleService) }) else { fail("AirType Bluetooth service unavailable."); return }
        peripheral.discoverCharacteristics([CBUUID(string: NearbyProtocol.bleWrite), CBUUID(string: NearbyProtocol.bleNotify)], for: service)
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard self.peripheral === peripheral else { return }
        guard error == nil,
              let writer = service.characteristics?.first(where: { $0.uuid == CBUUID(string: NearbyProtocol.bleWrite) }),
              let notifier = service.characteristics?.first(where: { $0.uuid == CBUUID(string: NearbyProtocol.bleNotify) }) else { fail("Bluetooth characteristics unavailable."); return }
        writeCharacteristic = writer; peripheral.setNotifyValue(true, for: notifier)
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        guard self.peripheral === peripheral else { return }
        if error != nil || !characteristic.isNotifying { fail("Unable to subscribe to the Bluetooth receiver.") }
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard self.peripheral === peripheral else { return }
        if let error { fail(error.localizedDescription) }
        else if characteristic.uuid == CBUUID(string: NearbyProtocol.bleNotify), let value = characteristic.value { received(value) }
    }
    private func flushBLEWrite() {
        guard !writeInFlight, !writeChunks.isEmpty, let peripheral, let writeCharacteristic else { return }
        writeInFlight = true; peripheral.writeValue(writeChunks.removeFirst(), for: writeCharacteristic, type: .withResponse)
    }
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard self.peripheral === peripheral else { return }
        writeInFlight = false
        if let error { fail(error.localizedDescription) } else { flushBLEWrite() }
    }
    deinit { browser?.cancel(); connection?.cancel(); central?.stopScan(); timeout?.cancel() }
}
