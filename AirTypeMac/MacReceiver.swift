import Foundation
import Combine
import Network
import CoreBluetooth
import AppKit
import ApplicationServices

final class MacReceiver: NSObject, ObservableObject, CBPeripheralManagerDelegate {
    @Published private(set) var pairingKey = NearbyProtocol.pairingCode()
    @Published private(set) var wifiStatus = "Stopped"
    @Published private(set) var bluetoothStatus = "Stopped"
    @Published private(set) var wifiRunning = false
    @Published private(set) var bluetoothRunning = false
    @Published private(set) var receivedText = ""
    @Published private(set) var lastAction = "No commands received yet."
    @Published private(set) var connections = 0
    @Published var typeIntoApps = false
    private var listener: NWListener?
    private var wifiChannels: [ObjectIdentifier: WiFiChannel] = [:]
    private var manager: CBPeripheralManager?
    private var notifyCharacteristic: CBMutableCharacteristic?
    private var bleChannels: [UUID: BLEChannel] = [:]
    private var ledger = NearbyCommandLedger()
    private var wantsBluetooth = false
    private let label: String

    init(displayName: String? = nil) {
        label = displayName ?? Host.current().localizedName ?? "AirType Mac"
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
    func clearPreview() { receivedText = "" }
    func requestAccessibility() {
        _ = AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary)
    }
    private func execute(_ packet: NearbyPacket) -> String? {
        if ledger.contains(packet.id) { return nil }
        guard let action = packet.action else { return "Missing key command." }
        if typeIntoApps {
            guard AXIsProcessTrusted() else { return "Enable Accessibility for AirType Receiver on your Mac, or use preview mode." }
            guard NSWorkspace.shared.frontmostApplication?.bundleIdentifier != Bundle.main.bundleIdentifier else {
                return "Focus the destination app on your Mac before sending."
            }
            guard MacInputInjector.post(packet) else { return "Unable to create the keyboard event." }
        } else {
            switch action {
            case .insert: receivedText += packet.text ?? ""
            case .delete: if !receivedText.isEmpty { receivedText.removeLast() }
            case .newline: receivedText += "\n"
            case .tab: receivedText += "\t"
            default: break
            }
            // Preview is an inspection surface, not a permanent typing log.
            if receivedText.count > 16_384 { receivedText = String(receivedText.suffix(16_384)) }
        }
        ledger.record(packet.id)
        lastAction = "\(typeIntoApps ? "Posted to focused app" : "Received in preview"): \(action.rawValue)"
        return nil
    }
    private func updateCount() { connections = wifiChannels.count + bleChannels.count }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) { updateBluetoothState() }
    private func updateBluetoothState() {
        guard wantsBluetooth, let manager else { return }
        if manager.state == .poweredOn { publishBLEService(); return }
        switch manager.state {
        case .poweredOff: bluetoothStatus = "Turn on Bluetooth on this Mac."
        case .unauthorized: bluetoothStatus = "Allow Bluetooth for AirType Receiver in System Settings."
        case .unsupported: bluetoothStatus = "Bluetooth peripheral mode is unavailable on this Mac."
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
        peripheral.startAdvertising([CBAdvertisementDataLocalNameKey: "AirType " + label,
            CBAdvertisementDataServiceUUIDsKey: [CBUUID(string: NearbyProtocol.bleService)]])
    }
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        guard wantsBluetooth else { return }
        if let error { stopBluetooth(); bluetoothStatus = error.localizedDescription }
        else { bluetoothRunning = true; bluetoothStatus = "Advertising · AirType \(label)" }
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
