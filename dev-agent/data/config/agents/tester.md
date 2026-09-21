---
description: Runs test/lint/build commands and reports results. Use after edits.
mode: subagent
model: opencode-go/mimo-v2.5
hidden: true
permissions:
  - action: edit
    resource: "*"
    effect: deny
  - action: subagent
    resource: "*"
    effect: deny
  # webfetch accepts only a flat action, not patterns.
  - action: webfetch
    resource: "*"
    effect: allow
  - action: shell
    resource: "*"
    effect: ask
  - action: shell
    resource: "grep *"
    effect: allow
  - action: shell
    resource: "rg *"
    effect: allow
  - action: shell
    resource: "head *"
    effect: allow
  - action: shell
    resource: "xargs *"
    effect: allow
  - action: shell
    resource: "tail *"
    effect: allow
  - action: shell
    resource: "less *"
    effect: allow
  - action: shell
    resource: "file *"
    effect: allow
  - action: shell
    resource: "stat *"
    effect: allow
  - action: shell
    resource: "ls"
    effect: allow
  - action: shell
    resource: "ls *"
    effect: allow
  - action: shell
    resource: "cat *"
    effect: allow
  - action: shell
    resource: "diff *"
    effect: allow
  - action: shell
    resource: "find *"
    effect: allow
  - action: shell
    resource: "sort *"
    effect: allow
  - action: shell
    resource: "tree *"
    effect: allow
  - action: shell
    resource: "uniq *"
    effect: allow
  - action: shell
    resource: "sleep"
    effect: allow
  - action: shell
    resource: "sleep *"
    effect: allow
  - action: shell
    resource: "wc *"
    effect: allow
  - action: shell
    resource: "cd"
    effect: allow
  - action: shell
    resource: "cd *"
    effect: allow
  - action: shell
    resource: "cut *"
    effect: allow
  - action: shell
    resource: "tr *"
    effect: allow
  - action: shell
    resource: "jq *"
    effect: allow
  - action: shell
    resource: "basename *"
    effect: allow
  - action: shell
    resource: "dirname *"
    effect: allow
  - action: shell
    resource: "realpath *"
    effect: allow
  - action: shell
    resource: "test *"
    effect: allow
  - action: shell
    resource: "git status*"
    effect: allow
  - action: shell
    resource: "git diff*"
    effect: allow
  - action: shell
    resource: "git log*"
    effect: allow
  - action: shell
    resource: "git rev-parse*"
    effect: allow
  - action: shell
    resource: "git branch"
    effect: allow
  - action: shell
    resource: "git branch *"
    effect: allow
  # Read-only stash inspection (failing tests vs uncommitted WIP);
  # push/pop/apply/drop mutate the tree and stay at ask.
  - action: shell
    resource: "git stash list*"
    effect: allow
  - action: shell
    resource: "git stash show*"
    effect: allow
  - action: shell
    resource: "git ls-files*"
    effect: allow
  - action: shell
    resource: "git config --get*"
    effect: allow
  - action: shell
    resource: "dart analyze*"
    effect: allow
  - action: shell
    resource: "dart format*"
    effect: allow
  - action: shell
    resource: "dart test*"
    effect: allow
  - action: shell
    resource: "dart pub get*"
    effect: allow
  - action: shell
    resource: "dart pub upgrade*"
    effect: allow
  - action: shell
    resource: "flutter test*"
    effect: allow
  - action: shell
    resource: "flutter analyze*"
    effect: allow
  - action: shell
    resource: "flutter pub *"
    effect: allow
  - action: shell
    resource: "flutter --version*"
    effect: allow
  - action: shell
    resource: "serverpod generate*"
    effect: allow
  - action: shell
    resource: "serverpod analyze*"
    effect: allow
  - action: shell
    resource: "flutter doctor*"
    effect: allow
  - action: shell
    resource: "flutter devices*"
    effect: allow
  # The body instructs jaspr checks, so the permission must exist too.
  - action: shell
    resource: "jaspr build*"
    effect: allow
  # Log markers and no-ops: compound lines are fragment-checked, so
  # "|| true" and echo separators need allows too.
  - action: shell
    resource: "echo *"
    effect: allow
  - action: shell
    resource: "printf *"
    effect: allow
  - action: shell
    resource: "true"
    effect: allow
  - action: shell
    resource: "sed *"
    effect: allow
  - action: shell
    resource: "which *"
    effect: allow
  # AGENTS.md "Testing expectations": DB-backed tests run against
  # dev_test_* databases with the TEST_* creds. Enforcement is the
  # container's db-safe wrapper (symlinked over these names on PATH)
  # plus server-side grants -- not these globs.
  - action: shell
    resource: "psql *"
    effect: allow
  - action: shell
    resource: "mysql *"
    effect: allow
  - action: shell
    resource: "mariadb *"
    effect: allow
  - action: shell
    resource: "redis-cli *"
    effect: allow
  # Smoke-run an entrypoint / reproduce a failure; CI-equivalent build
  # (the role covers "test/lint/build").
  - action: shell
    resource: "dart run *"
    effect: allow
  - action: shell
    resource: "flutter build *"
    effect: allow
  # env only as a wrapper around already-allowed tools (never "env *":
  # it overrides every anchored deny via last-match-wins).
  - action: shell
    resource: "env * dart *"
    effect: allow
  - action: shell
    resource: "env * flutter *"
    effect: allow
  - action: shell
    resource: "env * serverpod *"
    effect: allow
  - action: shell
    resource: "env * jaspr *"
    effect: allow
  # Last-match-wins env-file guards; see the note in opencode.jsonc.
  - action: shell
    resource: "cat *.env*"
    effect: deny
  - action: shell
    resource: "head *.env*"
    effect: deny
  - action: shell
    resource: "tail *.env*"
    effect: deny
  - action: shell
    resource: "less *.env*"
    effect: deny
  - action: shell
    resource: "sed *.env*"
    effect: deny
  - action: shell
    resource: "rg *.env*"
    effect: deny
  - action: shell
    resource: "grep *.env*"
    effect: deny
---

You are the tester subagent.

Job: after a batch of edits, run project test/lint/build commands and report results.

- Detect project type: dart test, flutter test, dart analyze, dart format --set-exit-if-changed, jaspr, serverpod checks.
- Run commands via bash, capture output.
- Summarize pass/fail, failures with file:line, and suggest fixes.
- If a failure stems from unfamiliar package behavior, check its docs first (MCP doc tools, README/examples) before reading its sources under ~/.pub-cache.
- Do not edit code unless explicitly asked — only verify.
