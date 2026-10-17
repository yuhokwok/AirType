# AirType implementation checklist

- [x] Locate invivo's original listing and inspect all four screenshots.
- [x] Save reference assets and record inferred design contract.
- [x] Create containing iOS app, embedded keyboard extension, and shared resources.
- [x] Reproduce grey Web Access panel, circular original icon, status, keyboard/address/delete controls and conditional globe.
- [x] Reproduce four-row QWERTY, shift/caps, symbol pages, space, Wi-Fi toggle, blue return key, light/dark appearance.
- [x] Implement keyboard document-proxy insertion, deletion, newline, system globe menu, repeat Delete.
- [x] Implement local browser portal, Enter/Send, Unicode, reconnect polling and retained drafts.
- [x] Implement bounded HTTP parsing, pairing-token authentication, origin checks, duplicate-command protection and server cleanup.
- [x] Build and run app plus embedded extension on iPhone Simulator.
- [x] Test parser/command validation and actual extension browser-to-field behaviour.
- [ ] Physical-device acceptance: signing, Wi-Fi permissions, second-computer connection, host apps, iPad and landscape touch layouts.
- [x] Add visible foreground Bonjour check, permission recovery guidance, specific network errors, and hostname retries after permission changes.

## Design contract

Connection mode (updated 17 October 2026): grey keyboard background, the transport selector temporarily hidden, and equal-width status/icon and pairing-code halves. Bottom-left returns to the local keyboard; bottom-right deletes. Both are 44-point circular buttons using native Liquid Glass on iOS 26+ and solid circle fallbacks on iOS 17–25. The address/details control stays between them. The original AirType branding remains visible.

Local mode: QWERTY / ASDF / shift-ZXCV-delete rows, followed by 123/ABC, optional globe, Wi-Fi, wide space, period and blue return. Both local and remote modes follow needsInputModeSwitchKey; the local globe sits between 123/ABC and Wi-Fi when required. Capitalization follows the current text field, Shift supports one-shot capitals and caps lock, and delete uses CInput's one-second delay, 100 ms cadence and left-drag acceleration down to 35 ms. Dark keys retain solid charcoal styling.

The setup app and connection-token/QR detail screen are new supporting UI. The reference screenshots do not show the original containing app. iOS 17 is the new minimum; the historical listing's iOS 8 compatibility is not replicated.

## CInput touch behavior — 17 October 2026

- [x] Match CInput phone/wide-iPad key radii: 10/14 points.
- [x] Shift touch-down activates uppercase; slide-release types a capital; another finger can type while Shift remains held.
- [x] 123/ABC and #+= reveal a temporary page on touch-down, drag-release inserts then returns to the exact source, and tap keeps the destination.
- [x] Track each contact independently; newer letter/space presses flush older pending input in press order without duplicate releases.
- [x] Keep layout updates on the same touch surface; correct keys by sliding and reject accidental Return/Wi-Fi activation from letter drags.
- [x] Render enlarged character previews with rounded cap/stem and edge clamping.
- [x] Keep space and add a period at the former right-side mode-button position; move Wi-Fi beside 123/ABC.
- [x] Add a 34-point local English spelling/completion row and space-hold cursor control.
- [x] Build app/extension and run 47 tests including reducer, actual surface and timer paths.
- [ ] Physical-device acceptance for simultaneous fingers, drag feel, VoiceOver and third-party editors.

## Web-only presentation — 17 October 2026

- [x] Show Keyboard setup directly; temporarily hide Connect and its tab bar.
- [x] Hide the keyboard's transport segmented control and reclaim its space.
- [x] Force Web for UI mode requests and previously saved native-mode preferences.
- [x] Preserve nearby source behind AirTypeFeatures.nearbyTypingEnabled for later development.
- [x] Build and pass 47 tests; inspect setup and Web keyboard simulator previews.

## Icon refinement — 17 October 2026

- [x] Use smaller 17-point panel control symbols within 44-point circular hit areas.
- [x] Mask the Web Access logo with a radius calculated from its current bounds, retaining a white circular background.
- [x] Always show a local globe between 123/ABC and Wi-Fi; preserve native system input-mode menu handling.
- [x] Build, inspect simulator previews and pass all 47 tests, including the updated globe placement check.

## Restore system globe policy — 17 October 2026

Both local and Web keyboards follow UIInputViewController.needsInputModeSwitchKey. Do not hard-code device models. Hide the in-keyboard globe when the system does not require it; retain its 123/ABC–globe–Wi-Fi position when shown. Space takes the freed width.

## Simplified containing app — 17 October 2026

- [x] Compact branded header and three short cards: Set up the keyboard, Allow Local Network, Try AirType.
- [x] Keep network access before optional connection naming; show short honest idle/checking/completed/blocked/failed messages.
- [x] Move connection name, detailed diagnostics, troubleshooting, manual keyboard path, shared preview and privacy explanation into Advanced settings.
- [x] Keep a single installed-keyboard Try entry on the home screen; simplify its text field, remove preview appearance controls and add a placeholder/connection hint.
- [x] Footer links: Threads @invivointeractive, http://www.invivointeractive.com/airtype and mailto:info@invivovinteractive.com (exact supplied spelling).
- [x] Adaptive horizontal/vertical footer links for large Dynamic Type.
- [x] App/extension build and all 47 tests pass; simulator checks cover home, network success, Advanced navigation, Try navigation and larger text.
