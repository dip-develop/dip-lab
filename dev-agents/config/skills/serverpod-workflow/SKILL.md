---
name: serverpod-workflow
description: The exact command sequence for changing Serverpod models, endpoints, and running migrations in this project. Use whenever a task touches lib/src/protocol, lib/src/endpoints, or the database schema.
---

# Serverpod change workflow

Follow this order every time - skipping steps is the most common way an
agent leaves a Serverpod project in a broken, half-generated state.

1. Edit the `.yaml` model file(s) under `lib/src/protocol/` (or the
   endpoint Dart file under `lib/src/endpoints/`).
2. Run `serverpod generate` from the project root. Do this immediately
   after every model change, not batched at the end - generated code
   drifting out of sync with hand-written code is the main source of
   confusing compile errors in this stack.
3. If the model change affects the database schema (new/changed/removed
   fields on a `table` model), run `serverpod create-migration`. This is
   allowed automatically. Applying it (`serverpod apply-migrations`) is
   NOT auto-approved - it changes the live database, so it always needs
   an explicit yes from Dmytro.
4. Run `dart analyze` on both the server and client packages before
   calling the change done - Serverpod projects are typically split into
   `<project>_server`, `<project>_client`, `<project>_flutter` (adjust to
   actual package names), and a generated-code mismatch often only shows
   up in one of them.
5. Run relevant tests (`dart test` server-side, `flutter test` client-side).

Never hand-edit anything under `lib/src/generated/` (or the client-side
generated equivalent) - it's overwritten by `serverpod generate` and any
manual edit there will silently disappear.
