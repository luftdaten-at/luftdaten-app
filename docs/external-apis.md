# External APIs and network usage

The app uses the [`http`](https://pub.dev/packages/http) package for most programmatic requests. Map-related providers share a common `User-Agent` built in `HttpProvider` (`lib/features/map/logic/http_provider.dart`): `Luftdaten.at/<appVersion> dart:io/<platform> (...)` plus device name from `DeviceInfo`.

---

## Luftdaten.at measurement API

**Base URL:** `https://api.luftdaten.at`

### Current snapshot for map (JSON)

- **Class:** `MapHttpProvider`
- **Request:** `GET` — full URL is fixed in code, including query parameters:
  - Path: `/v1/station/historical`
  - Notable params: `end=current`, `precision=all`, `output_format=json`, `include_location=true`
- **Response:** JSON array of objects parsed by `Measurement.fromJson` (`lib/features/measurements/data/measurement.dart`): `location` (lat, lon, height), `values` (dimension + value), `device` (station id string), `time_measured`.
- **Caching / throttle:** `fetch()` only triggers a network call if the last fetch is older than 5 minutes (or 30 seconds if the list is still empty).
- **Consumers:** Map page (`MapPage` calls `getIt<MapHttpProvider>().fetch()`), station markers and overlays.

### Per-station history (CSV)

- **Class:** `SingleStationHttpProvider`
- **Request:** `GET` `https://api.luftdaten.at/v1/station/historical` with query params:
  - `station_ids=<device_id>` — Luftdaten.at station id (e.g. ids ending in `SC` denote sensor.community–oriented stations in the ecosystem; the app does **not** call sensor.community APIs directly for map data).
  - `precision` — `all` for the first series (last day), `hour` for week and month windows.
  - `output_format=csv`
  - `start=<ISO8601 UTC>`
- **Response:** CSV with header `device,time_measured,dimension,value`; dimensions align with `Dimension` enums in `lib/core/domain/dimensions.dart`.
- **Consumers:** Dashboard station tiles, station detail / chart flows (`dashboard_station_tile.dart`, `station_details_page.dart`, `map_page.dart`).

### Map overlay and “sensor.community” wording

In settings, **“Stationäre Messstationen anzeigen”** uses copy that mentions sensor.community (`AppSettings.I.showOverlay`). The **network source for those markers is still** `api.luftdaten.at` via `MapHttpProvider`. The API aggregates the broader citizen-sensor landscape; the app does not implement a separate REST client for `sensor.community` map tiles or APIs.

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
| Luftdaten API | `api.luftdaten.at` | GET | `lib/features/map/logic/http_provider.dart` |
| WordPress | `luftdaten.at/wp-json/...` | GET | `lib/features/dashboard/logic/news_controller.dart` |
| Datahub | `datahub.luftdaten.at` / `staging.datahub.luftdaten.at` | GET, POST | `lib/features/measurements/logic/workshop_controller.dart` |
| OSM tiles | `tile.openstreetmap.org` | GET (tile library) | `map_page.dart`, `map_select_marker.dart`, … |
| Registration (dormant) | `dev.luftdaten.at` | POST (commented) | `registration_page.dart` (commented) |
