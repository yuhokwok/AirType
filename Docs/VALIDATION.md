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
