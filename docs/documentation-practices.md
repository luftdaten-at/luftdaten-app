# Flutter documentation practices (and how this repo applies them)

This page summarizes widely recommended patterns for Flutter project documentation and maps them to the **Luftdaten.at** codebase. It is not a substitute for upstream docs; use it as a checklist when adding features or onboarding contributors.

## What good Flutter documentation usually includes

1. **A strong root README** — Prerequisites, how to run, how to test, where deeper docs live. Keeps the “happy path” one screen away for new contributors.
2. **A `docs/` directory for depth** — README stays short; architecture, integrations, debugging, and conventions move here so they can evolve without cluttering the landing page. This matches common guidance for growing apps (see e.g. [Flutter app architecture](https://docs.flutter.dev/app-architecture/guide)).
3. **Architecture in plain language** — Which layers exist (UI vs state vs data), how navigation works, and where to put new code. Reduces inconsistent folder sprawl.
4. **Integration docs** — External HTTP APIs, BLE, maps, push/background: endpoints, permissions, and the Dart files involved. Update these when behavior changes.
5. **Developer workflow** — Format, analyze, tests, code generation, CI. Copy-pasteable commands lower friction.
6. **Testing strategy** — Where tests live, what is covered, how CI runs them.
7. **Platform-specific notes** — Especially iOS (signing, debugging, Bluetooth background). Android equivalents where non-obvious.
8. **Internationalization** — How strings are translated and where locale is configured.
9. **Living documentation** — Treat doc updates as part of the same PR as code when behavior, URLs, or contracts change. Stale docs cost more than no docs.

## How this repository is organized

| Area | Location |
|------|----------|
| Entry + clone/setup | [README.md](../README.md) |
| App structure, DI, routing | [architecture.md](architecture.md) |
| Day-to-day commands, codegen, CI | [development.md](development.md) |
| Tests | [testing.md](testing.md) |
| Locales / `*.i18n.dart` | [internationalization.md](internationalization.md) |
| iOS debugging | [DEBUGGING_IOS.md](DEBUGGING_IOS.md) |
| HTTP / maps / backends | [external-apis.md](external-apis.md) |
| BLE / GATT | [bluetooth.md](bluetooth.md) |
| Contributing / license reminder | [contributing.md](contributing.md) |

## Alignment with Flutter architecture guidance

The Flutter team recommends **separation of concerns** and **clear UI vs data boundaries** ([recommendations](https://docs.flutter.dev/app-architecture/recommendations)). This app uses a **feature-first** layout under `lib/features/<feature>/{data,logic,presentation}` plus shared `lib/core`, which is a common scalable shape: features own their UI and coordinators; core holds cross-cutting config, widgets, and DI.

You do not need to rename folders to match every diagram in the official guide; you **do** need to keep new code in the same spirit (feature-local vs shared core) and document exceptions.

## Optional extras (not required here)

- **ADRs (Architecture Decision Records)** — Short markdown files in `docs/adr/` when a decision is hard to reverse (e.g. “why GetIt + Provider”).
- **Generated API client docs** — If the app later uses OpenAPI-generated clients, document the generator command and refresh policy.
- **Accessibility / release checklists** — Add when the team formalizes QA gates.

When in doubt, add a short section to the relevant `docs/*.md` file and link it from [README.md](README.md) in this folder.
