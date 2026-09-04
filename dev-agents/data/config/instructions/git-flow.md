# Git Flow policy: branches and PRs

All work follows Git Flow. Long-lived branches: `main` (production,
tagged releases) and `develop` (integration). Nothing lands on either
except through pull requests — the operator merges.

| Branch | Branch from | Open PR into | Example |
|---|---|---|---|
| `feature/<topic>` | `develop` | `develop` | `feature/login-page` |
| `bugfix/<topic>` | `develop` | `develop` | `bugfix/null-avatar` |
| `hotfix/<topic>` | `main` | `main` AND `develop` (two PRs) | `hotfix/crash-on-start` |
| `release/<version>` | `develop` | `main` AND `develop` (two PRs) | `release/1.4.0` |

Workflow:

1. Create the branch from the correct base, e.g.
   `git checkout develop && git checkout -b feature/<topic>`.
2. Commit in small, single-purpose chunks with clear messages.
3. Push the branch (`git push -u origin feature/<topic>`) and open
   the PR with `gh pr create --base develop` — the base MUST match
   the table; `gh pr create` alone defaults to the repo's default
   branch, which is usually wrong.
4. Stop and summarize what is ready for review. The operator
   merges PRs, creates release tags, and pushes `main`/`develop`.

Never:

- Never commit or push directly to `main` or `develop`; pushes to
  them are hard-denied at the permission layer.
- Never merge into `main`/`develop`, tag releases, delete branches,
  or force-push — release/hotfix merges and tagging are operator
  actions.
- Never open PRs from `main`/`develop`, and never branch off
  another PR branch; always branch off the table's base.

Trade-off: for tiny single-author projects Git Flow is heavier than
GitHub Flow, but this environment standardizes on Git Flow.
