# Validation — 13 October 2026

Environment: Xcode 27.0, iPhone 17 Simulator, iOS 27.0.

## Passed

- App and embedded keyboard extension build, install, and launch without build errors.
- Extension registered in Settings, added as AirType and enabled with Full Access on the test simulator.
- Actual extension renders in a normal `UITextView` using the system keyboard flow; this is separate from the containing-app preview.
- Original icon, grey Web Access panel, connected indicator, address strip, QWERTY key arrangement, cyan Wi-Fi toggle and blue return inspected visually.
- Browser Enter sent `AirType extension: 你好 👋` through the extension's document proxy.
- Remote Delete removed the emoji, preserving the Chinese text.
- Remote newline followed by `Second line` produced a separate second line in the host field.
- A local A key inserted A and released one-shot Shift to lowercase.
- Changing the host field to dark keyboard appearance produced the charcoal keyboard.
- The extension globe key successfully switched to the Apple English keyboard.
- Missing token and invalid token returned HTTP 403. Foreign Origin returned 403.
- Two identical command IDs both received HTTP 200; host text contained `Duplicate test ✓` once.
- Browser connected again after the app/extension was rebuilt and relaunched, without changing the existing pairing address.
- 3 XCTest cases pass: fragmented UTF-8 body handling; ambiguous/oversized request rejection; Unicode and payload validation.

Network response evidence: `Validation/network-checks.json`. Screenshots in `Validation` show the actual extension unless named preview.

## Remaining acceptance

Physical iPhone/iPad signing and installation; real Local Network permission prompts; Wi-Fi between two physical devices/computers; router client isolation; screen lock/background reconnection; physical touch and repeat-delete feel; third-party host applications; iPad and landscape rendered UI; VoiceOver interaction; cross-browser desktop testing. Simulator network traffic uses the host Mac network and does not establish these device-level results.

The supplied references are App Store promotional screenshots, with a small keyboard embedded in each. This is a faithful recreation of their visible layout and documented functionality, not a pixel comparison against full-resolution original UI captures or source code.

## Pairing correction — 16 October 2026

Reported symptom: opening the keyboard's IP/port loads the page, but neither side shows Connected and sending is unavailable. Source inspection found that the address strip hid the `#token`, while `/status` required it. The original portal therefore loaded successfully without being authorized to type.

The keyboard now shows a six-digit pairing code. The IP-only page presents a Connect form that exchanges this code for the existing bearer token; command and status authentication remain required. Incorrect codes show an explicit error, repeated guessing is limited to five failures per minute, and invalid/outdated token URLs return to pairing. Full tokenized URLs and QR codes continue to work.

Validation on Keyboard-Trail-Host-QA / iOS 27 Simulator using the shared keyboard preview and actual Network.framework server:

- Opened only `http://<LAN IP>:8307/`: pairing form visible; Send disabled until authentication.
- Incorrect code rejected, with an actionable error on the page.
- Correct keyboard-visible code accepted: browser and native preview both showed Connected.
- Browser Enter inserted `IP-only pairing works — 你好 👋` into the preview text field.
- An outdated URL token returned to pairing. A draft entered before re-pairing remained intact afterward.
- All 6 XCTest cases passed, including incorrect/correct code checks and rate-limit expiry.
- App and embedded extension build succeeded after the change. A further system-extension UI run was attempted on iPhone 17; Device Hub failed to reopen, so this run does not establish fresh installed-extension UI or physical-device proof.

Evidence: `Validation/pairing-code-connected.jpg` and `Validation/pairing-portal-connected.jpg`. The native screenshot shows the shared keyboard preview. Physical-device acceptance remains open. Install the rebuilt app and refresh the browser page to use the updated protocol/UI.

## Bonjour hostname and setup shortcut — 16 October 2026

- Added actual IPv4 mDNS host registration in addition to the existing `_airtype._tcp` service advertisement. Default browser address: `http://airtype.local:8307/`.
- Added a custom Bonjour name on the app page, shared with the keyboard using App Group `group.com.invivo.AirTypeReplica`. DNS labels are normalized and bounded; a name conflict tries `-2` through `-20`, then retains the IP fallback. The displayed address uses a hostname only after successful registration.
- Added Open Keyboard Settings using `UIApplication.openSettingsURLString`, with the manual setup path shown below it and an alert if opening Settings is rejected. This supported API opens AirType's app settings; it does not promise a private deep link to the global Add New Keyboard screen.
- Build succeeded. All 9 tests passed. Tests include a live DNS-SD conflict between two distinct address records, suffix registration, deregistration, normalized names, and shared App Group persistence.
- `dns-sd -G v4 airtype.local` resolved the hostname to the Mac-hosted Simulator address. Both the hostname and IP portal returned HTTP 200.
- In the browser, opened `http://airtype.local:8307/`, paired with the keyboard-visible code, and sent `Bonjour works — airtype.local 你好 👋` successfully to the shared keyboard preview field. Native screenshot: `Validation/bonjour-connected.jpg`.
- Setup button was checked in the rendered app (`Validation/keyboard-settings-link.jpg`). A Device Hub crash prevented normal native interaction; the browser mirror rendered live frames, but this run does not establish a completed Settings-navigation flow on a physical device.
- Remaining device checks: provision the App Group for both targets, custom-name sharing with the installed extension, actual Wi-Fi mDNS across devices/router configurations, and the Settings shortcut's final destination on the supported iOS versions. The simulator uses the Mac's mDNS environment.

Implementation references: Apple's [Bonjour Concepts](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/NetServices/Articles/about.html), [DNS Service Discovery C](https://developer.apple.com/documentation/dnssd/dns-service-discovery-c), and [app-settings URL](https://developer.apple.com/documentation/uikit/uiapplication/opensettingsurlstring).

## Local-network diagnostics and retry — 16 October 2026

Reported symptom: local-network connection still fails. The exact browser error and physical-device permission state have not yet been supplied, so the device-specific cause remains unconfirmed.

- Replaced the silent permission browser with a foreground check that advertises a unique temporary `_airtype._tcp` service and waits to discover that exact service. Browser `.ready` alone is not reported as success. The check releases its advertisement/browser on completion, navigation away, failure, or timeout.
- Added visible checking, blocked/pending, success, and failure states; app Settings access; automatic rechecking when returning from Settings; explicit guidance separating Local Network permission from keyboard Full Access and explaining that Web Access must stay visible.
- Corrected hostname registration caching: transient DNS-SD errors previously prevented retrying the same name/IP for the rest of the session. Address refresh now retries after five seconds. A permanent conflict at the suffix limit still keeps the IP fallback.
- Keyboard network waits and failures now distinguish DNS policy denial from other errors, rather than labeling every wait as denied permission.
- All 12 tests passed, including actual discovery of the check service, live DNS-SD registration, error classification, and a simulated permission-denial callback followed by successful registration retry. The conflict test now explicitly delivers the conflict callback and verifies real suffix registration: two loopback records on the same Mac mDNS daemon no longer reliably produce a conflict, so that setup is not treated as proof of cross-device collision behavior.
- Simulator build, install, and launch passed without warnings. Physical-device permission prompts, Settings recovery, router reachability, and browser-to-keyboard reconnection remain to be checked on the user's device. Apple's TN3179 states that Simulator does not enforce Local Network privacy.
