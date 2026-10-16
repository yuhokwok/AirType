import Foundation

/// Short, keyboard-visible codes authenticate the initial LAN pairing only.
struct PairingCode {
    let value: String
    private var failures: [Date] = []
    enum Result { case accepted, incorrect, rateLimited }

    init(value: String = String(Int.random(in: 100_000...999_999))) {
        self.value = value
    }

    mutating func verify(_ candidate: String, now: Date = Date()) -> Result {
        failures.removeAll { now.timeIntervalSince($0) >= 60 }
        guard failures.count < 5 else { return .rateLimited }
        guard candidate == value else { failures.append(now); return .incorrect }
        failures.removeAll()
        return .accepted
    }
}
