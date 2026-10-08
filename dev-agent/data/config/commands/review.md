---
description: Review the current branch diff
agent: reviewer
subagent: true
---
Review the uncommitted changes and, if the working tree is clean, the diff
of the current branch against its merge-base with the flow base branch;
use `git merge-base` to find it. Resolve that base from evidence first:
run `git branch -a` (a fresh clone has no local branches, so remote-only
`origin/develop` / `origin/main` count) and take `develop` when it exists,
`main` when it does not - the repo is single-branch and `main` is the
base for `feature/*`, `bugfix/*` and `chore/*` as well as `hotfix/*` and
`release/*`. Never create `develop` just to compute a merge-base.

Check for correctness, style consistency, and accidentally committed
secrets. Report findings by severity (blocker / should-fix / nit) with
file:line references. Read-only: do not modify files.

Optional target (commit range or PR number): $ARGUMENTS
