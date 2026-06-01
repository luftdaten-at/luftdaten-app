# App architecture

High-level structure of the Luftdaten.at Flutter app: where code lives, how dependency injection and UI state interact, and how navigation is wired.

## Directory layout

```
lib/
  main.dart              # Entry: bindings init, GetIt registration, runApp
  core/                  # Cross-cutting: app shell, config, DI, widgets, background
    app/                 # LDApp, global pages (home, settings, welcome), logging
    background_services/ # Platform-specific background measurement service
    config/              # AppSettings, env, licenses
    di/                  # get_it instance
    domain/              # Shared enums (e.g. dimensions)
    utils/, widgets/
  features/              # Vertical slices
    dashboard/           # News, favorites, workshop entry, “get app”
    devices/             # BLE, device manager, wizards, debug pages
    map/                 # Map, station HTTP providers, map UI
    measurements/        # Trips, charts, files, workshop upload logic
```

Each feature typically follows:

- `data/` — models, DTOs, small pure types  
- `logic/` — `ChangeNotifier`s, controllers, services used by UI  
- `presentation/` — pages, widgets, routes constants on page classes  

## Dependency injection: GetIt + Provider

- **GetIt** (`lib/core/di/di.dart`): service locator. Long-lived singletons are registered in `main.dart` (e.g. `DeviceManager`, `TripController`, `MapHttpProvider`, `BleController`, `WorkshopController`, …).
- **Provider** (`lib/core/app/app.dart`): exposes a subset of those singletons to the widget tree via `MultiProvider` / `ChangeNotifierProvider.value`, so widgets can `context.watch` / `Provider.of` for notifiers that drive UI rebuilds.

**Convention:** register once in `main.dart`; prefer injecting via `getIt<T>()` in logic, and Provider where the widget tree needs reactive updates.

## Application widget

- **`LDApp`** (`lib/core/app/app.dart`): builds `MaterialApp`, theme (Material 3, `GoogleFonts.nunitoSansTextTheme`), `I18n` wrapper, `supportedLocales` (`de`, `en`), and the global `routes` map.
- **Lifecycle:** `WidgetsBindingObserver` exits the background service when the app is paused and no trip is ongoing (see `didChangeAppLifecycleState`).

## Navigation

- **Named routes** on `MaterialApp.routes` — see `LDApp` for the full map (home `'/'`, `MapPage.route`, `SettingsPage.route`, workshop shortcuts, wizard routes, etc.).
- **Imperative pushes** — Some flows use `Navigator.push` with `MaterialPageRoute` where a named route is not defined.

When adding a top-level screen, prefer a **static `route` constant** on the page widget and register it in `LDApp` for consistency.

## State and async work

- **Trip / measurement flow:** `TripController` coordinates ongoing trips; `BackgroundService` (Android/iOS implementations) keeps work alive according to platform rules.
- **Map data:** `MapHttpProvider` fetches station snapshots; `SingleStationHttpProvider` loads per-station history (see [external-apis.md](external-apis.md)).
- **Workshops:** `WorkshopController` persists workshop config and posts to Datahub (same doc).

## Logging

- **`logger`** (`lib/core/app/logging.dart`): global `Logger` from `package:logger`, custom printer `LdLogger` that also retains events for in-app log UI when enabled.

## Assets

Declared under `flutter: assets:` in `pubspec.yaml` (icons, Lottie, audio, images). New asset directories must be listed there.

## Related docs

- [external-apis.md](external-apis.md) — HTTP backends  
- [bluetooth.md](bluetooth.md) — BLE stack  
- [development.md](development.md) — Running and analyzing the project  
- [testing.md](testing.md) — Test layout  
