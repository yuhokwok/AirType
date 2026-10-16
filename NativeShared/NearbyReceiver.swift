import Foundation
import Combine
import Network
import CoreBluetooth

final class NearbyReceiver: NSObject, ObservableObject, CBPeripheralManagerDelegate {
    @Published private(set) var pairingKey = NearbyProtocol.pairingCode() { didSet { onStateChange?() } }
    @Published private(set) var wifiStatus = "Stopped" { didSet { onStateChange?() } }
    @Published private(set) var bluetoothStatus = "Stopped" { didSet { onStateChange?() } }
    @Published private(set) var wifiRunning = false { didSet { onStateChange?() } }
    @Published private(set) var bluetoothRunning = false { didSet { onStateChange?() } }
    @Published private(set) var connections = 0 { didSet { onStateChange?() } }
    var onCommand: ((NearbyPacket) -> String?)?
    var onStateChange: (() -> Void)?
    private var listener: NWListener?
    private var wifiChannels: [ObjectIdentifier: WiFiChannel] = [:]
    private var manager: CBPeripheralManager?
    private var notifyCharacteristic: CBMutableCharacteristic?
    private var bleChannels: [UUID: BLEChannel] = [:]
    private var ledger = NearbyCommandLedger()
    private var wantsBluetooth = false
    private let label: String

    init(displayName: String? = nil) {
        label = displayName ?? "AirType keyboard"
        super.init()
    }

    final class WiFiChannel {
        let connection: NWConnection
        let session: NearbyReceiverSession
        var decoder = NearbyFrameDecoder()
        var deadline: DispatchWorkItem?
        init(connection: NWConnection, session: NearbyReceiverSession) { self.connection = connection; self.session = session }
    }
    final class BLEChannel {
        let central: CBCentral
        let session: NearbyReceiverSession
        var decoder = NearbyFrameDecoder()
        var outgoing = Data()
        var deadline: DispatchWorkItem?
        init(central: CBCentral, session: NearbyReceiverSession) { self.central = central; self.session = session }
    }
    func startWiFi() {
        stopWiFi()
        do {
            let parameters = NWParameters.tcp
            parameters.includePeerToPeer = true
            let listener = try NWListener(using: parameters, on: .any)
            self.listener = listener
            wifiRunning = true
            listener.service = NWListener.Service(name: label, type: NearbyProtocol.serviceType)
            listener.stateUpdateHandler = { [weak self, weak listener] state in
                guard let self, let listener, self.listener === listener else { return }
                switch state {
                case .ready: self.wifiRunning = true; self.wifiStatus = "Listening · \(self.label)"
                case .waiting(let error): self.wifiStatus = "Waiting: \(error)"
                case .failed(let error): self.stopWiFi(); self.wifiStatus = error.localizedDescription
                default: break
                }
            }
            listener.newConnectionHandler = { [weak self] in self?.acceptWiFi($0) }
            wifiStatus = "Starting…"; listener.start(queue: .main)
        } catch { wifiStatus = error.localizedDescription }
    }
    func stopWiFi() {
        listener?.cancel(); listener = nil
        for channel in wifiChannels.values { channel.deadline?.cancel(); channel.connection.cancel() }
        wifiChannels.removeAll(); wifiRunning = false; wifiStatus = "Stopped"; updateCount()
    }
    private func acceptWiFi(_ connection: NWConnection) {
        guard wifiChannels.count < 4, let session = try? NearbyReceiverSession(code: pairingKey) else { connection.cancel(); return }
        let channel = WiFiChannel(connection: connection, session: session)
        let id = ObjectIdentifier(connection); wifiChannels[id] = channel; updateCount()
        let deadline = DispatchWorkItem { [weak self] in self?.closeWiFi(id) }
        channel.deadline = deadline; DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: deadline)
        connection.stateUpdateHandler = { [weak self, weak channel] state in
            guard let self, let channel, self.wifiChannels[id] === channel else { return }
            if case .ready = state {
                do { self.sendWiFi(try NearbyProtocol.challengeFrame(session.challenge), channel: channel); self.receiveWiFi(channel) }
                catch { self.closeWiFi(id) }
            }
            if case .failed = state { self.closeWiFi(id) }
            if case .cancelled = state { self.closeWiFi(id) }
        }
        connection.start(queue: .main)
    }
    private func receiveWiFi(_ channel: WiFiChannel) {
        let id = ObjectIdentifier(channel.connection)
        channel.connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { [weak self, weak channel] data, _, complete, error in
            guard let self, let channel, self.wifiChannels[id] === channel else { return }
            do {
                if let data {
                    for frame in try channel.decoder.append(data) {
                        let reply = try channel.session.receive(frame) { self.execute($0) }
                    self.updateCount()
                        channel.deadline?.cancel(); channel.deadline = nil
                        self.sendWiFi(reply, channel: channel)
                    }
                }
                if complete || error != nil { self.closeWiFi(id) } else { self.receiveWiFi(channel) }
            } catch { self.closeWiFi(id) }
        }
    }
    private func sendWiFi(_ data: Data, channel: WiFiChannel) {
        channel.connection.send(content: data, completion: .contentProcessed { [weak self, weak channel] error in
            if error != nil, let channel { self?.closeWiFi(ObjectIdentifier(channel.connection)) }
        })
    }
    private func closeWiFi(_ id: ObjectIdentifier) {
        guard let channel = wifiChannels.removeValue(forKey: id) else { return }
        channel.deadline?.cancel(); channel.connection.cancel(); updateCount()
    }
    func startBluetooth() {
        stopBluetooth(); wantsBluetooth = true; bluetoothRunning = true; bluetoothStatus = "Starting Bluetooth…"
        if manager == nil { manager = CBPeripheralManager(delegate: self, queue: .main) }
        else if manager?.state == .poweredOn { publishBLEService() }
        else { updateBluetoothState() }
    }
    func stopBluetooth() {
        wantsBluetooth = false; manager?.stopAdvertising(); manager?.removeAllServices()
        notifyCharacteristic = nil
        for channel in bleChannels.values { channel.deadline?.cancel() }
        bleChannels.removeAll(); bluetoothRunning = false; bluetoothStatus = "Stopped"; updateCount()
    }
    func rotateKey() {
        stopWiFi(); stopBluetooth(); pairingKey = NearbyProtocol.pairingCode(); ledger = NearbyCommandLedger()
    }
    private func execute(_ packet: NearbyPacket) -> String? {
        if ledger.contains(packet.id) { return nil }
        guard let onCommand else { return "AirType keyboard is not ready to receive text." }
        let error = onCommand(packet)
        if error == nil { ledger.record(packet.id) }
        return error
    }
    private func updateCount() {
        connections = wifiChannels.values.filter { $0.session.authenticated }.count + bleChannels.values.filter { $0.session.authenticated }.count
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) { updateBluetoothState() }
    private func updateBluetoothState() {
        guard wantsBluetooth, let manager else { return }
        if manager.state == .poweredOn { publishBLEService(); return }
        switch manager.state {
        case .poweredOff: bluetoothStatus = "Turn on Bluetooth on this device."
        case .unauthorized: bluetoothStatus = "Allow Bluetooth for AirType in Settings."
        case .unsupported: bluetoothStatus = "Bluetooth peripheral mode is unavailable on this device."
        default: bluetoothStatus = "Bluetooth is not ready."
        }
        for channel in bleChannels.values { channel.deadline?.cancel() }
        bleChannels.removeAll(); updateCount()
    }
    private func publishBLEService() {
        guard wantsBluetooth, let manager, notifyCharacteristic == nil else { return }
        let notify = CBMutableCharacteristic(type: CBUUID(string: NearbyProtocol.bleNotify), properties: [.notify], value: nil, permissions: [.readable])
        let writer = CBMutableCharacteristic(type: CBUUID(string: NearbyProtocol.bleWrite), properties: [.write], value: nil, permissions: [.writeable])
        let service = CBMutableService(type: CBUUID(string: NearbyProtocol.bleService), primary: true)
        service.characteristics = [writer, notify]; notifyCharacteristic = notify; manager.add(service)
    }
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        guard wantsBluetooth, service.characteristics?.contains(where: { $0 === notifyCharacteristic }) == true else { return }
        if let error { stopBluetooth(); bluetoothStatus = error.localizedDescription; return }
        peripheral.startAdvertising([CBAdvertisementDataLocalNameKey: label,
            CBAdvertisementDataServiceUUIDsKey: [CBUUID(string: NearbyProtocol.bleService)]])
    }
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        guard wantsBluetooth else { return }
        if let error { stopBluetooth(); bluetoothStatus = error.localizedDescription }
        else { bluetoothRunning = true; bluetoothStatus = "Advertising · \(label)" }
    }
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        guard wantsBluetooth, characteristic.uuid == CBUUID(string: NearbyProtocol.bleNotify), bleChannels.count < 4,
              let session = try? NearbyReceiverSession(code: pairingKey) else { return }
        let channel = BLEChannel(central: central, session: session)
        bleChannels[central.identifier]?.deadline?.cancel()
        bleChannels[central.identifier] = channel; updateCount()
        let deadline = DispatchWorkItem { [weak self, weak channel] in
            guard let self, let channel, self.bleChannels[central.identifier] === channel else { return }
            self.bleChannels.removeValue(forKey: central.identifier); self.updateCount()
        }
        channel.deadline = deadline
        DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: deadline)
        if let data = try? NearbyProtocol.challengeFrame(session.challenge) { channel.outgoing.append(data); flushBLENotifications() }
    }
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        bleChannels.removeValue(forKey: central.identifier)?.deadline?.cancel(); updateCount()
    }
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            guard request.characteristic.uuid == CBUUID(string: NearbyProtocol.bleWrite), request.offset == 0,
                  let value = request.value, let channel = bleChannels[request.central.identifier] else {
                peripheral.respond(to: request, withResult: .writeNotPermitted); continue
            }
            do {
                for frame in try channel.decoder.append(value) {
                    let reply = try channel.session.receive(frame) { self.execute($0) }
                    self.updateCount()
                    channel.deadline?.cancel(); channel.deadline = nil
                    guard channel.outgoing.count + reply.count <= NearbyProtocol.maxFrame * 2 else { throw NearbyError.invalidFrame }
                    channel.outgoing.append(reply)
                }
                peripheral.respond(to: request, withResult: .success); flushBLENotifications()
            } catch {
                bleChannels.removeValue(forKey: request.central.identifier)?.deadline?.cancel(); updateCount()
                peripheral.respond(to: request, withResult: .unlikelyError)
            }
        }
    }
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) { flushBLENotifications() }
    private func flushBLENotifications() {
        guard let manager, let notifyCharacteristic else { return }
        for channel in bleChannels.values {
            while !channel.outgoing.isEmpty {
                let count = min(channel.central.maximumUpdateValueLength, channel.outgoing.count)
                guard count > 0 else { break }
                let data = Data(channel.outgoing.prefix(count))
                guard manager.updateValue(data, for: notifyCharacteristic, onSubscribedCentrals: [channel.central]) else { return }
                channel.outgoing.removeFirst(count)
            }
        }
    }
    deinit {
        listener?.cancel()
        for channel in wifiChannels.values { channel.deadline?.cancel(); channel.connection.cancel() }
        for channel in bleChannels.values { channel.deadline?.cancel() }
        manager?.stopAdvertising()
    }
}
