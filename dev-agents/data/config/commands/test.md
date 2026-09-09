---
description: Run project tests in an isolated dev_test_ database
agent: tester
subtask: true
---
Run the test suite for this project (dart test / flutter test, whichever applies).

Rules that MUST hold (see the container AGENTS.md):
- Use the TEST_* credentials from the environment and the pre-created test
  database when a database is needed.
- For isolated tests create a per-feature database named `dev_test_<feature>`
  and DROP it when done. Never touch non-`dev_test_` databases or non-test
  Redis indexes; do not bypass the db-safe wrapper.
- Report failures with enough context to fix them (failing test names plus
  relevant output). Do not fix application code yourself.

Optional scope (path or test-name filter): $ARGUMENTS
