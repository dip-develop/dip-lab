---
description: Push the current branch and open a PR (Git Flow)
---
Open a pull request for the current work:

1. Inspect `git status`, `git diff`, `git log --oneline -10` first; stage
   only intended files. Never commit secrets or `.env` files.
2. Commit style: match the repo's existing messages (scope: lowercase
   summary). Split into small logical commits if needed.
3. `git push -u origin <branch>`.
4. Pick the flow base from evidence, never assumption: run `git branch -a`
   first (a fresh clone has no local branches, so remote-only
   `origin/develop` / `origin/main` count). Then set `--base`:
   `develop` for `feature/*`, `bugfix/*` and `chore/*`; `main` for
   `hotfix/*` and `release/*` - see the Git Flow table in `AGENTS.md`.
   When `git branch -a` shows no `develop` at all, the repo is
   single-branch: use `--base main` for every branch type, and never
   create `develop` to satisfy the table. Note that `gh pr create` alone
   defaults to the repo's default branch, which is usually wrong for
   Git Flow. Hotfix and release branches need two PRs, into `main` AND
   `develop`, only when `develop` exists; otherwise the single `main` PR.
5. `gh pr create --base <base from step 4>` with a title matching the main
   change and a body that summarizes what/why and lists a test plan.

Stop after creating the PR and report its URL. Do not merge.

Optional extra PR description notes: $ARGUMENTS
