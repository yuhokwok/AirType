# Native nearby typing developer build

Direction: **Mac → visible iPhone/iPad keyboard extension → focused app text field**. The containing app saves connection preferences and prepares permissions. It is not a background relay.

- [x] Shared bounded AES-GCM command framing, fresh challenge, sequence checks and acknowledgements.
- [x] Keyboard-owned peer-to-peer-enabled Bonjour/TCP receiver.
- [x] Keyboard-owned Bluetooth LE peripheral with MTU segmentation and notification backpressure.
- [x] Mac sender discovery, pairing, composer and editing controls in AirTypeDesktop.
- [x] Route accepted commands through the extension's textDocumentProxy.
- [x] Web / Direct Wi-Fi / Bluetooth selector on the keyboard; retain browser workflow.
- [x] Stop receiving when keyboard disappears or changes to local QWERTY.
- [x] Build both platforms and run protocol/input routing tests.
- [ ] Physical-device acceptance for installed-extension Bluetooth, permissions, no-router Wi-Fi and editing across supported apps.

## Validation — 16 October 2026

- AirType iOS app and embedded keyboard extension build; native Wi-Fi preview installs and launches on iOS 27 Simulator.
- AirTypeDesktop macOS 14+ target builds. Mac Accessibility injection was removed; the Mac is the sender.
- All 24 XCTest cases pass: existing regressions, native protocol validation and UITextView command routing, including Chinese, composed emoji, delete, newline/tab and unsupported key rejection.
- The headless native integration test passes real Bonjour/TCP discovery, encrypted pairing, Unicode delivery, acknowledgement and confirmed-draft clearing using the actual shared transport controllers.
- With `--native-keyboard-wifi`, the Mac sender also discovers the iOS Simulator's keyboard preview and sends `Mac → AirType keyboard — 你好 👋`. [A screenshot](Validation/native-keyboard-preview.jpg) confirms the received text in its UITextView. This is shared-view preview evidence, not a fresh installed-extension interaction test.
- The Mac window could not be interacted with because native computer-use repeatedly returned a closed connection. Its build and headless sender behavior are verified separately.
- Simulator networking does not prove peer-to-peer radio use or enforce physical-device Local Network permission. CoreBluetooth compiling in the extension does not establish working physical Bluetooth advertising, subscription or permission behavior.

## Device acceptance

1. Install with provisioned App Groups; enable AirType and Full Access.
2. Prepare Local Network and Bluetooth permissions in the containing app.
3. In Notes or another supported app, open AirType and select Direct Wi-Fi; pair from AirType Desktop and check Unicode, Delete, Return, Tab and cursor movement.
4. Repeat without a shared router and record whether discovery/delivery works.
5. Select Bluetooth, disable Wi-Fi and check discovery, pairing, long Unicode payloads and repeated editing.
6. Switch apps, hide/reopen the keyboard, change transport and interrupt connectivity. Confirm sessions stop, drafts survive uncertain sends and reconnect does not duplicate input.

Bluetooth is a custom GATT transport, not standard Bluetooth HID. Unsupported Up, Down and Escape commands are rejected. The containing app does not keep a receiver alive after it backgrounds.
