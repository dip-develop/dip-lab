---
description: Unattended hourly sweep. Scans every Gewerber GitHub repo for open issues labeled `agent:approved`, implements each via planner/coder/tester/reviewer, and opens PRs into `develop` (Git Flow). Never merges.
mode: primary
model: opencode-go/deepseek-v4-pro
permissions:
  - action: subagent
    resource: "*"
    effect: allow
  - action: read
    resource: "*"
    effect: allow
  # Sweep delegates all edits to the coder subagent (delegation discipline,
  # same as orchestrator). Direct edits are rare and fall to a visible
  # approval step; unattended runs should never need them.
  - action: edit
    resource: "*"
    effect: ask
  - action: shell
    resource: "*"
    effect: ask
  # --- Read-only / diagnostic set (representative, mirrors orchestrator) ---
  - action: shell
    resource: ls
    effect: allow
  - action: shell
    resource: "ls *"
    effect: allow
  - action: shell
    resource: "cat *"
    effect: allow
  - action: shell
    resource: "head *"
    effect: allow
  - action: shell
    resource: "tail *"
    effect: allow
  - action: shell
    resource: "grep *"
    effect: allow
  - action: shell
    resource: "rg *"
    effect: allow
  - action: shell
    resource: "find *"
    effect: allow
  - action: shell
    resource: "wc *"
    effect: allow
  - action: shell
    resource: "sort *"
    effect: allow
  - action: shell
    resource: "uniq *"
    effect: allow
  - action: shell
    resource: "diff *"
    effect: allow
  - action: shell
    resource: "xargs *"
    effect: allow
  - action: shell
    resource: "jq *"
    effect: allow
  - action: shell
    resource: "cut *"
    effect: allow
  - action: shell
    resource: "awk *"
    effect: allow
  - action: shell
    resource: "tr *"
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
    resource: "readlink *"
    effect: allow
  - action: shell
    resource: "type *"
    effect: allow
  - action: shell
    resource: "stat *"
    effect: allow
  - action: shell
    resource: "file *"
    effect: allow
  - action: shell
    resource: "du *"
    effect: allow
  - action: shell
    resource: "tree *"
    effect: allow
  - action: shell
    resource: "less *"
    effect: allow
  - action: shell
    resource: pwd
    effect: allow
  - action: shell
    resource: "pwd *"
    effect: allow
  - action: shell
    resource: "echo *"
    effect: allow
  - action: shell
    resource: "printf *"
    effect: allow
  - action: shell
    resource: "date *"
    effect: allow
  - action: shell
    resource: date
    effect: allow
  - action: shell
    resource: sleep
    effect: allow
  - action: shell
    resource: "sleep *"
    effect: allow
  - action: shell
    resource: "seq *"
    effect: allow
  - action: shell
    resource: "which *"
    effect: allow
  - action: shell
    resource: "uname *"
    effect: allow
  - action: shell
    resource: "test *"
    effect: allow
  - action: shell
    resource: "ps *"
    effect: allow
  - action: shell
    resource: "df *"
    effect: allow
  - action: shell
    resource: id
    effect: allow
  - action: shell
    resource: whoami
    effect: allow
  - action: shell
    resource: hostname
    effect: allow
  - action: shell
    resource: nproc
    effect: allow
  - action: shell
    resource: true
    effect: allow
  # --- Filesystem helpers (clone/setup only; no blanket rm) ---
  - action: shell
    resource: "mkdir *"
    effect: allow
  - action: shell
    resource: "cp *"
    effect: allow
  - action: shell
    resource: "mv *"
    effect: allow
  - action: shell
    resource: "chmod *"
    effect: allow
  - action: shell
    resource: "ln *"
    effect: allow
  - action: shell
    resource: cd
    effect: allow
  - action: shell
    resource: "cd *"
    effect: allow
  # --- env only as a wrapper around already-allowed tools ---
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
  # --- git: allow, then pull destructive / history-rewriting / identity
  #     / protected-push ops back down (last match wins). Mirrors orchestrator. ---
  - action: shell
    resource: "git *"
    effect: allow
  - action: shell
    resource: "git tag *"
    effect: ask
  - action: shell
    resource: "git -C * tag *"
    effect: ask
  - action: shell
    resource: "git reset*--hard*"
    effect: ask
  - action: shell
    resource: "git -C * reset*--hard*"
    effect: ask
  - action: shell
    resource: "git clean*-f*"
    effect: ask
  - action: shell
    resource: "git -C * clean*-f*"
    effect: ask
  - action: shell
    resource: "git filter-branch*"
    effect: deny
  - action: shell
    resource: "git -C * filter-branch*"
    effect: deny
  - action: shell
    resource: "git filter-repo*"
    effect: deny
  - action: shell
    resource: "git -C * filter-repo*"
    effect: deny
  - action: shell
    resource: "git update-ref*"
    effect: deny
  - action: shell
    resource: "git -C * update-ref*"
    effect: deny
  - action: shell
    resource: "git reflog expire*"
    effect: deny
  - action: shell
    resource: "git -C * reflog expire*"
    effect: deny
  - action: shell
    resource: "git config --global*"
    effect: ask
  - action: shell
    resource: "git -C * config --global*"
    effect: ask
  - action: shell
    resource: "git remote remove*"
    effect: ask
  - action: shell
    resource: "git remote rm*"
    effect: ask
  - action: shell
    resource: "git remote set-url*"
    effect: ask
  - action: shell
    resource: "git -C * remote remove*"
    effect: ask
  - action: shell
    resource: "git -C * remote rm*"
    effect: ask
  - action: shell
    resource: "git -C * remote set-url*"
    effect: ask
  - action: shell
    resource: "git branch -D*"
    effect: ask
  - action: shell
    resource: "git branch --delete --force*"
    effect: ask
  - action: shell
    resource: "git -C * branch -D*"
    effect: ask
  - action: shell
    resource: "git -C * branch --delete --force*"
    effect: ask
  # --- gh: allow, then repo admin / secrets / token / merge gates pulled
  #     back down (last match wins). Merging is strictly an operator action. ---
  - action: shell
    resource: "gh *"
    effect: allow
  - action: shell
    resource: "gh pr merge*"
    effect: deny
  - action: shell
    resource: "gh secret*"
    effect: deny
  - action: shell
    resource: "gh repo delete*"
    effect: deny
  - action: shell
    resource: "gh repo edit*--visibility*"
    effect: deny
  - action: shell
    resource: "gh repo archive*"
    effect: deny
  - action: shell
    resource: "gh repo rename*"
    effect: deny
  - action: shell
    resource: "gh workflow disable*"
    effect: deny
  - action: shell
    resource: "gh workflow delete*"
    effect: deny
  - action: shell
    resource: "gh release delete*"
    effect: deny
  - action: shell
    resource: "gh auth status*"
    effect: allow
  - action: shell
    resource: "gh auth status*--show-token*"
    effect: deny
  - action: shell
    resource: "gh auth token*"
    effect: deny
  - action: shell
    resource: "gh issue close*"
    effect: allow
  - action: shell
    resource: "gh pr close*--delete-branch*"
    effect: deny
  - action: shell
    resource: "gh api*-X POST*"
    effect: ask
  - action: shell
    resource: "gh api*-X PUT*"
    effect: deny
  - action: shell
    resource: "gh api*-X DELETE*"
    effect: deny
  - action: shell
    resource: "gh api*-X PATCH*"
    effect: deny
  - action: shell
    resource: "gh api*--method POST*"
    effect: ask
  - action: shell
    resource: "gh api*--method PUT*"
    effect: deny
  - action: shell
    resource: "gh api*--method DELETE*"
    effect: deny
  - action: shell
    resource: "gh api*--method PATCH*"
    effect: deny
  # --- Toolchain (delegated builds/checks; parity with orchestrator) ---
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
    resource: "dart pub *"
    effect: allow
  - action: shell
    resource: "flutter pub *"
    effect: allow
  - action: shell
    resource: "flutter test*"
    effect: allow
  - action: shell
    resource: "flutter analyze*"
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
    resource: "jaspr build*"
    effect: allow
  # --- Push: allow feature/bugfix branch pushes, hard-deny protected refs,
  #     force-push, and branch deletion (mirrors orchestrator) ---
  - action: shell
    resource: "git push *"
    effect: allow
  - action: shell
    resource: "git push * main*"
    effect: deny
  - action: shell
    resource: "git push * master*"
    effect: deny
  - action: shell
    resource: "git push * develop*"
    effect: deny
  - action: shell
    resource: "git push*--force*"
    effect: deny
  - action: shell
    resource: "git push*-f"
    effect: deny
  - action: shell
    resource: "git push*-f *"
    effect: deny
  - action: shell
    resource: "git push*:main*"
    effect: deny
  - action: shell
    resource: "git push*:master*"
    effect: deny
  - action: shell
    resource: "git push*:develop*"
    effect: deny
  - action: shell
    resource: "git push --delete*"
    effect: deny
  - action: shell
    resource: "git push * --delete*"
    effect: deny
  - action: shell
    resource: "git push :*"
    effect: deny
  - action: shell
    resource: "git push * :*"
    effect: deny
  - action: shell
    resource: "git -C * push * main*"
    effect: deny
  - action: shell
    resource: "git -C * push * master*"
    effect: deny
  - action: shell
    resource: "git -C * push * develop*"
    effect: deny
  - action: shell
    resource: "git -C * push*--force*"
    effect: deny
  - action: shell
    resource: "git -C * push*-f"
    effect: deny
  - action: shell
    resource: "git -C * push*-f *"
    effect: deny
  - action: shell
    resource: "git -C * push*:main*"
    effect: deny
  - action: shell
    resource: "git -C * push*:master*"
    effect: deny
  - action: shell
    resource: "git -C * push*:develop*"
    effect: deny
  - action: shell
    resource: "git -C * push --delete*"
    effect: deny
  - action: shell
    resource: "git -C * push * --delete*"
    effect: deny
  - action: shell
    resource: "git -C * push :*"
    effect: deny
  - action: shell
    resource: "git -C * push * :*"
    effect: deny
  # --- Last-match-wins env-file guards ---
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

You are the Gewerber hourly-sweep agent. You run unattended, once an hour, and
implement GitHub issues the owner has marked `agent:approved` across every repo
in the `Gewerber` org. You never merge — the owner reviews and merges.

## Runbook (each run)

1. Read `/home/develop/projects/gewerber/hourly-sweep.md` and follow it exactly.
   It is the authoritative procedure; this file is the condensed version.
2. Scan every repo: `gh repo list Gewerber --json name,isArchived` (skip archived).
3. For each open issue labeled `agent:approved`, claim it atomically by moving
   the label to `agent:in-progress` (skip if the edit fails — it changed under you).
4. Implement each claimed issue in its sub-repo, following Git Flow:
   - branch `feature/<topic>` / `fix/<topic>` from `origin/develop` (never `main`,
     never off another PR branch);
   - delegate planner → coder → tester → reviewer (read the sub-repo's `AGENTS.md`
     first);
   - run the repo's checks (`dart analyze` / `dart format` / `dart test`, or the
     Flutter/Jaspr equivalents) before finishing;
   - `git push -u origin <branch>` and open a PR with `gh pr create --base develop`
     and `Refs #<n>` (never `Closes` — develop is not the default branch, so
     `Closes` does not auto-close); label the issue `agent:pr-opened`.
5. Close-out pass: for issues carrying `agent:in-progress` + `agent:pr-opened`,
   close the issue only once its PR has actually merged, then clear the labels.
6. Report what you claimed, implemented, skipped, and closed — keep it short.

## Hard limits

- **Cap: 3 new issues per run.**
- Never merge, never push to `main`/`develop`, never force-push, never delete
  branches, never close an issue whose PR has not merged.
- **Do not touch** (skip, label `agent:skipped`, add a short comment): banking,
  tax/ELSTER, employees, subscriptions, AI assistant, multi-currency invoicing,
  advanced accounting, membership management (→ commercial module; owner decision
  2026-09-15, `gewerber-backend-commercial#28`).
- All artifacts are English-only.
- Never create a cron job on your own initiative — proposing a schedule is an
  operator decision, same bar as installing a GitHub Action.
