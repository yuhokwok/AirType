# Native nearby typing developer build

First version: iPhone/iPad host app sends text and key commands to a native Mac receiver. The existing browser-to-iPhone extension remains separate.

- [x] Shared bounded, authenticated-encrypted command framing; challenge, sequence and acknowledgement checks.
- [x] iOS peer-to-peer-enabled Bonjour discovery and TCP connection.
- [x] iOS Bluetooth LE central with serialized, MTU-sized writes and response handling.
- [x] Mac receiver with Wi-Fi and BLE service publication, pairing, acknowledgements and bounded sessions.
- [x] Mac preview receiving plus explicit Accessibility-based typing into other apps.
- [x] Host-app transport selection, pairing and composer; keep legacy keyboard setup accessible.
- [x] Build both targets and run protocol/security regression tests.
- [ ] Physical-device verification: no-router Wi-Fi, Bluetooth-only delivery, long Unicode payloads, reconnection and focused-app typing.

The Bluetooth implementation is custom GATT with a Mac receiver, not a standard Bluetooth HID keyboard. Peer-to-peer Wi-Fi is Apple's technology; macOS can also choose infrastructure Wi-Fi if available. The developer build must not claim which radio path was used without physical-device evidence.

## Validation — 16 October 2026

- iOS app + embedded keyboard compile, install and launch on the iOS 27 Simulator with `com.invivo.ios.AirType`. The Type to Mac screen was inspected in a simulator screenshot.
- The `AirTypeReceiver` macOS 14+ target builds. Xcode reports only the informational App Intents metadata-extraction warning for a target that does not use App Intents.
- 22 XCTest cases pass: 10 native-protocol cases plus 12 existing regression cases. Coverage includes wrong keys, pre-auth commands, cross-session replay, repeated sequence numbers, ciphertext tampering, bounded fragmented/coalesced frames, receiver rejection, Unicode, and 20-byte BLE-style framing.
- `scripts/check-nearby-macos.sh` compiles the actual sender controller and receiver model into a temporary headless test. Real Bonjour discovery and TCP exchange pass: encrypted authentication, Unicode delivery to preview, acknowledgement and clearing the confirmed draft. The test uses a unique service name and never enables event injection.
- This local test does not establish that Apple peer-to-peer radio was used; infrastructure networking can be selected automatically. It is not an iPhone/Mac hardware test.
- Native Mac UI automation failed twice with a closed computer-use connection, including after runtime reset. Mac window interaction and permission prompts remain unverified. The receiver's headless model and native app compilation are verified separately.
- Physical-device acceptance remains open: BLE peripheral advertising, iPhone central discovery/subscription, MTU/backpressure, permission prompts, no-router Wi-Fi, reconnect and actual focused-app Unicode/key delivery after the user grants Accessibility.

The uncommitted user changes to `AirType.icon` and `output/` were not modified by this work.
