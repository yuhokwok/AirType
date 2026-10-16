import Foundation
import CryptoKit

/// Shared wire protocol for the native iOS sender and Mac receiver. Not Bluetooth HID.
enum NearbyProtocol {
    static let serviceType = "_airtype-near._tcp"
    static let bleService = "92E3C878-EC81-49AF-83A0-7DD3A089FE21"
    static let bleWrite = "92E3C878-EC81-49AF-83A0-7DD3A089FE22"
    static let bleNotify = "92E3C878-EC81-49AF-83A0-7DD3A089FE23"
    static let maxFrame = 16_384
    static func pairingCode() -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<20).map { _ in alphabet.randomElement()! })
    }
    static func normalizedCode(_ code: String) -> String {
        code.uppercased().filter { !$0.isWhitespace && $0 != "-" }
    }
    static func key(code: String) throws -> SymmetricKey {
        let value = normalizedCode(code)
        guard value.count == 20, value.allSatisfy({ "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".contains($0) }) else {
            throw NearbyError.invalidCode
        }
        return SymmetricKey(data: SHA256.hash(data: Data(("AirType nearby v1:" + value).utf8)))
    }
    static func challengeFrame(_ challenge: String) throws -> Data {
        try frame(NearbyEnvelope(challenge: challenge, sealed: nil))
    }
    static func seal(_ packet: NearbyPacket, key: SymmetricKey) throws -> Data {
        let box = try AES.GCM.seal(JSONEncoder().encode(packet), using: key)
        guard let combined = box.combined else { throw NearbyError.invalidFrame }
        return try frame(NearbyEnvelope(challenge: nil, sealed: combined.base64EncodedString()))
    }
    static func open(_ envelope: NearbyEnvelope, key: SymmetricKey) throws -> NearbyPacket {
        guard envelope.challenge == nil, let raw = envelope.sealed, let data = Data(base64Encoded: raw) else {
            throw NearbyError.invalidFrame
        }
        return try JSONDecoder().decode(NearbyPacket.self, from: AES.GCM.open(AES.GCM.SealedBox(combined: data), using: key))
    }
    private static func frame(_ envelope: NearbyEnvelope) throws -> Data {
        var data = try JSONEncoder().encode(envelope)
        guard data.count < maxFrame else { throw NearbyError.invalidFrame }
        data.append(10)
        return data
    }
}

struct NearbyEnvelope: Codable { let challenge: String?; let sealed: String? }
struct NearbyPacket: Codable {
    enum Kind: String, Codable { case authenticate, command, acknowledgement }
    enum Action: String, Codable, CaseIterable { case insert, delete, newline, tab, escape, left, right, up, down }
    let kind: Kind
    let id: UUID
    let challenge: String
    let sequence: UInt64
    var action: Action? = nil
    var text: String? = nil
    var accepted: Bool? = nil
    var message: String? = nil
    var validCommand: Bool {
        kind == .command && action != nil && (action != .insert || (text?.isEmpty == false && (text?.utf8.count ?? 0) <= 4096))
    }
}

struct NearbyFrameDecoder {
    private var buffer = Data()
    mutating func append(_ data: Data) throws -> [NearbyEnvelope] {
        var result: [NearbyEnvelope] = []
        // Process one bounded frame at a time, including multiple frames in one TCP read.
        for byte in data {
            if byte == 10 {
                guard !buffer.isEmpty else { throw NearbyError.invalidFrame }
                result.append(try JSONDecoder().decode(NearbyEnvelope.self, from: buffer))
                buffer.removeAll(keepingCapacity: true)
            } else {
                guard buffer.count < NearbyProtocol.maxFrame else { throw NearbyError.invalidFrame }
                buffer.append(byte)
            }
        }
        return result
    }
}

enum NearbyError: LocalizedError {
    case invalidCode, invalidFrame, unauthenticated, replay
    var errorDescription: String? {
        switch self {
        case .invalidCode: return "Enter the 20-character pairing key shown on your Mac."
        case .invalidFrame: return "Invalid or oversized nearby message."
        case .unauthenticated: return "Pairing failed. Check the key on your Mac."
        case .replay: return "Stale or repeated connection message rejected."
        }
    }
}

/// Per-connection challenge and strict sequencing stop captured traffic being replayed.
final class NearbyReceiverSession {
    let challenge = UUID().uuidString
    private let key: SymmetricKey
    private var authenticated = false
    private var sequence: UInt64 = 0
    init(code: String) throws { key = try NearbyProtocol.key(code: code) }
    func receive(_ envelope: NearbyEnvelope, execute: (NearbyPacket) -> String?) throws -> Data {
        let packet = try NearbyProtocol.open(envelope, key: key)
        guard packet.challenge == challenge else { throw NearbyError.replay }
        let error: String?
        if !authenticated {
            guard packet.kind == .authenticate, packet.sequence == 0 else { throw NearbyError.unauthenticated }
            authenticated = true; error = nil
        } else {
            guard packet.validCommand else { throw NearbyError.invalidFrame }
            guard packet.sequence == sequence + 1 else { throw NearbyError.replay }
            sequence = packet.sequence
            error = execute(packet)
        }
        return try NearbyProtocol.seal(NearbyPacket(kind: .acknowledgement, id: packet.id,
            challenge: challenge, sequence: packet.sequence, accepted: error == nil, message: error), key: key)
    }
}

/// Receiver-wide IDs survive reconnects during one listening session.
struct NearbyCommandLedger {
    private var ids = Set<UUID>()
    private var order: [UUID] = []
    func contains(_ id: UUID) -> Bool { ids.contains(id) }
    mutating func record(_ id: UUID) {
        guard ids.insert(id).inserted else { return }
        order.append(id)
        if order.count > 512 { ids.remove(order.removeFirst()) }
    }
}

/// Keep UTF-16 surrogate pairs intact when building Quartz keyboard events.
enum NearbyTextChunks {
    static func utf16(_ text: String, limit: Int = 20) -> [[UInt16]] {
        precondition(limit >= 2)
        let units = Array(text.utf16)
        var result: [[UInt16]] = [], start = 0
        while start < units.count {
            var end = min(start + limit, units.count)
            if end < units.count, (0xD800...0xDBFF).contains(units[end - 1]) { end -= 1 }
            result.append(Array(units[start..<end])); start = end
        }
        return result
    }
}
