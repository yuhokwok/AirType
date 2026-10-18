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


## UI localization and browser key forwarding — 18 October 2026

- [x] Localize shipping iOS setup, Advanced settings, test/preview, keyboard controls/status and permission descriptions into English, Traditional Chinese and Simplified Chinese.
- [x] Select portal language on the serving iPhone/iPad, independent of browser language; translate pairing, typing, errors, accessibility labels and emoji search names.
- [x] Forward empty-draft Enter as Return and Backspace as Delete, preserving normal draft edits, Shift+Enter, IME composition and modified shortcuts.
- [x] Keep existing reconnect cutoff, uncertain-send draft retention and no automatic command replay.
- [x] Pass 50 XCTest cases and 10 portal regressions; inspect all three native setup languages and actual Chinese browser-to-preview input.
- [ ] Fresh physical-device acceptance for installed-extension editing, app-language changes, Local Network permission and third-party editors.


## Version 1.1 and simpler setup — 18 October 2026

- [x] Set app/extension marketing version to 1.1 in the project and generator source.
- [x] Restore “Type, from your computer.” with suitable Traditional/Simplified Chinese taglines.
- [x] Remove Advanced settings, network diagnostics, connection help, keyboard setup help and the UI preview entry.
- [x] Put expandable connection naming and privacy directly on the homepage.
- [x] Add a localized four-step animated typing guide, with pause/play, replay, previous/next and Reduce Motion support. Stop animation offscreen/inactive.
- [x] Build app/extension, pass all 50 XCTest cases and inspect the revised native flow.


## Owner screenshot home and Bonjour settings — 18 October 2026

- [x] Match IMG_0152’s three cyan/blue/purple number columns, Wi-Fi wordmark, tagline, privacy link and paper/black surround.
- [x] Match IMG_0153–0155’s closeable instruction pages, color-block titles and highlighted settings/key names; retain modern pairing instructions and empty-draft shortcuts.
- [x] Add a top-right Settings gear with shared Bonjour-name persistence/normalization, save feedback and reopen-keyboard instruction; retain contact links here.
- [x] Bundle the committed bilingual nine-section privacy policy for the reference-style policy screen, retaining its original date; provide Simplified Chinese UI as well.
- [x] Keep installed-keyboard Try and animated typing guide on the Type page, and Local Network permission check on Setup for AirType.
- [x] Build app/extension, pass 50 existing tests, visually inspect Chinese/English home and guide pages, and verify name persistence through UI.


## Adaptive iPhone screens — 18 October 2026

- [x] Size the paper surface from the actual safe-area viewport rather than a fixed 620-point page.
- [x] Distribute header, number band and column space using available height; use a compact layout in landscape.
- [x] Allow titles to wrap without shrinking/truncating; use full-width vertical steps at accessibility text sizes.
- [x] Keep Close in a fixed header, clip scrolling content to its viewport and allow interactive keyboard dismissal in Bonjour settings.
- [x] Inspect iPhone SE (3rd generation, iOS 18.2), standard iPhone 17 and dedicated iPhone 17 Pro Max simulator; inspect SE landscape and accessibility text size on Pro Max.
- [x] Restore test typography/orientation and pass all 50 XCTest cases.
