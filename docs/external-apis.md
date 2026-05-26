# External APIs and network usage

The app uses the [`http`](https://pub.dev/packages/http) package for most programmatic requests. Map-related providers share a common `User-Agent` built in `HttpProvider` (`lib/features/map/logic/http_provider.dart`): `Luftdaten.at/<appVersion> dart:io/<platform> (...)` plus device name from `DeviceInfo`.

---

## Luftdaten.at measurement API

**Base URL:** `https://api.luftdaten.at`

### Current snapshot for map (CSV, all stations)

- **Class:** `MapHttpProvider`
- **Request:** `GET` `https://api.luftdaten.at/v1/station/current/all`
  - The response is delivered as **CSV** (same shape regardless of optional `Accept` / `output_format=json` queries in typical use). The implementation does not rely on JSON for this bulk call.
- **Response:** CSV with header **`sid,latitude,longitude,pm1,pm25,pm10`**. Each row is converted to a `Measurement` in code (`http_provider.dart`): `Location(lat, lon, null)`, `Values` rows for dimensions `PM1_0`, `PM2_5`, and `PM10_0` (`lib/core/domain/dimensions.dart`), device id `sid`. Missing numeric cells may appear as the literal string `None` and are mapped to null.
- **Why not `/v1/station/historical`?** That endpoint expects **`station_ids`** (validated by the API; missing ids → HTTP **422**). There is no app-side list of every id at fetch time for the Luftkarte, so bulk “all stations now” uses **`current/all`** instead. Structured JSON shapes for stations are documented in the [Luftdaten.at API Swagger](https://api.luftdaten.at/docs) (e.g. `/v1/station/all` for station metadata).
- **Caching / throttle:** `fetch()` only triggers a network call if the last **successful** load is older than 5 minutes (or 30 seconds if the list is still empty). After HTTP 200, parsed rows populate `allItems` and `_lastfetch` is updated (`http_provider.dart`).
- **Consumers:** Map page markers when **“Stationäre Messstationen”** overlay is enabled (`AppSettings.showOverlay`), via `ChangeNotifierProvider` + `context.watch<MapHttpProvider>()`. Startup also registers `MapHttpProvider()..fetch()` in `main.dart`.
- **Colours:** Points and numeric labels follow the [**European Air Quality Index**](https://airindex.eea.europa.eu/) µg/m³ bands (hourly classes), matching the overlays described on [Luftdaten.at Datahub](https://datahub.luftdaten.at). See `Dimension.getColor` in [`lib/core/domain/dimensions.dart`](../lib/core/domain/dimensions.dart) (PM4 uses the PM2.5‑sized bins).

### Per-station history (CSV)

- **Class:** `SingleStationHttpProvider`
- **Request:** `GET` `https://api.luftdaten.at/v1/station/historical` with query params:
  - `station_ids=<device_id>` — Luftdaten.at station id (e.g. ids ending in `SC` denote sensor.community–oriented stations in the ecosystem; the app does **not** call sensor.community APIs directly for map data).
  - `precision` — `all` for the first series (last day), `hour` for week and month windows.
  - `output_format=csv`
  - `start=<ISO8601 UTC>`
- **Response:** CSV with header **`device,time_measured,dimension,dimension_name,value`** (5 columns). `SingleStationHttpProvider` reads **`dimension` from column 3 (0-based index 2)** and the **numeric measurement from the last column**, which also matches legacy **4-column** CSV without `dimension_name` as long as `dimension_name` does not contain commas. Dimension IDs map to `Dimension` in `lib/core/domain/dimensions.dart`; charts aggregate timestamps into `DataItem` rows (PM1/PM2.5/PM10 when those dimensions exist for that time).
- **Consumers:** Dashboard station tiles, station detail / chart flows (`dashboard_station_tile.dart`, `station_details_page.dart`, `map_page.dart`).

### Map overlay and “sensor.community” wording

In settings, **“Stationäre Messstationen anzeigen”** uses copy that mentions sensor.community (`AppSettings.I.showOverlay`). The **network source for those markers is still** `api.luftdaten.at` via `MapHttpProvider`. The API aggregates the broader citizen-sensor landscape; the app does not implement a separate REST client for `sensor.community` map tiles or APIs.

---

## Air Station BLE (CircuitPython firmware)

Source of truth: [Luftdaten firmware `docs/ble-characteristics.md`](https://github.com/luftdaten-at/firmware/blob/main/docs/ble-characteristics.md).

- **GATT**: service `0931b4b5-2917-4a8d-9e72-23103c09ac29`; Air Station TLV read/write uses command byte **`0x06`** (`SET_AIR_STATION_CONFIGURATION`). Implementation: `BleControllerV2.readAirStationConfiguration` / `sendAirStationConfig` and `AirStationConfig` TLV encode/decode (`lib/features/devices/data/air_station_config.dart`). Large MQTT payloads may be emitted as multiple `{0x06, … TLV…}` BLE writes (**chunking** helper `AirStationBleHomeAssistantDefaults.chunkSetAirStationConfiguration`, applied in `BleControllerV2.sendAirStationConfig`).
- **MQTT / Home Assistant TLV flags** (`9…17`; companion doc [`companion-app-mqtt-ble.md`](https://github.com/luftdaten-at/firmware/blob/main/docs/companion-app-mqtt-ble.md), HA notes [`mqtt-home-assistant.md`](https://github.com/luftdaten-at/firmware/blob/main/docs/mqtt-home-assistant.md)):
  - **`9`** → `MQTT_ENABLED` (int32 `0|1`)
  - **`10`** → `MQTT_BROKER` (UTF‑8 host/IP)
  - **`11`** → `MQTT_PORT` (int32, e.g. `1883` / `8883`)
  - **`12`** → `MQTT_USE_TLS` (int32 `0|1`)
  - **`13`** → `MQTT_USERNAME` (UTF‑8 optional)
  - **`14`** → `MQTT_PASSWORD` (**write-only TLV**; omitted on read‑back characteristic)
  - **`15`** → `MQTT_DISCOVERY_PREFIX` (UTF‑8; firmware HA default **`homeassistant`**)
  - **`16`** → `MQTT_DEVICE_NAME` (UTF‑8 optional)
  - **`17`** → `MQTT_CERTIFICATE_PATH` (UTF‑8 optional PEM path on device; empty → firmware HTTPS CA bundle)
- **Station TLV flags (strings / ints)** also used elsewhere in the companion app:
  - **`18`** → `TZ` (IANA timezone, e.g. `Europe/Vienna`)
  - **`19`** → `LOG_LEVEL` (`DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL`, per firmware)
  - **`20`** → `api_key` (Datahub/API token; mirrored on read from the station where supported)
- **Startup / `startup.toml` flags (int32 `0|1`)** — same TLV layout as other flags after command **`0x06`**: `[flag u8][len u8][value]`, int32 big-endian; `0` → false, non-zero → true. Documented in firmware [`ble-characteristics.md`](https://github.com/luftdaten-at/firmware/blob/main/docs/ble-characteristics.md). These are **one-shot / next-boot** style settings: values written while the station is running **persist for the next reboot**; the firmware doc recommends **disconnecting and rebooting** the station after writing. Reads on `air_station_configuration` reflect the **currently persisted** `0/1` values.

  | Flag | Name | Notes |
  |:---:|:---|:---|
  | **`21`** | `SYNC_RTC_FROM_NTP` | One-shot; applied on **next boot** |
  | **`22`** | `DETECT_MODEL_FROM_SENSORS` | One-shot; **next boot** |
  | **`23`** | `UPLOAD_SD_LOG_TO_DATAHUB` | **Sensitive** |
  | **`24`** | `CLEAR_SD_CARD` | **Destructive** |
  | **`25`** | `REFRESH_SENSORS` | One-shot; **next boot** |

  The app sends TLVs **`21…25`** only via **`AirStationConfig.toBytesStartupFlagsOnly()`** (dedicated BLE dialog), not via the full wizard “send entire config” path, so routine Wi‑Fi / location sends do not flip these unexpectedly. Saving from the UI writes **all five** flags with explicit `0` or `1` so the firmware state matches the toggles.

- **App storage**:
  - `TZ`, `LOG_LEVEL`, non-secret MQTT fields, and the five startup-flag mirrors (`21…25` as booleans) persist with `AirStationConfig` JSON in **`SharedPreferences`** (`air_station_config_<bleName>` keys).
  - **`api_key` (TLV `20`)** and **`MQTT_PASSWORD` (TLV `14`)** are stored only in OS secure storage via **`flutter_secure_storage`** (`StationSecretsStore`, keyed by BLE broadcast name — same string as `AirStationConfig.id` / `AirStationConfigWizardController.id`).
- **Write / read‑back UX**: TLV `14` is included only when the user edits the MQTT password UI field; TLV `20` behaves the same in the wizard. After a BLE write (`sendAirStationConfig`), firmware merges TLV subsets; the app optionally **read‑backs** (`readAirStationConfiguration`) and merges non‑secret MQTT fields (**never** hydrating password). Startup flags use the same read‑back + merge into prefs after a successful write. UI entry points include the Air Station wizard (`MQTT / Home Assistant (BLE)`, `Startup (BLE) …`) and the device manager MQTT / startup actions when connected.

---

## Luftdaten.at WordPress (news)

- **URL:** `GET https://luftdaten.at/wp-json/wp/v2/posts?categories=12`
- **Class:** `NewsController` (`lib/features/dashboard/logic/news_controller.dart`)
- **Purpose:** Load posts in category **12** for the dashboard news list. Parses `date_gmt`, `id`, `title.rendered`, `excerpt.rendered`, `link`.
- **Storage:** `GetStorage('news')` for items and `lastRefresh` so only posts newer than the last refresh are appended.

---

## Luftdaten.at Datahub (workshops / campaigns)

Controlled by `AppSettings.I.useStagingServer`:

| Mode | Host |
|------|------|
| Production | `datahub.luftdaten.at` |
| Staging | `staging.datahub.luftdaten.at` |

**Class:** `WorkshopController` (`lib/features/measurements/logic/workshop_controller.dart`)

### Upload trip measurements

- **URL:** `POST https://<host>/api/v1/devices/data/`
- **Headers:** `Content-Type: application/json`
- **Body:** JSON built per measurement point (device id, firmware, model, apikey from BLE when available, workshop id, participant uid, sensor readings, optional GPS). See `_buildWorkshopPayload` and `attemptSendData`.

### Workshop metadata

- **URL:** `GET https://<host>/api/workshop/detail/<id>/` (id lowercased)
- **Method:** `loadWorkshopDetails` — expects HTTP 200 and JSON decoded to `WorkshopConfiguration`.

Errors: `ConnectionError` on transport failure; `InvalidIdError` if status ≠ 200.

---

## Station registration (legacy / dormant code)

The file `lib/core/app/presentation/registration_page.dart` is **entirely wrapped in a block comment** and is **not imported** by the running app. The following is preserved for reference if that flow is re-enabled.

| Intended use | URL / pattern | Notes |
|--------------|---------------|--------|
| Check station | `LDHttpProvider.checkStation(mac)` | Type `LDHttpProvider` is **not** defined or registered in the current codebase (`main.dart` does not register it). |
| Register station | `POST https://dev.luftdaten.at/d/station/register` with JSON body | Called `sendDataWithResponse` in commented code. |

Before shipping any revival of this flow, add the provider implementation, register it in `GetIt`, and replace or confirm the `dev.luftdaten.at` endpoint.

---

## OpenStreetMap map tiles

Raster tiles for `flutter_map`:

- **Template:** `https://tile.openstreetmap.org/{z}/{x}/{y}.png`
- **User-Agent:** `userAgentPackageName: 'at.luftdaten.pmble'` on the map’s `TileLayer` (`map_page.dart`). Registration / marker submaps may use other package names (e.g. `com.pmble.app` in commented registration UI).
- **Attribution:** Settings link to OpenStreetMap copyright (`settings_page.dart`).

`main.dart` registers `FlutterError.onError` / `runZonedGuarded` handlers that **suppress** console noise for common tile load failures (connection reset, etc.) when the message mentions `tile.openstreetmap.org`.

---

## Fonts (Google Fonts)

The app depends on `google_fonts` and preloads `GoogleFonts.nunitoSansTextTheme()` in `main.dart`. That may trigger **runtime fetches** from Google’s font CDN unless fonts are fully cached or bundled; no custom API keys are involved.

---

## In-app browser / launcher only (no app HTTP client)

These URLs are opened with `url_launcher` or shown as links, not as structured API clients:

- `https://luftdaten.at/datenschutz`, `https://luftdaten.at/kontakt`, `https://luftdaten.at/mobile-app/`
- Sensirion PDF info notes (VOC / NOx index) from `settings_page.dart`
- `https://maps.sensor.community`, `https://devices.sensor.community/` (registration / onboarding copy in commented code)

---

## Summary table

| Service | Base / URL | Method | Primary Dart location |
|---------|------------|--------|------------------------|
| Luftdaten API | `api.luftdaten.at` (map: **`/v1/station/current/all`**; per-station history: **`/v1/station/historical`**) | GET | `lib/features/map/logic/http_provider.dart` |
| WordPress | `luftdaten.at/wp-json/...` | GET | `lib/features/dashboard/logic/news_controller.dart` |
| Datahub | `datahub.luftdaten.at` / `staging.datahub.luftdaten.at` | GET, POST | `lib/features/measurements/logic/workshop_controller.dart` |
| OSM tiles | `tile.openstreetmap.org` | GET (tile library) | `map_page.dart`, `map_select_marker.dart`, … |
| Registration (dormant) | `dev.luftdaten.at` | POST (commented) | `registration_page.dart` (commented) |
