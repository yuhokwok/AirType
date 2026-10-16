# AirType implementation checklist

- [x] Locate invivo's original listing and inspect all four screenshots.
- [x] Save reference assets and record inferred design contract.
- [x] Create containing iOS app, embedded keyboard extension, and shared resources.
- [x] Reproduce grey Web Access panel, circular original icon, status, keyboard/address/delete controls and conditional globe.
- [x] Reproduce four-row QWERTY, shift/caps, symbol pages, space, AirType icon toggle, blue return key, light/dark appearance.
- [x] Implement keyboard document-proxy insertion, deletion, newline, system globe menu, repeat Delete.
- [x] Implement local browser portal, Enter/Send, Unicode, reconnect polling and retained drafts.
- [x] Implement bounded HTTP parsing, pairing-token authentication, origin checks, duplicate-command protection and server cleanup.
- [x] Build and run app plus embedded extension on iPhone Simulator.
- [x] Test parser/command validation and actual extension browser-to-field behaviour.
- [ ] Physical-device acceptance: signing, Wi-Fi permissions, second-computer connection, host apps, iPad and landscape touch layouts.
- [x] Add visible foreground Bonjour check, permission recovery guidance, specific network errors, and hostname retries after permission changes.

## Design contract

Connection mode (updated 17 October 2026): grey keyboard background, a 16-point inset segmented connection selector, and equal-width status/icon and pairing-code halves. Bottom-left returns to the local keyboard; bottom-right deletes. Both are 44-point circular buttons using native Liquid Glass on iOS 26+ and solid circle fallbacks on iOS 17–25. The address/details control stays between them. The original AirType branding remains visible.

Local mode: QWERTY / ASDF / shift-ZXCV-delete rows, followed by 123, optional globe, wide space, AirType icon and blue return. The extension follows needsInputModeSwitchKey instead of hard-coded iPhone models, preserving the system globe on Face ID phones. Capitalization follows the current text field, Shift supports one-shot capitals and caps lock, and delete uses CInput's one-second delay, 100 ms cadence and left-drag acceleration down to 35 ms. Dark keys retain solid charcoal styling.

The setup app and connection-token/QR detail screen are new supporting UI. The reference screenshots do not show the original containing app. iOS 17 is the new minimum; the historical listing's iOS 8 compatibility is not replicated.
