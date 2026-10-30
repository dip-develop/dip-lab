---
name: git-flow
description: Branch, commit, PR and back-merge rules for a repo that uses main alone or main plus develop. Use before any branch, commit, push, PR or back-merge, and for drift checks.
---

# Git flow

## 1. Detect the base branch first

Run this in each repo before branching:

    git ls-remote --heads origin develop

- Output with a line: the repo has `develop`. Use the flow table in section 2.
- No output: the repo is main-only. Branch from `main` and use `--base main` for every PR. Never create `develop` to satisfy the table.
- The command fails (no `origin`, no network): report it and stop. Do not guess a base.

## 2. Flow table (repos with `develop`)

| Branch | Branch from | PR into |
|---|---|---|
| `feature/<topic>`, `bugfix/<topic>`, `chore/<topic>` (deps, CI) | `develop` | `develop` |
| `hotfix/<topic>` | `main` | `main`, then `develop` (two PRs) |
| `release/<version>` | `develop` | `main`, then `develop` (two PRs) |
| `backmerge/<version>` | `main` | `develop` |

## 3. Flow for main-only repos

Branch `feature/<topic>` or `fix/<topic>` from `main`. Open one PR with `--base main`. Releases and hotfixes are also one PR into `main`.

## 4. Steps (both kinds of repo)

1. Branch from the base chosen in section 1 or 2. Commit in small single-purpose commits, matching the repo's commit style. Never stage `.env` files or secrets.
2. `git push -u origin <branch>`.
3. `gh pr create --base <base>`. Always pass `--base`: without it, `gh` targets the default branch, which is often wrong here.
4. PR body: a summary, why, a test plan, and `Refs #<n>` for the tracking issue (see AGENTS.md, Work tracking).
5. Stop after the PR is open and report its URL. Do not merge.

## 5. Drift and back-merge (repos with `develop` only)

After every release, `main` must stay a subset of `develop`. Run `git fetch`, then `git rev-list --count origin/develop..origin/main`. A non-zero count with no open `backmerge/*` PR means a back-merge is owed. Propose `backmerge/<version>` cut from `origin/main` into `develop`, then stop for the operator. Take the version from `git describe --tags --abbrev=0`; with no tag, ask.

Merge releases and hotfixes into `main` with merge commits, never squash. A squash turns every later back-merge into a manual conflict.

## 6. Never

- Commit to, push to, or open a PR from `main` or `develop` directly.
- Merge, tag, delete branches, or force-push. Those are operator actions.
- Create `develop` in a repo that does not have it.
