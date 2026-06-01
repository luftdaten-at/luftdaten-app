# Development workflow

Commands and tooling for day-to-day work on this project.

## Prerequisites

- Flutter SDK matching the repo (see `environment.sdk` in [pubspec.yaml](../pubspec.yaml); currently `>=3.4.0 <4.0.0`).
- Xcode (macOS) for iOS, Android SDK for Android.
- Run `flutter doctor` and fix reported issues before debugging device-specific problems.

## Install dependencies

```bash
flutter pub get
```

## Run the app

```bash
flutter run
```

Use `-d <device_id>` to pick a specific device or emulator.

## Static analysis

The analyzer is configured via [analysis_options.yaml](../analysis_options.yaml) (`flutter_lints`).

```bash
dart analyze
```

(`flutter analyze` still works and delegates to the same analyzer.)

## Formatting

Format Dart sources with the Dart SDK formatter:

```bash
dart format .
```

Avoid relying on deprecated `flutter format`; `dart format` is the supported entry point on current toolchains.

## Code generation (JSON)

Some models use `json_serializable` (e.g. `lib/features/measurements/data/sensor_data.dart` with `part 'sensor_data.g.dart'`).

After changing annotated classes, regenerate:

```bash
dart run build_runner build --delete-conflicting-outputs
```

For watch mode during active edits:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

Commit generated `*.g.dart` files when they change.

## Tests

```bash
flutter test
```

See [testing.md](testing.md) for layout and scope.

## Clean builds

```bash
flutter clean
flutter pub get
```

## CI

GitHub Actions workflow [.github/workflows/test.yml](../.github/workflows/test.yml) runs `flutter pub get` and `flutter test` on pushes and pull requests to `main`. Local runs should pass the same command before opening a PR.

Build workflows for Android/iOS also live under `.github/workflows/` (used for release pipelines).

## Useful paths

| Task | Location |
|------|----------|
| App entry / DI registration | `lib/main.dart` |
| Global routes & theme | `lib/core/app/app.dart` |
| Lint rules | `analysis_options.yaml` |
| Dependencies | `pubspec.yaml` |

## Related docs

- [DEBUGGING_IOS.md](DEBUGGING_IOS.md) — Physical iOS debugging  
- [architecture.md](architecture.md) — Where to add new code  
- [contributing.md](contributing.md) — PR expectations  
