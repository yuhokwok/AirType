# Localization

AirType ships `en`, `zh-Hant` and `zh-Hans`; English is the development language. iOS selects the app/extension’s supported language from its language preferences. `L10n.language` normalizes that choice for the portal. Unsupported languages fall back through the supported preferences, ultimately to English.

## Sources

- `Shared/Localizable.xcstrings`: native UI strings. UIKit and dynamic SwiftUI strings use `L10n.text` or `L10n.format`; do not translate characters inserted by the QWERTY keys.
- `Shared/InfoPlist.xcstrings`: localized system permission descriptions for both iOS targets.
- `Shared/Resources/PortalLocales.json`: Chinese portal labels, status/error messages, emoji categories and names. English strings in `Portal.html` are the fallback keys. Keep these keys synchronized when changing the portal or shared server error messages.
- `Shared/L10n.swift`: loads the selected dictionary, escapes it for inline-script safety and replaces the portal translation marker and HTML language. The browser never uses `navigator.language` or `Accept-Language` to choose UI language.

Reopen AirType/Web Access and reload the browser after changing the phone/tablet’s language. The dictionary is injected per HTML response; already-open pages retain their language until refreshed. No extra network translation resources are required.

## Browser shortcuts

| Draft and key | Result |
| --- | --- |
| Text present + Enter | Send draft text |
| Empty + Enter | Send `newline` to the keyboard |
| Empty + Backspace | Send `delete` to the keyboard |
| Text present + Backspace | Edit browser draft normally |
| Shift+Enter | Add a browser draft line |
| IME composing, keyCode 229, Ctrl/Command/Alt | Do not forward a shortcut |

Whitespace is text, not an empty draft. Disconnected or busy requests are not queued or automatically replayed. Existing command acknowledgement and uncertain-send draft retention rules remain in effect.

## Validation

Run the AirType XCTest scheme and `node --test Tests/PortalConnectionTests.cjs`. `LocalizationTests.swift` checks supported-language matching, bundled string tables and server-side HTML injection. Portal regressions check labels/search and key forwarding. Device acceptance remains necessary for language changes in the installed extension and actual host apps. See [validation evidence](VALIDATION.md).
