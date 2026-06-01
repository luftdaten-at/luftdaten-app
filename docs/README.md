# Developer documentation

Extended documentation for the Luftdaten.at Flutter app. The root [README.md](../README.md) covers clone, setup, and basic commands; this folder holds **architecture**, **workflow**, **integrations**, and **platform** notes.

**Why a `docs/` folder?** Flutter and production-app guidance recommend keeping the README focused and moving depth (architecture, APIs, conventions) into versioned docs so it stays maintainable ([app architecture guide](https://docs.flutter.dev/app-architecture/guide)).

## Index

| Document | Contents |
|----------|----------|
| [documentation-practices.md](documentation-practices.md) | Flutter doc best practices and how this repo maps to them. |
| [architecture.md](architecture.md) | Folder layout, GetIt + Provider, navigation, logging. |
| [development.md](development.md) | analyze, format, build_runner, CI, daily commands. |
| [testing.md](testing.md) | Test directory layout, running tests, conventions. |
| [internationalization.md](internationalization.md) | Locales, `i18n_extension`, adding strings. |
| [DEBUGGING_IOS.md](DEBUGGING_IOS.md) | iOS device debugging, LLDB, BLE vs simulator. |
| [contributing.md](contributing.md) | PR checklist, layout, license, privacy notes. |
| [external-apis.md](external-apis.md) | HTTP hosts, endpoints, OSM tiles, integrations. |
| [packages.md](packages.md) | Resolved direct/dev dependency snapshot (pairs with `pubspec.lock`; refresh after upgrades). |
| [bluetooth.md](bluetooth.md) | BLE plugin, permissions, GATT UUIDs, protocol v1/v2. |

## Keeping docs in sync

- **HTTP / backends:** Update [external-apis.md](external-apis.md) when adding or changing hosts, paths, or payloads.
- **Dependencies:** After changing `pubspec.yaml` constraints, run `flutter pub get`, commit `pubspec.lock`, and refresh the tables in [packages.md](packages.md) (same machine/Flutter SDK as CI when possible — e.g. `dart pub deps --json`).
- **BLE:** Update [bluetooth.md](bluetooth.md) when UUIDs, protocol detection, or connection behavior changes.
- **Structure / DI / routes:** Update [architecture.md](architecture.md).
- **Tooling / CI:** Update [development.md](development.md) and, if needed, describe new checks in [contributing.md](contributing.md).
- **New `GetIt` singletons** that perform I/O: mention them in architecture and external-apis as appropriate.

When you add a new major concern (e.g. push notifications, deep linking), add a focused `docs/<topic>.md` and link it here.
