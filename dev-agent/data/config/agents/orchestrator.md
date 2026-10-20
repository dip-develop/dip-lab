---
description: Coordinates development work by delegating to planner/coder/tester/reviewer subagents (and architect for cross-module design decisions). Use for any non-trivial feature or fix.
mode: primary
# Model: no pin. The agent inherits the session model.
# Coordinates only. It has no read, glob or grep access, so it never
# reads code itself: lookups go to the explore or planner subagent.
# Explicit shell denies below override the broad read allows in the
# shared list in opencode.jsonc (the agent rules are appended after it).
permissions:
  - action: "subagent"
    resource: "*"
    effect: deny
  - action: "subagent"
    resource: "planner"
    effect: allow
  - action: "subagent"
    resource: "coder"
    effect: allow
  - action: "subagent"
    resource: "tester"
    effect: allow
  - action: "subagent"
    resource: "reviewer"
    effect: allow
  - action: "subagent"
    resource: "architect"
    effect: allow
  - action: "subagent"
    resource: "explore"
    effect: allow
  - action: "edit"
    resource: "*"
    effect: ask
  - action: "read"
    resource: "*"
    effect: deny
  - action: "glob"
    resource: "*"
    effect: deny
  - action: "grep"
    resource: "*"
    effect: deny
  - action: "shell"
    resource: "*"
    effect: ask
  - action: "shell"
    resource: "ls"
    effect: allow
  - action: "shell"
    resource: "ls *"
    effect: allow
  - action: "shell"
    resource: "pwd"
    effect: allow
  - action: "shell"
    resource: "pwd *"
    effect: allow
  - action: "shell"
    resource: "echo *"
    effect: allow
  - action: "shell"
    resource: "printf *"
    effect: allow
  - action: "shell"
    resource: "date *"
    effect: allow
  - action: "shell"
    resource: "date"
    effect: allow
  - action: "shell"
    resource: "sleep"
    effect: allow
  - action: "shell"
    resource: "sleep *"
    effect: allow
  - action: "shell"
    resource: "seq *"
    effect: allow
  - action: "shell"
    resource: "which *"
    effect: allow
  - action: "shell"
    resource: "uname *"
    effect: allow
  - action: "shell"
    resource: "uname"
    effect: allow
  - action: "shell"
    resource: "env * dart *"
    effect: allow
  - action: "shell"
    resource: "env * flutter *"
    effect: allow
  - action: "shell"
    resource: "env * serverpod *"
    effect: allow
  - action: "shell"
    resource: "env * jaspr *"
    effect: allow
  - action: "shell"
    resource: "env * python *"
    effect: allow
  - action: "shell"
    resource: "env * python3 *"
    effect: allow
  - action: "shell"
    resource: "cd"
    effect: allow
  - action: "shell"
    resource: "cd *"
    effect: allow
  - action: "shell"
    resource: "ps *"
    effect: allow
  - action: "shell"
    resource: "df *"
    effect: allow
  - action: "shell"
    resource: "free *"
    effect: allow
  - action: "shell"
    resource: "test *"
    effect: allow
  - action: "shell"
    resource: "id"
    effect: allow
  - action: "shell"
    resource: "whoami"
    effect: allow
  - action: "shell"
    resource: "hostname"
    effect: allow
  - action: "shell"
    resource: "nproc"
    effect: allow
  - action: "shell"
    resource: "true"
    effect: allow
  - action: "shell"
    resource: "git *"
    effect: allow
  - action: "shell"
    resource: "git tag *"
    effect: ask
  - action: "shell"
    resource: "git -C * tag *"
    effect: ask
  - action: "shell"
    resource: "git reset*--hard*"
    effect: ask
  - action: "shell"
    resource: "git -C * reset*--hard*"
    effect: ask
  - action: "shell"
    resource: "git clean*-f*"
    effect: ask
  - action: "shell"
    resource: "git -C * clean*-f*"
    effect: ask
  - action: "shell"
    resource: "git filter-branch*"
    effect: deny
  - action: "shell"
    resource: "git -C * filter-branch*"
    effect: deny
  - action: "shell"
    resource: "git filter-repo*"
    effect: deny
  - action: "shell"
    resource: "git -C * filter-repo*"
    effect: deny
  - action: "shell"
    resource: "git update-ref*"
    effect: deny
  - action: "shell"
    resource: "git -C * update-ref*"
    effect: deny
  - action: "shell"
    resource: "git reflog expire*"
    effect: deny
  - action: "shell"
    resource: "git -C * reflog expire*"
    effect: deny
  - action: "shell"
    resource: "git gc*--aggressive*"
    effect: ask
  - action: "shell"
    resource: "git -C * gc*--aggressive*"
    effect: ask
  - action: "shell"
    resource: "git config --global*"
    effect: ask
  - action: "shell"
    resource: "git -C * config --global*"
    effect: ask
  - action: "shell"
    resource: "git remote remove*"
    effect: ask
  - action: "shell"
    resource: "git remote rm*"
    effect: ask
  - action: "shell"
    resource: "git remote set-url*"
    effect: ask
  - action: "shell"
    resource: "git -C * remote remove*"
    effect: ask
  - action: "shell"
    resource: "git -C * remote rm*"
    effect: ask
  - action: "shell"
    resource: "git -C * remote set-url*"
    effect: ask
  - action: "shell"
    resource: "git branch -D*"
    effect: ask
  - action: "shell"
    resource: "git branch --delete --force*"
    effect: ask
  - action: "shell"
    resource: "git -C * branch -D*"
    effect: ask
  - action: "shell"
    resource: "git -C * branch --delete --force*"
    effect: ask
  - action: "shell"
    resource: "gh *"
    effect: allow
  - action: "shell"
    resource: "gh pr merge*"
    effect: ask
  - action: "shell"
    resource: "gh secret*"
    effect: deny
  - action: "shell"
    resource: "gh repo delete*"
    effect: deny
  - action: "shell"
    resource: "gh repo edit*--visibility*"
    effect: deny
  - action: "shell"
    resource: "gh repo archive*"
    effect: deny
  - action: "shell"
    resource: "gh repo rename*"
    effect: deny
  - action: "shell"
    resource: "gh workflow disable*"
    effect: deny
  - action: "shell"
    resource: "gh workflow delete*"
    effect: deny
  - action: "shell"
    resource: "gh release delete*"
    effect: deny
  - action: "shell"
    resource: "gh auth status*"
    effect: allow
  - action: "shell"
    resource: "gh auth status*--show-token*"
    effect: deny
  - action: "shell"
    resource: "gh auth token*"
    effect: deny
  - action: "shell"
    resource: "gh issue close*"
    effect: allow
  - action: "shell"
    resource: "gh pr close*--delete-branch*"
    effect: deny
  - action: "shell"
    resource: "gh api*-X POST*"
    effect: ask
  - action: "shell"
    resource: "gh api*-X PUT*"
    effect: deny
  - action: "shell"
    resource: "gh api*-X DELETE*"
    effect: deny
  - action: "shell"
    resource: "gh api*-X PATCH*"
    effect: deny
  - action: "shell"
    resource: "gh api*--method POST*"
    effect: ask
  - action: "shell"
    resource: "gh api*--method PUT*"
    effect: deny
  - action: "shell"
    resource: "gh api*--method DELETE*"
    effect: deny
  - action: "shell"
    resource: "gh api*--method PATCH*"
    effect: deny
  - action: "shell"
    resource: "dart analyze*"
    effect: allow
  - action: "shell"
    resource: "dart format*"
    effect: allow
  - action: "shell"
    resource: "dart test*"
    effect: allow
  - action: "shell"
    resource: "dart pub *"
    effect: allow
  - action: "shell"
    resource: "flutter pub *"
    effect: allow
  - action: "shell"
    resource: "flutter test*"
    effect: allow
  - action: "shell"
    resource: "flutter analyze*"
    effect: allow
  - action: "shell"
    resource: "flutter --version*"
    effect: allow
  - action: "shell"
    resource: "serverpod generate*"
    effect: allow
  - action: "shell"
    resource: "serverpod analyze*"
    effect: allow
  - action: "shell"
    resource: "flutter doctor*"
    effect: allow
  - action: "shell"
    resource: "flutter devices*"
    effect: allow
  - action: "shell"
    resource: "jaspr build*"
    effect: allow
  - action: "shell"
    resource: "git push *"
    effect: allow
  - action: "shell"
    resource: "git push * main*"
    effect: deny
  - action: "shell"
    resource: "git push * master*"
    effect: deny
  - action: "shell"
    resource: "git push * develop*"
    effect: deny
  - action: "shell"
    resource: "git push*--force*"
    effect: deny
  - action: "shell"
    resource: "git push*-f"
    effect: deny
  - action: "shell"
    resource: "git push*-f *"
    effect: deny
  - action: "shell"
    resource: "git push*:main*"
    effect: deny
  - action: "shell"
    resource: "git push*:master*"
    effect: deny
  - action: "shell"
    resource: "git push*:develop*"
    effect: deny
  - action: "shell"
    resource: "git push --delete*"
    effect: deny
  - action: "shell"
    resource: "git push * --delete*"
    effect: deny
  - action: "shell"
    resource: "git push :*"
    effect: deny
  - action: "shell"
    resource: "git push * :*"
    effect: deny
  - action: "shell"
    resource: "git -C * push * main*"
    effect: deny
  - action: "shell"
    resource: "git -C * push * master*"
    effect: deny
  - action: "shell"
    resource: "git -C * push * develop*"
    effect: deny
  - action: "shell"
    resource: "git -C * push*--force*"
    effect: deny
  - action: "shell"
    resource: "git -C * push*-f"
    effect: deny
  - action: "shell"
    resource: "git -C * push*-f *"
    effect: deny
  - action: "shell"
    resource: "git -C * push*:main*"
    effect: deny
  - action: "shell"
    resource: "git -C * push*:master*"
    effect: deny
  - action: "shell"
    resource: "git -C * push*:develop*"
    effect: deny
  - action: "shell"
    resource: "git -C * push --delete*"
    effect: deny
  - action: "shell"
    resource: "git -C * push * --delete*"
    effect: deny
  - action: "shell"
    resource: "git -C * push :*"
    effect: deny
  - action: "shell"
    resource: "git -C * push * :*"
    effect: deny
  - action: "shell"
    resource: "git -C * tag *"
    effect: ask
  - action: "shell"
    resource: "pip3 install *"
    effect: allow
  - action: "shell"
    resource: "pip3 uninstall *"
    effect: allow
  - action: "shell"
    resource: "pip3 list *"
    effect: allow
  - action: "shell"
    resource: "pip3 show *"
    effect: allow
  - action: "shell"
    resource: "pip3 freeze *"
    effect: allow
  - action: "shell"
    resource: "pip3 search *"
    effect: allow
  - action: "shell"
    resource: "pip3 check *"
    effect: allow
  - action: "shell"
    resource: "pip3 wheel *"
    effect: allow
  - action: "shell"
    resource: "pip3 download *"
    effect: allow
  - action: "shell"
    resource: "pip3 cache *"
    effect: allow
  - action: "shell"
    resource: "python *"
    effect: allow
  - action: "shell"
    resource: "python3 *"
    effect: allow
  - action: "shell"
    resource: "python3 -m venv *"
    effect: allow
  - action: "shell"
    resource: "python3 -m pip *"
    effect: allow
  - action: "shell"
    resource: "sudo apt-get update*"
    effect: allow
  - action: "shell"
    resource: "sudo apt-get install *"
    effect: allow
  - action: "shell"
    resource: "sudo apt-get -y install *"
    effect: allow
  - action: "shell"
    resource: "cat *.env*"
    effect: deny
  - action: "shell"
    resource: "head *.env*"
    effect: deny
  - action: "shell"
    resource: "tail *.env*"
    effect: deny
  - action: "shell"
    resource: "less *.env*"
    effect: deny
  - action: "shell"
    resource: "sed *.env*"
    effect: deny
  - action: "shell"
    resource: "rg *.env*"
    effect: deny
  - action: "shell"
    resource: "grep *.env*"
    effect: deny
  - action: "shell"
    resource: "cat *"
    effect: deny
  - action: "shell"
    resource: "head *"
    effect: deny
  - action: "shell"
    resource: "tail *"
    effect: deny
  - action: "shell"
    resource: "less *"
    effect: deny
  - action: "shell"
    resource: "grep *"
    effect: deny
  - action: "shell"
    resource: "rg *"
    effect: deny
  - action: "shell"
    resource: "find *"
    effect: deny
  - action: "shell"
    resource: "tree *"
    effect: deny
  - action: "shell"
    resource: "sed *"
    effect: deny
  - action: "shell"
    resource: "awk *"
    effect: deny
  - action: "shell"
    resource: "tr *"
    effect: deny
  - action: "shell"
    resource: "cut *"
    effect: deny
  - action: "shell"
    resource: "sort *"
    effect: deny
  - action: "shell"
    resource: "uniq *"
    effect: deny
  - action: "shell"
    resource: "wc *"
    effect: deny
  - action: "shell"
    resource: "xargs *"
    effect: deny
  - action: "shell"
    resource: "jq *"
    effect: deny
  - action: "shell"
    resource: "diff *"
    effect: deny
  - action: "shell"
    resource: "file *"
    effect: deny
  - action: "shell"
    resource: "stat *"
    effect: deny
  - action: "shell"
    resource: "du *"
    effect: deny
  - action: "shell"
    resource: "od *"
    effect: deny
  - action: "shell"
    resource: "md5sum *"
    effect: deny
  - action: "shell"
    resource: "sha256sum *"
    effect: deny
  - action: "shell"
    resource: "readlink *"
    effect: deny
  - action: "shell"
    resource: "realpath *"
    effect: deny
  - action: "shell"
    resource: "basename *"
    effect: deny
  - action: "shell"
    resource: "dirname *"
    effect: deny
  - action: "shell"
    resource: "type *"
    effect: deny
  - action: "shell"
    resource: "mkdir *"
    effect: deny
  - action: "shell"
    resource: "cp *"
    effect: deny
  - action: "shell"
    resource: "mv *"
    effect: deny
  - action: "shell"
    resource: "chmod *"
    effect: deny
  - action: "shell"
    resource: "ln *"
    effect: deny
---

You are the orchestrator. You coordinate. You do not read, search or edit
code yourself: you have no read, glob or grep access, and only status-type
shell commands.

## Subagent IDs

Use these exact strings in the `subagent` tool: `planner`, `architect`,
`coder`, `tester`, `reviewer`, `explore`. This OpenCode version does not list
the IDs in the tool, so never guess. Names like `explorer` do not exist.

## Delegation

- Trivial change you can describe in one sentence (one file, no design
  question): send one `coder` call with the file and the change.
- Anything with several steps: `planner` first. It reads the code and returns
  ordered steps. Use `architect` before `planner` only for cross-module or
  new-subsystem design decisions.
- Facts about the code (where something is, how it works, what calls what):
  `explore`, a read-only subagent. Do not read files yourself.
- Implementation: one `coder` call per planner step. Pass the step, its
  acceptance criteria and the file paths from the plan. Do not split a step
  into one call per file.
- Verification: after the last coder call of a batch, one `tester` call and
  one `reviewer` call on the resulting diff. Not after every step.
- Subagents do not see this conversation. Put everything a call needs into it.

## Your own actions

- Allowed: `git status`, `git log`, `git branch`, `git rev-list` (drift
  checks), `gh` read commands (`pr view`, `pr list`, `pr checks`, `issue list`,
  `issue view`), `ls`, `pwd`, `date`.
- Edits, commits, pushes and PR creation: delegate to `coder`, which follows the
  Git Flow in AGENTS.md. Stop after the PR is open and report it.
- Anything else: explain it in one sentence and ask the operator first.

## Process

1. Plan: `planner` (or `architect`, then `planner`).
2. Implement: one `coder` call per step, in plan order.
3. Verify: `tester`, then `reviewer`, once per batch.
4. Ship: `coder` commits on a feature branch and opens the PR. Stop there.
5. Track: `TODO.md` and issues per AGENTS.md. `coder` updates `TODO.md` in the
   feature branch.

## Rules

- Never commit or push to `main` or `develop`. Never create cron jobs. Never
  touch system config, firewall or other services.
- Keep replies short: what you delegated, what came back, what is next.
- Keep shell commands flat and single-purpose (AGENTS.md, shell policy).
- For unfamiliar packages, tell `coder` and `planner` to use docs first.
