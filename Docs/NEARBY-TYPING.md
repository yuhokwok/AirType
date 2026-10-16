# Nearby typing architecture

The requested direction is **computer → keyboard extension → iPhone/iPad app text field**. AirTypeDesktop sends commands. The visible AirType keyboard receives and calls textDocumentProxy. The containing app configures permissions and the preferred transport; it does not receive and forward commands in the background.

## Implemented developer transports

| Route | Implementation and limits |
| --- | --- |
| Web | Existing browser-to-keyboard HTTP workflow on shared Wi-Fi; six-digit pairing code. |
| Direct Wi-Fi | Network.framework Bonjour discovery and TCP with includePeerToPeer on browser, listener and connection. Mac companion required. Infrastructure Wi-Fi may be selected. No-router operation requires hardware testing. |
| Bluetooth LE | Mac central sends to a custom GATT service published by the keyboard's CoreBluetooth peripheral. Twenty-character pairing key, encrypted protocol, MTU fragmentation and backpressure. Extension radio/permission behavior still requires physical-device validation. |

Only the selected transport runs while the keyboard connection panel is active. Hiding the keyboard or switching to QWERTY disconnects. Native commands support Unicode insertion, Delete, Return, Tab and left/right cursor movement; the iOS document proxy does not offer general Escape or vertical-arrow events. Secure fields and apps that disable third-party keyboards remain subject to iOS restrictions.

Apple peer-to-peer networking is not generic cross-platform Wi-Fi Direct. Wi-Fi Aware and Bluetooth HID are not implemented. Successful local TCP or GATT framing tests do not prove a particular radio path.

## Identity and validation

App: com.invivo.ios.AirType. Keyboard: com.invivo.ios.AirType.Keyboard. Mac: com.invivo.mac.AirTypeDesktop. Shared App Group: group.com.invivo.AirTypeReplica. project.yml preserves the user's team and bundle identifiers.

See [the implementation and validation checklist](NEARBY-PLAN.md) for completed tests and outstanding physical-device gates.

## Apple references

- [Creating a custom keyboard](https://developer.apple.com/documentation/uikit/creating-a-custom-keyboard)
- [Core Bluetooth](https://developer.apple.com/documentation/corebluetooth)
- [iOS Wi-Fi API overview](https://developer.apple.com/documentation/technotes/tn3111-ios-wifi-api-overview)
- [Moving from Multipeer Connectivity to Network framework](https://developer.apple.com/documentation/technotes/tn3213-moving-from-multipeer-connectivity-to-network-framework)
- [Transferring data between Bluetooth Low Energy devices](https://developer.apple.com/documentation/corebluetooth/transferring-data-between-bluetooth-low-energy-devices)
