# Git Flow policy: branches and PRs

All work follows Git Flow. Long-lived branches: `main` (production,
tagged releases) and `develop` (integration). Nothing lands on either
except through pull requests — the operator merges.

| Branch | Branch from | Open PR into | Example |
|---|---|---|---|
| `feature/<topic>` | `develop` | `develop` | `feature/login-page` |
| `bugfix/<topic>` | `develop` | `develop` | `bugfix/null-avatar` |
| `chore/<topic>` | `develop` | `develop` | `chore/bump-test-deps` (dependency/CI maintenance) |
| `hotfix/<topic>` | `main` | `main` AND `develop` (two PRs) | `hotfix/crash-on-start` |
| `release/<version>` | `develop` | `main` AND `develop` (two PRs) | `release/1.4.0` |
| `backmerge/<version>` | `main` | `develop` | `backmerge/1.4.0` |

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

## Back-merge: `main` into `develop` after every release

`main` must stay a subset of `develop`'s history. Anything that
lands on `main` (release/hotfix merges, GitHub-side fixes) makes
`develop` lag; resolve the drift immediately with a back-merge PR —
never let it accumulate:

1. Cut `backmerge/<version>` from `origin/main`, push it, and open
   `gh pr create --base develop` titled e.g.
   `chore: back-merge main into develop (1.4.0)`. The operator
   merges it. Do not use `--head main` — a `backmerge/*` branch
   keeps the protected-branch rules intact.
2. Before starting new work in a repo, check for missed back-merges:
   `git fetch` then `git rev-list --count develop..origin/main`;
   non-zero with no open back-merge PR → propose one first.
3. Merging release/hotfix PRs into `main` must use merge commits,
   never squash — squashing rewrites `main`'s history and makes
   every later back-merge conflict (operator action).

## Dependabot & CI maintenance

- Dependency updates and CI fixes belong on `develop`. Every repo
  must set `target-branch: develop` on each ecosystem entry in
  `.github/dependabot.yml` — the default is the repo's default
  branch (usually `main`), which is the main drift source.
- Never retarget or rebase an incoming dependency/CI PR onto
  `main`; do that work on `chore/*` branches off `develop`.
- Auto-back-merge on release (GitHub Action on `release: published`
  / push to `main`, opening the `backmerge/*` PR) is recommended —
  but it is operator infrastructure; agents may propose it, never
  install or schedule it themselves.

Never:

- Never commit or push directly to `main` or `develop`; pushes to
  them are hard-denied at the permission layer.
- Never merge into `main`/`develop`, tag releases, delete branches,
  or force-push — release/hotfix merges and tagging are operator
  actions. Back-merges are delivered as PRs, never as local merges
  pushed onward.
- Never open PRs with `main`/`develop` itself as the head — the
  only sanctioned flow toward `develop` is the `backmerge/*` branch
  described above; never branch off another PR branch, always off
  the table's base.

Trade-off: for tiny single-author projects Git Flow is heavier than
GitHub Flow, but this environment standardizes on Git Flow.
