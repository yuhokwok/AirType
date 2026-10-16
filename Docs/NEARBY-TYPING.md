# Nearby typing feasibility

Research checked on 16 October 2026. The first native developer implementation is now available; see [the build and validation checklist](NEARBY-PLAN.md).

## Product direction to confirm

The existing keyboard receives text from a computer browser. The proposed host-app mode could instead make the iPhone a keyboard for a computer, or receive text in the host app. The first developer build takes the iPhone-to-Mac direction, with a native Mac receiver. Other directions and platforms remain separate follow-up scope.

## Transport choices

| Route | Feasibility and client requirements |
| --- | --- |
| Apple peer-to-peer Wi-Fi | Available using Network.framework with `includePeerToPeer` on discovery, listener and connection parameters. Appropriate for an iPhone/iPad and Mac companion app. No shared router is required. This is Apple's peer-to-peer protocol, not generic cross-platform Wi-Fi Direct. A browser does not itself perform the required native peer discovery and connection setup. |
| Wi-Fi Aware | An optional newer route on iOS 26 and supported hardware. Requires the Wi-Fi Aware capability, declared services, pairing and a compatible peer implementation. It is an industry standard, but cannot be assumed to work with every PC that advertises Wi-Fi Direct. |
| Custom Bluetooth LE | Core Bluetooth supports app-defined data services between a central and peripheral. A desktop companion can exchange text/commands over that service. This does not automatically make the device a standard system Bluetooth keyboard. |
| Bluetooth HID keyboard, without a desktop receiver | Worth a physical-device prototype. An existing App Store product advertises this behavior, but its internal implementation and compatibility are not documented by Apple. The available Core Bluetooth data-transfer sample does not establish that HID keyboard emulation works on all required hosts. Do not label it impossible or promise production support without testing advertising, pairing, HID reports and host behavior. |

## Proposed app split

Keep the keyboard extension's current browser-to-iPhone workflow. Give the containing app a separate nearby-typing screen once the desired direction is confirmed. Start with a Mac companion for Apple peer-to-peer Wi-Fi and custom BLE if those are the target platforms. A phone-to-computer mode needs the receiver to deliver commands to the computer's focused app. A computer-to-iPhone host-app mode can edit its own field, but the host app cannot replace the extension's system-wide document proxy in another app.

Run the first prototype in the foreground. Validate reconnect, device identity/pairing, Unicode and key commands on two physical devices. Do not assume app/extension processes stay alive when switching apps. Test Bluetooth HID independently from BLE transport; successful GATT transfer is not evidence of HID keyboard support.

## Bundle identity

The Xcode project now uses app `com.invivo.ios.AirType`, keyboard `com.invivo.ios.AirType.Keyboard`, and tests `com.invivo.ios.AirTypeTests`, with development team `5778F83X4J`. `project.yml` was synchronized so regeneration preserves the user's changes. The existing shared App Group is intentionally unchanged: group identifiers need not match the app bundle identifier, and replacing a provisioned group would require configuring that group for both targets.

## Primary references

- [Apple TN3111: iOS Wi-Fi API overview](https://developer.apple.com/documentation/technotes/tn3111-ios-wifi-api-overview)
- [Apple TN3151: Choosing the right networking API](https://developer.apple.com/documentation/technotes/tn3151-choosing-the-right-networking-api)
- [Apple TN3213: Moving from Multipeer Connectivity to Network framework](https://developer.apple.com/documentation/technotes/tn3213-moving-from-multipeer-connectivity-to-network-framework)
- [Apple: Adopting Wi-Fi Aware](https://developer.apple.com/documentation/wifiaware/adopting-wi-fi-aware)
- [Apple: Transferring Data Between Bluetooth Low Energy Devices](https://developer.apple.com/documentation/corebluetooth/transferring-data-between-bluetooth-low-energy-devices)
- [Bluetouch App Store product description](https://apps.apple.com/us/app/bluetouch/id1622635358) — product evidence only, not documentation of its implementation.
