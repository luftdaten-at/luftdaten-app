# Testing

How tests are organized and how to run them locally and in CI.

## Running tests

From the repository root:

```bash
flutter test
```

This is the same command used in CI ([.github/workflows/test.yml](../.github/workflows/test.yml)).

## Layout

Tests mirror `lib/` under `test/`:

| Directory | Purpose |
|-----------|---------|
| `test/unit/core/` | Core utilities, domain enums, shared helpers |
| `test/unit/features/<feature>/` | Feature-specific unit tests (`data`, `logic`, …) |
| `test/widget/` | Widget tests (when present) |
| `test/test_helpers/` | Shared test utilities |
| `test/widget_test.dart` | Default Flutter template / smoke tests (if applicable) |

Examples of existing coverage:

- Map HTTP provider behavior (`test/unit/features/map/logic/http_provider_test.dart`)
- Device manager and BLE JSON parsing (`test/unit/features/devices/...`)
- Measurements: trips, sensor data, measurements (`test/unit/features/measurements/...`)
- Dashboard: favorites, news (`test/unit/features/dashboard/...`)

## Conventions

- Prefer **unit tests** for pure logic, parsers, and serialization.
- Use **`mocktail`** (and **`fake_async`** where timing matters) per `pubspec.yaml` dev_dependencies.
- When fixing a bug, add a regression test in the closest `test/unit/...` mirror path.

## Integration / E2E

There is no separate integration_test driver documented in this repo today. If you add `integration_test/`, document the run command here (e.g. `flutter test integration_test/...`).

## Related docs

- [development.md](development.md) — `dart analyze`, formatting, build_runner  
- [architecture.md](architecture.md) — Feature vs core layout  
