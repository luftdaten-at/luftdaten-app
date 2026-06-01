# Internationalization (i18n)

How translations are handled in this app.

## Locales

`LDApp` (`lib/core/app/app.dart`) registers:

- `supportedLocales`: `Locale('de')`, `Locale('en')`
- Standard Flutter localization delegates: Material, Widgets, Cupertino

User locale preference may be read from `SharedPreferences` in `main.dart` and passed into the `I18n` widget as `initialLocale` when set.

## String translation pattern

The project uses **`i18n_extension`** (`package:i18n_extension`):

- Many UI strings use the `.i18n` extension on string literals.
- Per-screen or per-feature translations often live in companion files such as `some_page.i18n.dart` next to `some_page.dart`.

When adding user-visible text:

1. Prefer the same pattern as neighboring widgets (`.i18n` + entries in the matching `*.i18n.dart` file for `de` and `en`).
2. Ensure both supported locales have entries to avoid missing translations at runtime.
3. `main.dart` sets `Translations.missingKeyCallback` / `missingTranslationCallback` to reduce console noise for fallbacks (e.g. regional variants); do not rely on that to skip translations for primary locales.

## Flutter gen-l10n

This app does **not** use `flutter gen-l10n` ARB files as the primary mechanism; it uses `i18n_extension`. If you introduce ARB-based gen-l10n as well, document the workflow here to avoid two conflicting sources of truth.

## Related docs

- [architecture.md](architecture.md) — `LDApp` and `MaterialApp` setup  
