---
name: dart-flutter-conventions
description: House conventions for Dart/Flutter/Serverpod/Jaspr code in this project - style, structure, and patterns to follow before writing or reviewing any Dart file. Use this whenever writing, editing, or reviewing .dart files in this repo.
---

# Dart/Flutter/Serverpod/Jaspr conventions

Fill this in with your actual house style — this is a skeleton. What goes
here directly changes what `coder`/`reviewer` produce, so it's worth being
specific rather than generic ("write clean code").

## Style
- Effective Dart + `dart format` defaults, no manual reformatting arguments
- Null safety: no `!` unless truly provably non-null; prefer early returns
- <your naming conventions, e.g. file naming, folder-by-feature vs by-layer>

## State management (Flutter)
- <e.g. Riverpod / Bloc / plain ChangeNotifier — whichever you actually use>
- <where state lives, how widgets should be split (dumb widgets vs
  containers)>

## Serverpod (backend)
- Endpoints live in `lib/src/endpoints/`, one file per resource
- After changing any model in `lib/src/protocol/`, always run
  `serverpod generate` before considering the change done
- Schema changes go through `serverpod create-migration`, never hand-edited
  SQL - and `serverpod apply-migrations` requires explicit approval (see
  opencode.json permission config), don't try to work around that

## Jaspr (web)
- <component structure conventions, CSS approach, SSR vs CSR usage>

## Testing
- Unit tests next to the code they test, `*_test.dart` suffix
- Widget tests use `flutter test`, web-only behavior via
  `flutter test --platform chrome`
- <coverage expectations, if any>

## Things reviewers should flag
- <your project's common mistakes / footguns worth calling out explicitly>
