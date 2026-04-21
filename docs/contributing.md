# Contributing

Short guide for contributors. The root [README.md](../README.md) has a concise fork/branch/PR outline; this page adds project-specific expectations.

## Before you open a PR

1. **Analyze:** `dart analyze` (or `flutter analyze`) with no new issues in touched files.
2. **Tests:** `flutter test` passes.
3. **Format:** `dart format .` on changed Dart files.
4. **Docs:** If you change HTTP endpoints, BLE UUIDs/protocol, routing, i18n workflow, or CI steps, update the relevant file under [docs/](README.md).

## Code organization

Follow the existing **feature-first** layout (`lib/features/<name>/{data,logic,presentation}`) and put shared pieces in `lib/core/`. See [architecture.md](architecture.md).

## Dependencies

- Prefer published packages on [pub.dev](https://pub.dev); git dependencies (e.g. `bluetooth_enable`) should be rare and justified in the PR description.
- Run `flutter pub get` after editing `pubspec.yaml` and commit `pubspec.lock` when it changes.

## License

The project is licensed under the **AGPL-3.0** (see [LICENSE](../LICENSE)). Contributions are accepted under the same license.

## Security and privacy

- Do not commit API keys, keystores, or App Store provisioning secrets.
- When adding new network calls, document hosts and data flows in [external-apis.md](external-apis.md).
