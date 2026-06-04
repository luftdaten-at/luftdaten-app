# Bluetooth Low Energy (BLE)

The app talks to Luftdaten.at–compatible devices (e.g. portable “Air aRound” style hardware) over **Bluetooth Low Energy** using [`flutter_reactive_ble`](https://pub.dev/packages/flutter_reactive_ble) (`^5.2.0` in `pubspec.yaml`).

---

## Architecture overview

| Piece | Role |
|-------|------|
| `BleController` | Central facade: connect, detect protocol version, delegate reads/writes to v1 or v2 implementations. |
| `BleControllerV1` / `BleControllerV2` | Protocol-specific GATT operations and parsing (`ble_controller_v1.dart`, `ble_controller_v2.dart`). |
| `DeviceManager` | Persisted device list, scanning, matching discovered peripherals to known devices (`device_manager.dart`). |
| `BluetoothEnable` | Dependency `bluetooth_enable` (git) may be used where the app needs to prompt for radio on; scanning uses `permission_handler` for Android 12+ permissions. |

`BleController` is registered as a singleton in `main.dart` (`getIt.registerSingleton<BleController>(BleController())`).

---

## Permissions

The onboarding and settings UIs request BLE-related permissions via `permission_handler`, including:

- `Permission.bluetooth`, `Permission.bluetoothScan`, `Permission.bluetoothConnect` (exact set depends on platform and flow — see `welcome_page.dart`, `settings_page.dart`, `welcome_wizard_page.dart`).

Copy explains that BLE is required to communicate with the measurement device. Battery optimization is called out separately for background behavior.

---

## Scanning and discovery

`DeviceManager.scanForDevices`:

- Requests `Permission.bluetoothScan`.
- Uses `FlutterReactiveBle().scanForDevices(withServices: serviceIds ?? [])`.
- **Default** `serviceIds` is empty so **all** advertised devices are considered; comment in code: filtering by service can miss devices (e.g. ESP32) that do not advertise the service in the scan response.
- Names starting with `Luftdaten.at` are tracked in `deviceNamesFoundAtLastScan`.
- Known devices from storage get `bleId` / state updates when a matching name appears.

---

## Connection

`BleController.connectTo`:

- Calls `connectToDevice` with `connectionTimeout: 5` seconds.
- **iOS:** Does **not** pass `servicesWithCharacteristicsToDiscover`, so the stack performs **full GATT discovery**. This avoids missing write-only characteristics when using partial discovery.

After a successful connect, `BleDevice.connect()` reads device details (including protocol v2 `device_status`). If operational notices are present (WLAN failure, incomplete configuration, no sensor, etc.), the app shows a **Gerätestatus** dialog via `BleDeviceNoticesPresenter` (same messages as `BleDeviceNoticesBanner` on Geräte / Dashboard). Polling `refreshDeviceStatus` does not re-open that dialog.

---

## GATT service and protocol selection

### Service UUID (v1 and v2)

`0931b4b5-2917-4a8d-9e72-23103c09ac29`

### Protocol version

`getProtocolVersion` reads characteristic `8d473240-13cb-1776-b1f2-823711b3ffff` (config / device details slot):

- First byte is the protocol version for **binary** firmware.
- If the first byte is `0x7B` (`'{'`), the payload is treated as **JSON** (protocol **2**).

Supported protocol values: **1** and **2**. Other values throw `IncompatibleFirmwareException`.

---

## Characteristic UUIDs

### Protocol v1 (`BleControllerV1`)

| UUID | Purpose |
|------|---------|
| `8d473240-13cb-1776-b1f2-823711b3ffff` | Config blob (sensor count, dimensions, etc.) |
| `4b439140-73cb-4776-b1f2-8f3711b3bb4f` | Sensor data (binary); read for measurements |
| `51dc5a1c-46e0-4524-ab31-c165483ebab4` | Air station config write/read |
| `13fa8751-57af-4597-a0bb-b202f6111ae6` | Device / firmware / sensor info (binary layout) |

Writes use `writeCharacteristicWithResponse` for Air Station config.

### Protocol v2 (`BleControllerV2`)

| UUID | Purpose |
|------|---------|
| `8d473240-13cb-1776-b1f2-823711b3ffff` | Device details (JSON or binary; API key may appear in JSON or trailing binary) |
| `13fa8751-57af-4597-a0bb-b202f6111ae6` | Sensor details (split binary segments) |
| `030ff8b1-1e45-4ae6-bf36-3bca4c38cdba` | Command: `0x01` measure, `0x02` measure + battery readout; also used for Air Station config **without** response |
| `4b439140-73cb-4776-b1f2-8f3711b3bb4f` | Sensor data after command |
| `77db81d9-9773-49b4-aa17-16a2f93e95f2` | Device status: 5 bytes (battery + Wi‑Fi detail + operational flags) |
| `b47b0cdf-0ced-49a9-86a5-d78a03ea7674` | Read Air Station configuration blob |

**Measurement flow (v2):** write command → delay (~2.5 s) → read status (battery) → read sensor data. Data may be **JSON** starting with `[` (`0x5B`): array `[metadataMap, rawBytes]`; metadata can carry an API key via `BleJsonParser`. Otherwise binary is parsed with the shared `_SensorDataParser` logic (same structure as v1-style payloads).

---

## Data parsing and user settings

Binary sensor payloads are interpreted into `SensorDataPoint` / `MeasurableQuantity` values. `AppSettings` toggles (which PM sizes, humidity, VOC, etc. to show) filter parsed quantities in `_SensorDataParser.filterUsingSettings` so disabled dimensions are dropped client-side.

---

## Features that depend on BLE

- Live measurements and trips (`TripController`, background services).
- Device manager UI, optional multi-device measurements (`AppSettings.I.enableMultiDeviceMeasurements`).
- Air Station configuration wizard (writes commands / config per protocol).
- Workshop uploads: `DeviceApiKeyBleSync` reads the Datahub API key from BLE on connect (`device_info`, Air Station TLV `20`, sensor JSON metadata) and persists it to `StationSecretsStore`; `DeviceApiKeyResolver` uses BLE cache then secure storage. See firmware [`ble-characteristics.md`](https://github.com/luftdaten-at/firmware/blob/main/docs/ble-characteristics.md). If the device has no `api_key` configured, uploads are skipped (`pendingMissingApiKeyHint` toast) unless a key was synced on a previous connect.
- **Serial BLE console** (`BLESerialPage`) and **nearby device debug** (`nearby_devices_debug_page.dart`) for development / support.
- Registration wizard copy references BLE MAC (registration UI is currently commented out — see [external-apis.md](external-apis.md)).

---

## Device status (5 bytes, protocol v2)

Characteristic `77db81d9-9773-49b4-aa17-16a2f93e95f2` — see firmware [`ble-characteristics.md`](https://github.com/luftdaten-at/firmware/blob/improve-error-messages/docs/ble-characteristics.md).

| Index | Field |
|-------|--------|
| 0–2 | Battery (`BatteryDetails.fromBytes`) |
| 3 | Wi‑Fi detail when `WIFI_FAILURE` is set (`0x01` credentials missing, `0x02` SSID not in scan, `0x03` connection failed) |
| 4 | Operational flags bitmask: `0x01` config incomplete, `0x02` Wi‑Fi failure, `0x04` no sensor, `0x08` SSID configured (informational only) |

Parsed by [`BleDeviceStatusParser`](lib/features/devices/data/ble_device_status.dart); shown in the app via [`BleDeviceNoticesBanner`](lib/features/devices/presentation/widgets/ble_device_notices_banner.dart) on Geräte, Dashboard (compact), and Air Station wizard. Legacy firmware with only 3 bytes still works (battery only). While a Geräte tile is expanded, status is polled every 2 s.

## Errors and debugging

- **`IncompatibleFirmwareException`:** protocol byte &gt; 2 or unknown branch in `BleControllerForProtocol`.
- **Operational notices:** from `device_status` bytes 3–4; connect-time `SensorNotFoundError` is merged when the no-sensor flag is absent.
- **Retries:** v2 uses `_readWithRetry` on some characteristics after a short delay.
- **Logging:** extensive `logger` output for connection, reads, hex dumps, and JSON-vs-binary detection.

For firmware-level packet layouts beyond this summary, refer to [firmware BLE docs](https://github.com/luftdaten-at/firmware/blob/improve-error-messages/docs/ble-characteristics.md) or `ble_controller_v1.dart` / `ble_controller_v2.dart` / `ble_device_status.dart` / `ble_json_parser.dart`.
