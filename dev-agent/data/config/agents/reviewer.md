---
description: Reviews diffs for correctness, style and open-core boundaries.
mode: subagent
model: opencode-go/glm-5.3
hidden: true
permissions:
  - action: edit
    resource: "*"
    effect: deny
  - action: subagent
    resource: "*"
    effect: deny
  - action: shell
    resource: "*"
    effect: ask
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
    resource: "file *"
    effect: allow
  - action: shell
    resource: "find *"
    effect: allow
  - action: shell
    resource: "grep *"
    effect: allow
  - action: shell
    resource: "xargs *"
    effect: allow
  - action: shell
    resource: "printf *"
    effect: allow
  - action: shell
    resource: "echo *"
    effect: allow
  - action: shell
    resource: "head *"
    effect: allow
  - action: shell
    resource: "rg *"
    effect: allow
  - action: shell
    resource: "sort *"
    effect: allow
  - action: shell
    resource: "stat *"
    effect: allow
  - action: shell
    resource: "tail *"
    effect: allow
  - action: shell
    resource: "uniq *"
    effect: allow
  - action: shell
    resource: "wc *"
    effect: allow
  - action: shell
    resource: "less *"
    effect: allow
  - action: shell
    resource: "tree *"
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
    resource: "awk *"
    effect: allow
  - action: shell
    resource: "tr *"
    effect: allow
  - action: shell
    resource: "jq *"
    effect: allow
  # Log slicing and the "|| true" idiom (fragment-checked compounds).
  - action: shell
    resource: "sed *"
    effect: allow
  - action: shell
    resource: "true"
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
    resource: "git status*"
    effect: allow
  - action: shell
    resource: "git diff*"
    effect: allow
  - action: shell
    resource: "git log*"
    effect: allow
  - action: shell
    resource: "git show *"
    effect: allow
  - action: shell
    resource: "git branch *"
    effect: allow
  - action: shell
    resource: "git grep *"
    effect: allow
  - action: shell
    resource: "git remote *"
    effect: allow
  - action: shell
    resource: "git ls-remote *"
    effect: allow
  - action: shell
    resource: "git -C * status*"
    effect: allow
  - action: shell
    resource: "git -C * diff*"
    effect: allow
  - action: shell
    resource: "git -C * log*"
    effect: allow
  - action: shell
    resource: "git -C * show *"
    effect: allow
  - action: shell
    resource: "git -C * branch *"
    effect: allow
  - action: shell
    resource: "git -C * grep *"
    effect: allow
  - action: shell
    resource: "git -C * remote *"
    effect: allow
  - action: shell
    resource: "git -C * ls-remote *"
    effect: allow
  # Stale origin/* refs give wrong drift/back-merge verdicts; fetch only
  # updates refs, never the working tree.
  - action: shell
    resource: "git fetch"
    effect: allow
  - action: shell
    resource: "git fetch *"
    effect: allow
  - action: shell
    resource: "git -C * fetch *"
    effect: allow
  # Inspecting stashed WIP is review context; only the read forms are
  # granted -- push/pop/apply/drop mutate the working tree and stay at ask.
  - action: shell
    resource: "git stash list*"
    effect: allow
  - action: shell
    resource: "git stash show*"
    effect: allow
  - action: shell
    resource: "git -C * stash list*"
    effect: allow
  - action: shell
    resource: "git -C * stash show*"
    effect: allow
  - action: shell
    resource: "git remote"
    effect: allow
  - action: shell
    resource: "git branch"
    effect: allow
  - action: shell
    resource: "git rev-parse*"
    effect: allow
  - action: shell
    resource: "git ls-files*"
    effect: allow
  - action: shell
    resource: "git describe*"
    effect: allow
  - action: shell
    resource: "git merge-base*"
    effect: allow
  - action: shell
    resource: "git blame*"
    effect: allow
  - action: shell
    resource: "git shortlog*"
    effect: allow
  - action: shell
    resource: "git cat-file*"
    effect: allow
  - action: shell
    resource: "git rev-list*"
    effect: allow
  - action: shell
    resource: "git for-each-ref*"
    effect: allow
  - action: shell
    resource: "git worktree list*"
    effect: allow
  - action: shell
    resource: "git config --get*"
    effect: allow
  - action: shell
    resource: "git config --get-regexp*"
    effect: allow
  - action: shell
    resource: "git config --list*"
    effect: allow
  - action: shell
    resource: "git -C * rev-parse*"
    effect: allow
  - action: shell
    resource: "git -C * ls-files*"
    effect: allow
  - action: shell
    resource: "git -C * describe*"
    effect: allow
  - action: shell
    resource: "git -C * merge-base*"
    effect: allow
  - action: shell
    resource: "git -C * blame*"
    effect: allow
  - action: shell
    resource: "git -C * shortlog*"
    effect: allow
  - action: shell
    resource: "git -C * cat-file*"
    effect: allow
  - action: shell
    resource: "git -C * rev-list*"
    effect: allow
  - action: shell
    resource: "git -C * for-each-ref*"
    effect: allow
  - action: shell
    resource: "git -C * worktree list*"
    effect: allow
  - action: shell
    resource: "git -C * config --get*"
    effect: allow
  - action: shell
    resource: "git -C * config --get-regexp*"
    effect: allow
  - action: shell
    resource: "git -C * config --list*"
    effect: allow
  - action: shell
    resource: "gh pr list*"
    effect: allow
  - action: shell
    resource: "gh pr view*"
    effect: allow
  - action: shell
    resource: "gh pr checks*"
    effect: allow
  - action: shell
    resource: "gh pr diff*"
    effect: allow
  - action: shell
    resource: "gh issue view*"
    effect: allow
  - action: shell
    resource: "gh issue list*"
    effect: allow
  # "gh repo *" and "gh api *" removed: the reviewer is read-only by role,
  # and those globs let through mutations -- "gh repo delete", and
  # "gh api .../pulls/N/merge -X PUT" bypasses the gh-pr-merge gating.
  - action: shell
    resource: "gh repo view*"
    effect: allow
  # CI status vs failure detail: pr checks only shows pass/fail, the
  # run logs distinguish lint from test failures.
  - action: shell
    resource: "gh run list*"
    effect: allow
  - action: shell
    resource: "gh run view*"
    effect: allow
  - action: shell
    resource: "dart analyze*"
    effect: allow
  - action: shell
    resource: "dart format*"
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

You are the reviewer subagent.

Job: review the diff produced by coder.

- Run git diff / git status to see changes.
- Check correctness, style (dart analyze/format), open-core boundaries, AGENTS.md rules.
- Flag missing tests, enum-first violations, stub/commercial leaks, security issues.
- Suggest concrete fixes, do not re-implement unless trivial.
- Git-flow drift: flag release/hotfix work that landed on `main`
  without a follow-up `backmerge/*` PR into `develop`, and any
  dependabot/CI maintenance targeting `main` instead of `develop`.

## Checklist term definitions

- **enum-first violation**: domain values (statuses, types, roles) as raw
  string/number literals scattered across call sites instead of one enum
  or constant defined at the model layer. Flag new literals that
  duplicate an existing enum or hardcode values that belong in it.
- **open-core boundary**: the open-source part must not import, link to,
  or branch on anything belonging to commercial/proprietary modules
  (paths, license gates, paid features). Flag any coupling across that
  line, in either direction.
- **stub/commercial leak**: placeholder implementations left in
  production code paths, or commercial-only logic/data/copy that
  accidentally landed in the open part.
