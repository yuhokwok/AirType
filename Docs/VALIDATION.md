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

## Native keyboard receiving — 16 October 2026

The native modes now send from AirTypeDesktop on Mac into the visible keyboard extension, which applies commands through textDocumentProxy. The containing app prepares settings/permissions. Both platform builds and all 24 XCTest cases pass. Real Bonjour/TCP integration passes, including a Mac sender delivering Chinese and emoji into the iOS Simulator preview UITextView with encrypted acknowledgement. See [the detailed checklist](NEARBY-PLAN.md) and [preview evidence](Validation/native-keyboard-preview.jpg). Installed-extension Bluetooth, no-router Wi-Fi and editing across physical-device apps remain unverified.

## CInput basic behavior and connection controls — 17 October 2026

Compared CInput's KeyboardViewModel, KeyboardHandler and KeyboardTouchStateMachine with AirType. AirType now follows host capitalization/context, retains one-shot Shift/caps lock and symbol pages, and uses CInput's immediate delete, one-second repeat delay, 100–35 ms left-drag cadence. Native keyboard switching follows UIInputViewController.needsInputModeSwitchKey. The AirType brand image is retained on the connection panel and local mode toggle.

The connection panel uses equal status/pairing halves and a selector inset 16 points on both sides. Keyboard-return/delete controls are 44-point circles with UIButton.Configuration.glass() on iOS 26+ and solid fallbacks.

All 32 XCTest cases pass on the iOS 27 Simulator, including capitalization, hidden context, actual local button input, immediate/repeated/cancelled delete, accessible deletion, mode transitions and layout at 320×216, 852×162 and 1024×264. Tests also exercise both globe visibility states. App and embedded keyboard extension compile. Shared-view simulator screenshots: [connection controls](Validation/connection-controls-ios26.jpg), [QWERTY and AirType icon](Validation/qwerty-airtype-icon.jpg). Fresh physical-device touch/VoiceOver, older-iOS fallback appearance and installed-extension rendering remain separate acceptance checks.

API references: [needsInputModeSwitchKey](https://developer.apple.com/documentation/uikit/uiinputviewcontroller/needsinputmodeswitchkey), [UIKit glass button configuration](https://developer.apple.com/documentation/uikit/uibutton/configuration-swift.struct/glass()).

## CInput multi-touch, temporary modifiers and key previews — 17 October 2026

The local keyboard now has a stable UIKit touch surface and per-contact state modeled on CInput's touch dispatcher, rollover policy, Shift state and temporary layout state. It does not replace the touch surface when Shift or a symbol layout changes. Letter/space rollover commits older contacts in press order and consumes later releases. Modifier-first and character-first releases are tested, including preserving a pending symbol's identity after the layout returns. Dragging from a character to Return or Wi-Fi cannot submit or switch modes.

Phone keys use radius 10 and wide iPad keys 14. Character popups use a rounded cap/stem and remain within horizontal bounds. The bottom row places Wi-Fi beside 123/ABC, then the optional globe, space, period and return. AirType branding remains in its connection panel. A 34-point row offers local English spelling/completion choices. Space holds activate cursor movement after 400 ms, with 12 points per character, and suppress space insertion on release.

All 47 XCTest cases pass on iOS 27 Simulator. The new checks cover Shift drag, held Shift with another finger, symbol drag and source restoration, reverse release order, repeat delivery, cancellation, manual Shift, caps lock, actual touch-surface rollover and popups, spelling-choice replacement, space cursor control and timed delete cancellation. The app and embedded extension build without compiler warnings. This uses the production contact handlers with deterministic contact identities; it is not physical multi-finger touch evidence.

Screenshots: [running shared keyboard preview](Validation/qwerty-wifi-spelling.jpg) and [rendered XCTest rollover/key-popup attachment](Validation/keyboard-rollover-popup.png). The latter is a UIKit test render of the actual local keyboard, not a device screenshot. Device feel, installed-extension sizing across orientations and third-party-editor acceptance remain hardware checks.

## Temporarily expose setup and Web only — 17 October 2026

AirTypeHomeView now displays SetupView directly, with no Connect tab or tab bar. AirTypeFeatures.nearbyTypingEnabled is false: keyboard transport selection is hidden, receive-mode assignments resolve to Web, and previously saved native preferences are ignored while disabled. Native source is retained.

The iOS app/extension build and all 47 tests pass. The existing connection layout regression now verifies equal halves, no segmented transport control, and Web mode after a native-mode request. Simulator screenshots show [setup-only app](Validation/setup-only.jpg) and [Web-only keyboard preview](Validation/web-only-keyboard.jpg). Physical networking acceptance remains separate.

## Panel icons and local globe — 17 October 2026

The Web AirType keyboard/delete controls now use 17-point SF Symbols inside their existing 44-point circular controls. The logo's corner radius follows half its current bounds, with a white background, so resizing cannot turn the badge into a rounded square. The local keyboard always shows a native globe between 123/ABC and Wi-Fi, including Face ID devices. The remote panel retains the system-requested globe policy.

App/extension build and all 47 tests pass. The local mode-transition test now checks the globe is present and lies between the numeric and Wi-Fi controls. Shared-view previews were inspected for the circular logo, smaller controls and revised bottom row. Physical-device system-menu interaction remains a separate acceptance check.

## Restore conditional local globe — 17 October 2026

Removed the local keyboard's forced globe visibility. It now receives the same needsInputModeSwitchKey value as the Web panel. The existing mode-transition regression covers hiding and showing the local globe and its position between 123/ABC and Wi-Fi when shown. This follows UIKit's current keyboard environment rather than an iPhone model list.

## Three-step setup and contact links — 17 October 2026

The home screen now shows only Set up the keyboard, Allow Local Network and Try AirType, followed by Advanced settings and contact links. The compact header places all three actions and the footer within the tested normal-size iPhone viewport. Network status is a short message; completion is explicitly a local check, not a claim that a computer is connected or Full Access is enabled.

Advanced settings retains connection-name persistence/normalization, raw network diagnostics and recheck, app Settings access, connection help, manual keyboard setup, shared preview and privacy explanation. Try AirType uses the installed system keyboard and now has a text placeholder and connection hint without Light/Dark or Clear test controls. The shared preview retains those controls in Advanced settings.

Footer destinations are https://www.threads.com/@invivointeractive, http://www.invivointeractive.com/airtype and mailto:info@invivovinteractive.com. The email spelling matches the user's request exactly. Link destinations were checked in source; the web research tool could not retrieve the two external pages, so external page availability and email delivery were not verified.

App/extension build and all 47 XCTest cases pass. CUA on Device Hub verified the home network-check action reached completion, Advanced settings navigation and the installed-keyboard Try destination. Increasing simulator Text Size from 3 to 7 confirmed wrapping and scrolling; footer links changed to a vertical stack. Text Size was restored to 3. This does not establish real-device Local Network prompts, full Settings enablement, cross-device connectivity or VoiceOver acceptance.

Evidence: [home](Validation/setup-three-steps.jpg), [network check complete](Validation/setup-network-complete.jpg), [Advanced settings](Validation/setup-advanced.jpg), [Try AirType](Validation/setup-try-airtype.jpg), [large-text footer](Validation/setup-large-text-footer.jpg).


## UI localization and empty-draft keys — 18 October 2026

The shipping iOS UI and permission descriptions now support English, Traditional Chinese and Simplified Chinese. The server chooses the portal language from the effective app/extension language and injects its bundled translation dictionary into the HTML; browser language does not participate. Pairing, typing controls, status/errors, accessibility labels and emoji categories/names are translated. The QWERTY layout and local spelling service remain English.

All **50 XCTest cases** and **10 Node portal regressions** pass. New native tests verify locale negotiation, localized native/InfoPlist resources and server HTML injection. Portal tests cover empty Enter/Backspace, nonempty and whitespace-only drafts, Shift+Enter, composing/keyCode 229/modifier guards, disconnected/no-replay behavior and Chinese emoji search. Existing reconnect and pairing regressions remain green. The app and embedded extension build successfully.

CUA verified a real Traditional Chinese portal pairing and Chinese emoji search against the production server in the shared keyboard preview. Sending `回車刪除A`, pressing Enter on the empty draft, then Backspace twice produced `回車刪除`: Return inserted a newline; Delete removed that newline and then the final A. The browser console had no warnings or errors. This proves browser → server → production shared keyboard preview → UITextView delivery; it is not a fresh installed-extension or physical-device test.

An independent iPhone 17/iOS 27 simulator was used because another session switched the shared simulator to another app. The independent preview used the dynamic fallback port because 8307 was occupied. UI inspection covered English, Traditional Chinese and Simplified Chinese setup screens. Physical iPhone/iPad language changes, extension resource selection, permissions and third-party text fields remain device acceptance gates.

Evidence: [English setup](Validation/localization-setup-en.jpg), [Traditional Chinese setup](Validation/localization-setup-zh-Hant.jpg), [Simplified Chinese setup](Validation/localization-setup-zh-Hans.jpg), [Chinese browser](Validation/localization-web-zh-Hant.png), [empty Enter result](Validation/web-empty-enter.jpg), [two empty Backspaces result](Validation/web-empty-backspace.jpg).


## Version 1.1 and animated typing guide — 18 October 2026

Both the built app and embedded keyboard extension report CFBundleShortVersionString 1.1. The project and project.yml agree. The home tagline is “Type, from your computer.” / “用電腦，為手機打字。” / “用电脑，为手机打字。”. The Advanced settings destination is removed; connection name and privacy are homepage disclosures. The removed diagnostics/help/preview sections are no longer reachable in the shipping UI; developer preview launch arguments remain available.

The localized in-app guide illustrates the keyboard, browser address, six-digit pairing and text delivery over four steps. Values are explicitly examples. It supports automatic playback, pause/resume, manual previous/next and replay; Reduce Motion uses manual static steps, and inactive scenes cancel the playback task. App/extension build and all 50 XCTest cases pass. Native simulator CUA checks cover homepage disclosures, tutorial navigation and playback controls. This is an illustrated native animation, not a video of physical-device pairing.

Evidence: [version 1.1 home](Validation/setup-v1.1.jpg), [typing guide](Validation/typing-guide-v1.1.jpg).


## Screenshot-led home and Bonjour settings — 18 October 2026

The app home now follows owner-supplied IMG_0152–0156: a white paper panel on black, gradient Wi-Fi mark, cyan/blue/purple three-column tiles with numbered circles, and separate closeable color-block instruction/policy/settings screens. Modern safe-area, scrolling, system text and six-digit pairing behavior are retained. No legacy iOS status-bar/back-to-App-Store image is baked into the UI.

A Settings gear opens the Bonjour-name field. CUA entered `Study AirType.local`, saved its normalized value `study-airtype`, and verified it persisted after relaunch. The test then restored `airtype`. Save now resigns focus and retains the confirmation after normalization. Existing App Group persistence, safe-name and hostname-conflict tests remain green. App/extension compile without warnings; all 50 XCTest cases pass. English and Chinese reference layouts and instruction navigation were inspected in the dedicated iPhone simulator. Physical-device App Group provisioning, DNS visibility and real connection acceptance remain separate hardware gates.

The bundled privacy screen follows the previously committed legacy policy in nine sections and retains the 2014 update date. It does not represent a newly revised policy for the current HTTP transport. Website edits already present in the worktree were left untouched.

Evidence: [Chinese home](Validation/reference-home-zh.jpg), [English home](Validation/reference-home-en.jpg), [connection guide](Validation/reference-connection-guide.jpg), [Bonjour save confirmation](Validation/reference-bonjour-settings.jpg).


## Adaptive iPhone layout — 18 October 2026

The home now measures the safe-area viewport and scales its header, number band and column spacing from available width/height. Landscape uses a smaller mark, number band and icons. Titles wrap naturally; accessibility text categories switch to full-width vertical rows. The paper fills the available viewport with a small adaptive inset, while long content scrolls. Guides/settings/policy no longer require a fixed 620-point page. Close sits outside the scrolling content in a fixed header. Scrolling is clipped at the viewport, and the header background no longer extends into the status-bar safe area.

Build/install/launch and rendered inspection passed on iPhone SE (3rd generation) with iOS 18.2, the standard iPhone 17 QA simulator and a dedicated iPhone 17 Pro Max with iOS 27. SE portrait/landscape show all three controls without shrinking their titles. On Pro Max, Device Hub Text Size 9 visibly selects the vertical accessibility layout; the three rows remain readable. Long policy scrolling keeps Close available. Text Size was restored to 3, and the SE was restored to portrait. The iOS 18 inspector changed its value without visibly changing app typography, so the actual accessibility visual evidence comes from iOS 27. All 50 XCTest cases pass on the final source. Physical-device Display Zoom, call/hotspot status indicators and every iPhone model have not been individually checked.

Evidence: [SE portrait](Validation/adaptive-iphone-se.jpg), [SE landscape](Validation/adaptive-iphone-se-landscape.jpg), [standard iPhone](Validation/adaptive-iphone-standard.jpg), [Pro Max](Validation/adaptive-iphone-pro-max.jpg), [accessibility text](Validation/adaptive-accessibility-text.jpg), [policy safe area](Validation/adaptive-policy-safe-area.jpg).


## Vertical home with retained palette — 18 October 2026

The three steps are now vertical rounded cards using the original cyan/blue/purple palette and mosaic number badges. The Wi-Fi mark replaces the square app icon in the home header; the exact tagline is “Type, over the air”, with Traditional/Simplified Chinese equivalents. Step buttons directly open app Settings, request/check Local Network, or open the installed-keyboard test field. Separate information buttons retain the reference-style instruction pages. The tutorial, Bonjour name and privacy entries, and contact footer remain below the cards.

App/extension build and all 50 XCTest cases pass. Pro Max simulator inspection verifies the hierarchy and the exact English header, and CUA verifies the Try field opens and closes. Main cards continue to wrap/scroll without fixed heights. This native UI change leaves the browser portal and other pending website work untouched.

The direct Local Network button progressed from Checking to Network check complete in the simulator. Connection name opens the persisted Bonjour form. English/Traditional Chinese home screens were inspected. On iPhone SE/iOS 18.2, a native simulator swipe verified the lower Try, tutorial, settings, privacy and contact entries are reachable. This is simulator navigation/local discovery proof, not physical-device permission acceptance.

Evidence: [English](Validation/vertical-home-en.jpg), [Chinese](Validation/vertical-home-zh.jpg), [SE upper page](Validation/vertical-home-se.jpg), [SE footer after scrolling](Validation/vertical-home-se-footer.jpg).


## Centered reference Wi-Fi header — 18 October 2026

The header now centers a three-arc Wi-Fi mark over “Type, over the air” on white, with no side-by-side app-name row. The previous shallow freehand curves were replaced by circular cubic arc segments with round endpoints and the reference’s outer/inner stroke proportions. The vector shape fills a 300×176 reference coordinate space with a continuous blue-cyan to turquoise gradient. Vertical cards and their actions are unchanged.

App/extension build and rendered checks pass on iPhone SE (iOS 18.2) and the dedicated Pro Max simulator (iOS 27). This is a visual-only change; the previously passing 50-case suite was not rerun for arc geometry/spacing. Evidence: [SE header](Validation/centered-wave-header-se.jpg), [Pro Max header](Validation/centered-wave-header-pro-max.jpg).


## Step-specific secondary actions — 18 October 2026

Connection name is now a plain, unfilled blue button inside Step 2, immediately below Allow Local Network. Watch the typing guide is a plain purple button inside Step 3, immediately below Try AirType. Each uses its step tint and a 44-point minimum hit height. The previous standalone tutorial pill and connection-name row were removed; privacy and contacts remain below the cards.

The app/extension build passes. Rendered Pro Max inspection verifies both placements and colors; native CUA confirms the relocated connection button opens the Bonjour-name form. The tutorial retains the existing showTutorial sheet action. No input/network logic changed, and the full suite was not rerun for this placement/style edit. Evidence: [secondary actions](Validation/step-secondary-actions.jpg).


## Settings and tutorial popup colors — 18 October 2026

The Step 2 secondary action and Bonjour screen now say Set connection name, with Traditional/Simplified Chinese translations. Settings uses the Step 2 blue title, mosaic and controls. The reference paper screens use a white scroll canvas and light appearance, removing the black background exposed by overscroll. The typing tutorial shares the reference mosaic heading, with Step 3 purple for the heading, controls, progress and animated highlights. Its close button remains outside scrolling content.

Build/install/launch passes on the dedicated iPhone 17 Pro Max simulator (iOS 27). Device Hub rendering and semantic navigation confirm the blue settings screen and purple tutorial heading, and settings closes back to the home. All 50 XCTest cases pass on the final source. The last progress/border tint adjustment was build/test verified. Physical-device overscroll has not been separately checked.


## Secondary actions use sheets — 18 October 2026

Set connection name now has a dedicated sheet route instead of the full-screen guide route. Both it and Watch the typing guide use the large native sheet detent with a visible grabber and their existing close buttons. App/extension build passes. Simulator semantic navigation confirms both presentations expose Sheet Grabber, settings closes to home, and the tutorial opens with its playback controls. The 50-case suite was not rerun for this presentation-only change.


## Anchored information popovers — 18 October 2026

Each step information button now owns a native popover anchored to that button. Compact-width adaptation explicitly retains popover presentation on iPhone. The preferred 320×460 size keeps the reference heading and scrollable instructions inside a floating card; existing Close and outside-tap dismissal remain available. Settings and tutorial retain their sheet routes. Build/install/launch passes. Rendered Pro Max inspection confirms the Step 1 arrow points to its information button, the home remains visible behind the floating card, and the accessibility tree exposes PopoverDismissRegion rather than Sheet Grabber. This presentation-only edit did not rerun the test suite or individually validate every device size.


## Dual keyboard addresses and label refinements — 18 October 2026

The Web Access strip shows the preferred address at 12pt and an alternate at 9pt. Tapping swaps Bonjour/IP; duplicate or missing alternates are hidden. Both fields refresh when server addresses change. Long-press (or the VoiceOver custom action) opens details and a QR code for the selected primary address. Back/delete symbols shrink from 17pt to 14pt, retaining their 44pt hit areas and circular/glass backgrounds. The tutorial heading is Type guide. and Privacy uses the same gray as its page heading.

App/extension build and all 52 tests pass. Two added interaction tests cover swapping, live IP updates, IP-only/duplicate states, private-token omission in the strip, and selected-address details/QR availability. Dedicated Pro Max preview inspection verifies both address rows and a native tap exchanges their order. Both displayed Bonjour and IPv4 URLs return HTTP 200 from the running preview server. This is simulator/host network evidence, not a new physical-device connectivity check.


## Address swap hint and system keyboard canvas — 18 October 2026

A small up/down symbol and localized Tap to swap addresses hint now appear below the two address lines, hidden when there is no alternate. VoiceOver exposes the same hint. AirKeyboardView and the extension root are transparent/nonopaque, removing the custom light/dark canvas so the system keyboard host supplies its background. Key/button backgrounds remain intact. App/extension build and 52 tests pass, including visibility checks for the alternate-address hint and the transparent shared keyboard canvas. Simulator runtime snapshot confirms the hint appears alongside both addresses. The in-app preview has a different host; physical extension material/blur appearance remains a device visual check.


## Address hint legibility and smaller controls — 18 October 2026

The swap symbol is now 14pt to the right of the two address lines; the caption beneath them increases from 8pt to 10pt. Both hide when no alternate address exists. Back/delete symbols use an explicitly reconfigured 12pt image as well as the button preferred configuration, preserving the 44pt hit targets. Build and rendered Pro Max preview inspection pass; all 52 tests pass.


## Try AirType header matches tutorial — 18 October 2026

Try AirType uses the same shared popup frame as the typing tutorial: fixed light-gray close symbol and the purple Step 3 mosaic/large lightweight heading. The centered navigation-bar title is removed. The Try screen retains its existing full-screen presentation and installed-keyboard text field. Build/install/launch and rendered Pro Max inspection pass; the text field shows its insertion cursor under the new header. No input logic changed; the full suite was not repeated for this header-only change.
