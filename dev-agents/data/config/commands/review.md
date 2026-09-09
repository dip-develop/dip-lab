---
description: Review the current branch diff
agent: reviewer
subtask: true
---
Review the uncommitted changes and, if the working tree is clean, the diff
of the current branch against its merge-base with the flow base branch
(`develop` for `feature/*` and `bugfix/*`, `main` for `hotfix/*` and
`release/*`; use `git merge-base` to find it).

Check for correctness, style consistency, and accidentally committed
secrets. Report findings by severity (blocker / should-fix / nit) with
file:line references. Read-only: do not modify files.

Optional target (commit range or PR number): $ARGUMENTS
