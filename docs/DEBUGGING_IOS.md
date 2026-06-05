# Debugging on iOS

Tips for running and debugging the Luftdaten.at app on Apple devices and simulators. The root [README.md](../README.md) links here for iOS-specific issues (e.g. LLDB noise).

## Basics

1. Open the `ios/Runner.xcworkspace` in Xcode if you need to adjust signing, capabilities, or native breakpoints.
2. From the CLI, `flutter run` with an iOS device selected is usually enough for Dart-level debugging.
3. Ensure **Bluetooth** capability and usage descriptions in `Info.plist` match what `permission_handler` and `flutter_reactive_ble` require for your test scenario (physical devices for real BLE).

## LLDB / debugger warnings

When attaching to a **physical** iPhone, Xcode’s debugger sometimes prints LLDB warnings about symbols, dyld, or system frameworks. These are often **benign** and do not indicate a problem in app Dart code.

If debugging is unstable:

- Disconnect and reconnect the device; unlock the phone.
- In Xcode: **Window → Devices and Simulators** — check that the device is trusted and developer mode is enabled (iOS 16+).
- Try **Product → Clean Build Folder** in Xcode, then `flutter clean && flutter pub get && flutter run`.

## Swift Package Manager (SPM) migration errors

Flutter may try **“Adding Swift Package Manager integration…”** when SPM is enabled. If `xcodebuild` fails resolving plugin packages (for example **`public headers ("include") directory path … is invalid`** for **`flutter_native_splash`**), SPM metadata for that plugin is incompatible with the current Xcode/Flutter toolchain.

This repo disables SPM **per project** so iOS deps use CocoaPods consistently:

[`pubspec.yaml`](../pubspec.yaml) → `flutter` → `config` → **`enable-swift-package-manager: false`** (see [Flutter docs — turn off SPM](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers#how-to-turn-off-swift-package-manager)).

If Xcode already partially added **`FlutterGeneratedPluginSwiftPackage`**, turn SPM off as above, then run `flutter clean`, open **`ios/Runner.xcworkspace`**, remove that local package and any related **Runner** frameworks / scheme **Pre-actions**, as in [remove SPM integration](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers#how-to-remove-swift-package-manager-integration), then **`cd ios && pod install`**.

## Bluetooth and background

BLE behavior differs between **simulator** (limited/no real BLE) and **device**. For protocol work, use a physical device.

Background measurement uses `flutter_background_service` with an iOS-specific implementation (`lib/core/background_services/background_service_ios.dart`). If background tasks misbehave, verify:

- Appropriate **Background Modes** / notifications setup in the iOS project (as required by the plugins in use).
- That the app has been run at least once with permissions granted.

## Simulator vs device

- Prefer the **iOS Simulator** for UI and map-only work.
- Use a **real device** for BLE, push/notification nuances, and performance closer to production.

## Mock BLE devices (debug builds only)

The iOS Simulator has no real Bluetooth. In **debug** builds (`flutter run`), you can add **mock BLE devices** that simulate connect/disconnect, battery/status, and live PM readings for measurement trips.

1. Run the app on the simulator (`flutter run`).
2. Open **Einstellungen** → **Entwickleroptionen** → **Mock-BLE-Geräte (Simulator)**.
3. Ensure **Mock-BLE aktiv** is on (enabled by default on first launch on simulator).
4. Tap **Air aRound hinzufügen** or **Beide Presets**, then open the **Geräte** tab.
5. Tap **Verbinden** on a mock device, then start a measurement as usual — the background loop uses fake sensor values.

Shortcuts on the Geräte tab (simulator only): **Mock-Gerät hinzufügen** in the empty state, or the flask icon next to **Neues Gerät hinzufügen**.

Manual QR-style entry without a camera: **Manuelle QR-Daten…** on the mock page (same format as a device QR code).

Mock BLE is **not available in release/profile builds**. On a physical iPhone, mock mode stays off unless you explicitly enable it under Entwickleroptionen.

## Related docs

- [bluetooth.md](bluetooth.md) — BLE stack and GATT overview  
- [architecture.md](architecture.md) — Background service entry points  
