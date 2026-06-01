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

## Related docs

- [bluetooth.md](bluetooth.md) — BLE stack and GATT overview  
- [architecture.md](architecture.md) — Background service entry points  
