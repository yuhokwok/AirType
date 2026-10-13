# AirType implementation checklist

- [x] Locate invivo's original listing and inspect all four screenshots.
- [x] Save reference assets and record inferred design contract.
- [x] Create containing iOS app, embedded keyboard extension, and shared resources.
- [x] Reproduce grey Web Access panel, circular original icon, status, globe/address/delete bar.
- [x] Reproduce four-row QWERTY, shift/caps, symbol pages, space, cyan Wi-Fi toggle, blue return key, light/dark appearance.
- [x] Implement keyboard document-proxy insertion, deletion, newline, system globe menu, repeat Delete.
- [x] Implement local browser portal, Enter/Send, Unicode, reconnect polling and retained drafts.
- [x] Implement bounded HTTP parsing, pairing-token authentication, origin checks, duplicate-command protection and server cleanup.
- [x] Build and run app plus embedded extension on iPhone Simulator.
- [x] Test parser/command validation and actual extension browser-to-field behaviour.
- [ ] Physical-device acceptance: signing, Wi-Fi permissions, second-computer connection, host apps, iPad and landscape touch layouts.

## Design contract

Web mode: flat grey keyboard background; original AirType circular badge aligned toward the left; Web Access caption and fine cyan status line; full-width bottom bar with darkened square globe/delete ends, central URL and green connected dot. Address details add a QR code and complete pairing URL without changing the default reference layout.

Local mode: QWERTY / ASDF / shift-ZXCV-delete rows, followed by 123, globe, wide space, cyan Wi-Fi and blue return. Dark keys use solid charcoal instead of the obsolete system backdrop blur shown in the original screenshot. The modern iOS system supplies its own lower globe/dictation area outside the extension.

The setup app and connection-token/QR detail screen are new supporting UI. The reference screenshots do not show the original containing app. iOS 17 is the new minimum; the historical listing's iOS 8 compatibility is not replicated.
