import Foundation
import dnssd
import Darwin

/// Publishes an actual IPv4 .local host record; a DNS-SD instance name alone is not a URL host.
/// Main-queue ownership ensures DNS-SD callbacks cannot race teardown.
final class BonjourHostname {
    var onChange: (() -> Void)?
    private(set) var hostname: String?
    private var reference: DNSServiceRef?
    private var record: DNSRecordRef?
    private var key: String?
    private var base = "airtype"
    private var ip = ""
    private var attempt = 1
    private var generation = 0

    func publish(name: String, ipv4: String) {
        let desired = "\(name)|\(ipv4)"
        guard key != desired else { return }
        stop()
        key = desired; base = NetworkPreferences.normalizedHostname(name); ip = ipv4; attempt = 1
        register()
    }
    func stop() {
        generation += 1
        releaseReference()
        key = nil; hostname = nil
    }
    private func releaseReference() {
        if let reference { DNSServiceRefDeallocate(reference) }
        reference = nil; record = nil
    }
    private func register() {
        var address = in_addr()
        guard inet_pton(AF_INET, ip, &address) == 1 else { return }
        var ref: DNSServiceRef?
        guard DNSServiceCreateConnection(&ref) == kDNSServiceErr_NoError, let ref else { return }
        reference = ref
        let context = Unmanaged.passUnretained(self).toOpaque()
        let fullname = NetworkPreferences.candidate(base, attempt: attempt) + "."
        let result = DNSServiceRegisterRecord(ref, &record, DNSServiceFlags(kDNSServiceFlagsUnique), 0,
            fullname, UInt16(kDNSServiceType_A), UInt16(kDNSServiceClass_IN),
            UInt16(MemoryLayout<in_addr>.size), &address, 120,
            { ref, _, _, error, context in
                guard let context else { return }
                let owner = Unmanaged<BonjourHostname>.fromOpaque(context).takeUnretainedValue()
                guard owner.reference == ref else { return }
                owner.received(error)
            }, context)
        guard result == kDNSServiceErr_NoError else {
            releaseReference(); onChange?(); return
        }
        if DNSServiceSetDispatchQueue(ref, .main) != kDNSServiceErr_NoError {
            releaseReference(); onChange?()
        }
    }
    private func received(_ error: DNSServiceErrorType) {
        if error == kDNSServiceErr_NoError {
            hostname = NetworkPreferences.candidate(base, attempt: attempt)
            onChange?()
        } else {
            hostname = nil
            let currentGeneration = generation
            // End the callback before replacing its DNS-SD connection.
            DispatchQueue.main.async { [weak self] in
                guard let self, self.generation == currentGeneration else { return }
                self.releaseReference()
                if error == kDNSServiceErr_NameConflict && self.attempt < 20 {
                    self.attempt += 1; self.register()
                }
                self.onChange?()
            }
        }
    }
    deinit { if let reference { DNSServiceRefDeallocate(reference) } }
}
