# Developer Workstation — Agent Guide

This file is read by opencode when you open a project inside the
developer workstation container. It defines what agents are allowed to do.

## Stack

- Container: Debian Bookworm + Flutter SDK (stable) + Dart + opencode CLI v2
- Build entrypoint: `opencode serve --hostname 0.0.0.0 --port 4096`
- Companion tmux session: `tmux attach -t dev` (started by ENTRYPOINT)
- Container name: `dev-agent` (OpenCode v2 version)

## Database Quick Reference (Always Available)

**Critical database information is included here so it's available in every project.**

### Test Credentials (from dev-agent/.env)
- **PostgreSQL**: `postgres:5432` → USER: `$TEST_POSTGRES_USER`, DB: `dev_test_*`
- **MySQL**: `mysql:3306` → USER: `$TEST_MYSQL_USER`, DB: `dev_test_*`
- **Redis**: `redis:6379` → DB index: `$TEST_REDIS_DB` (default 15)

### Common Commands
```bash
# Connect to test DB
psql -h postgres -U "$TEST_POSTGRES_USER" -d "$TEST_POSTGRES_DB"
mysql -h mysql -u "$TEST_MYSQL_USER" "$TEST_MYSQL_DB"
redis-cli -h redis

# Create feature-specific test DB
psql -h postgres -U "$TEST_POSTGRES_USER" -d "$TEST_POSTGRES_DB" \
    -c "CREATE DATABASE dev_test_feature_name;"

# Drop after tests
psql -h postgres -U "$TEST_POSTGRES_USER" -d "$TEST_POSTGRES_DB" \
    -c "DROP DATABASE dev_test_feature_name;"
```

### Safety Rules
- ✅ **Allowed**: Work with databases `dev_test_*`
- ❌ **Forbidden**: `production`, `app`, `cloud`, `gallery` and other prod databases
- ❌ **Forbidden**: Redis indexes 0-14 (only TEST_REDIS_DB allowed)
- The `db-safe` wrapper enforces these rules automatically

## Network

The container is attached to the `internal` and `database` Docker
networks. From inside the container, services are reachable by
hostname:

| Service | URL (inside this container) |
|---|---|
| Automation (n8n) | `http://automation:5678` |
| n8n health | `http://automation:5678/healthz` |
| Hermes API Gateway | `http://hermes:8642` |
| Hermes API Gateway health | `http://hermes:8642/health` |
| Hermes API Gateway Dashboard | `http://hermes:9119` |
| PostgreSQL (test user only) | `postgres:5432` (use `TEST_POSTGRES_USER` / `TEST_POSTGRES_PASSWORD` from `dev-agent/.env`) |
| MySQL (test user only) | `mysql:3306` (use `TEST_MYSQL_USER` / `TEST_MYSQL_PASSWORD` from `dev-agent/.env`) |
| Redis (test DB index only) | `redis:6379` (use `TEST_REDIS_PASSWORD` and `TEST_REDIS_DB` from `dev-agent/.env`) |

The opencode web UI/API itself is on `http://localhost:4096` (host:
`http://${BIND_IP}:4096`, default `${BIND_IP}=127.0.0.1`). It is protected
by `OPENCODE_SERVER_PASSWORD` from `dev-agent/.env`.

## Database access (test only)

**The container has database access, but it is strictly isolated:**

- You connect as `TEST_POSTGRES_USER` / `TEST_MYSQL_USER` (not the
  prod users). These test users have server-side
  grants ONLY on databases whose name starts with `dev_test_`.
- A bash wrapper (`db-safe`, symlinked to `psql` / `mysql` /
  `mariadb` / `redis-cli` on PATH) refuses to talk to any non-test
  database. Examples that will be rejected:
  - `psql -d production`            → exit 1
  - `psql -d app`                   → exit 1
  - `mysql -D cloud`                → exit 1
  - `redis-cli -n 0`                → exit 1
  - `redis-cli SELECT 2`            → exit 1
- The wrapper can be disabled per-command with `DBSAFE=0 ...` or
  globally by setting `DB_SAFETY_GUARD=false` in `dev-agent/.env`.
  Don't disable it without a reason - the prod creds are NOT
  available inside the container, but the wrapper also protects
  against typo'd DB names that happen to match a prod DB.

### Working with test databases

```bash
# Connect to the pre-created test DB.
psql -h postgres -U "$TEST_POSTGRES_USER" -d "$TEST_POSTGRES_DB"
mysql -h mysql -u "$TEST_MYSQL_USER" "$TEST_MYSQL_DB"
redis-cli -h redis            # uses TEST_REDIS_DB index

# Create a new isolated test DB for one feature under test.
psql -h postgres -U "$TEST_POSTGRES_USER" -d "$TEST_POSTGRES_DB" \
    -c "CREATE DATABASE dev_test_feature_x;"
# ... tests run against dev_test_feature_x ...
# Drop it when done (the test user is the owner, so this works).
psql -h postgres -U "$TEST_POSTGRES_USER" -d "$TEST_POSTGRES_DB" \
    -c "DROP DATABASE dev_test_feature_x;"

# Redis: namespace your keys with `dev_test:` so a future FLUSHDB on
# the test index can never collide with prod keys.
redis-cli SET dev_test:counter 1
```

The `PGPASSWORD`, `MYSQL_PWD`, `REDISCLI_AUTH` env vars are
auto-exported in your shell from the container's `TEST_*_PASSWORD`
values (see `~/.config/dev-agent/env.sh`).

## Docker

- This container runs **without** `docker.sock` and **without**
  `--privileged`. The user inside is not in the `docker` group, so
  `docker` and `docker compose` are not even installed.
- If a task seems to need to build/run containers, say so explicitly and
  the operator will run those steps or grant a scoped exception. Do not
  try to work around the permission denial.

## Git workflow (Git Flow)

Long-lived branches: `main` (production, tagged releases) and `develop`
(integration). Nothing lands on either except through pull requests — the
operator merges.

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

Repos with no `develop` branch (single-branch projects such as
`dip-lab`) use `feature/*` off `main` and `gh pr create --base main`; run
`git branch -a` first rather than assuming the table applies.

### Back-merge: `main` into `develop` after every release

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

### Dependabot & CI maintenance

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

### Git flow — never

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

## Roadmap & TODO

Chat history is not durable. Any state worth keeping outlives the
session.

### Roadmap (long-lived) → GitHub issues

- Larger planned work, known bugs, and improvement ideas go to GitHub
  issues via `gh issue create --repo <owner/repo>`.
- One issue per topic, descriptive title, body with context and
  acceptance criteria. Label with a milestone if the repo uses them.
- Do not reopen a near-duplicate: check `gh issue list` first.
- Orchestrator may file issues; the operator still decides order and
  assignment.

### Working TODO (current) → `TODO.md` in the project root

- `TODO.md` is the short-lived working list for active work.
- Format: one item per line, `- [ ]` unchecked / `- [x]` done, newest
  items at the top. Keep at most ~20 items — archive or move finished
  topics to issues.
- The planner reads `TODO.md` before planning; the orchestrator
  updates it (check off, add follow-ups) as steps complete.
- `TODO.md` changes ride in the feature branch — they land via the
  normal PR, never directly on `develop`.

### Planned work → issue at planning time

- When the planner returns a multi-step plan, the orchestrator
  proposes creating a GitHub issue for it before dispatching coders
  (default: one issue for the plan, steps as `- [ ]` checkboxes in
  the body; per-step issues when they are independently actionable).
  The operator decides whether to file; one-shot drive-by fixes need
  no issue.
- Every PR body for that work references the issue: `Refs #<n>` —
  or `Closes #<n>` ONLY when the PR's base is the repo's default
  branch: GitHub's auto-close keyword is inert for merges into
  non-default branches, so Git Flow (develop-based) repos must close
  explicitly.
- After the operator merges, the orchestrator closes the linked
  issue with a pointer:
  `gh issue close <n> --comment "Done in PR #<m> (<sha>)"`.

### Roadmap — never

- Never keep progress lists only in chat ("I'll remember it").
- Never duplicate the same task in both an issue and `TODO.md`
  without a pointer to the other.
- Never close an issue whose implementing PR has not merged yet
  (`Closes #N` in a develop-based PR does NOT auto-close).

## Scheduled jobs

- Creating a recurring job is an operator action, same as installing the
  auto-back-merge GitHub Action described under *Git workflow* above: agents may
  propose a cron job (what it would run, how often) but must not create
  one themselves. (The `opencode-cron` plugin was removed as non-functional
  under V2.)
- Reason: a recurring job runs unattended against whichever model it's
  configured to use, against that model's own OpenCode Go usage cap
  (5h/week/month tranches -- see opencode.ai/docs/go), with no approval
  step in the loop, unlike a normal ask-gated bash command.

## Things to never do

- Never edit `.env`, secrets, SSH keys, WireGuard config, or anything
  outside the project working directory mounted at `/home/develop/projects`.
- Never run `docker`, `systemctl`, or firewall commands. `sudo` is
  allowed for installing packages/tools inside the container
  (e.g. `sudo apt-get install ...`), never for altering system/network
  config or anything outside the container.
- Never push to `main`/`develop` or delete branches.
- Never touch other services' Docker containers. Only reach them over HTTP/TCP from inside
  the container, as documented in the **Network** table above.
- Never `DROP DATABASE` / `TRUNCATE` / `FLUSHDB` against a
  non-`dev_test_` PostgreSQL/MySQL database, or a non-`TEST_REDIS_DB`
  Redis index. The `db-safe` wrapper enforces this; do not bypass it
  (`DBSAFE=0`) without operator approval.
- Never `DELETE FROM <prod_table>` or `UPDATE` prod data. The test
  users do not have privileges on prod DBs, so the server will
  reject the SQL - but if a future change widens the grant, the
  history here says "do not do this".

## Package research policy

When you need information about a third-party package (anything under
`~/.pub-cache` or another dependency cache), consult documentation
FIRST. Treat reading package sources as a last resort.

Order of preference:

1. MCP doc servers, when available for the ecosystem:
   - `dart` MCP: `pub_dev_search`, `read_package_uris` (README /
     `example/` via `package:` and `package-root:` URIs),
     `rip_grep_packages`.
   - `serverpod` MCP: `ask-docs`, `get-guide`, `list-guides`.
   - `jaspr` MCP: `list_doc_files`, `read_doc_page`.
   (tool names may be prefixed with the server name, e.g. `dart_pub_dev_search`.)
2. The package's README, CHANGELOG, and `example/` directory.
3. Official docs / API reference on pub.dev or the project website.

Only if docs do not answer the question: read sources under
`~/.pub-cache`, surgically — search for the specific symbol or
signature (e.g. with `rg`), do not browse whole files or dump large
source chunks into your output. Cite package + symbol + version.

Rationale: docs match the resolved version and stay current; cached
sources may not, and doc tools are cheaper and more targeted.

## Shell execution policy: keep commands flat

The permission checker matches shell commands fragment by fragment
against the allow/ask/deny rules in `opencode.jsonc` and each agent's
own `permissions:` block. This has one consequence every agent needs
to know, not just the one that happens to spell it out in its own
prompt:

- **Compound commands always fall back to `ask`, in full**, even when
  every individual piece is already allow-listed. Every sub-command in
  a `&&` / `;` / `||` chain must be individually allow-listed AND the
  checker must recognize the line as decomposable — in practice, a
  line starting with a shell keyword (`for`, `while`, `if`) can never
  match anything and always asks.
- Practical effect: `cd myproject && git status` asks for approval
  even though `cd *` and `git status*` are both allowed on their own.
  Prefer separate calls (`cd myproject`, then `git status`) over
  chaining when you want to stay inside the allow-listed path.
- Poll for a slow result (CI, a long build) with repeated simple calls
  — `sleep 45`, then `gh pr view ...` — never a shell loop. A loop
  both falls back to `ask` and won't do what you expect even once
  approved, since each iteration is a fresh, unrelated permission
  check.
- Never put bare `|`, `||`, or `&&` characters inside a quoted regex
  in a shell line the splitter sees (e.g. `grep 'a|b'`). Use separate
  `-e` patterns, or the dedicated grep tool, instead — the splitter
  can't tell a literal pipe inside quotes from a real one.

Keeping commands flat and single-purpose isn't just a style
preference: it's the difference between routine work running
autonomously within the allow-list and every other step stalling on
an avoidable approval round-trip.

## Testing expectations

- Run `dart analyze` and `dart test` (or the project's equivalents) before
  calling a change done. Delegate to the `tester` subagent.
- Use `flutter analyze` / `flutter test` for Flutter projects.
- For projects that need a real database: the
  `tester` subagent should use the test creds documented above. Use
  a per-feature test database (e.g. `dev_test_<feature>`) and drop
  it after the run.
- If a test needs a "clean slate" mid-run, drop and recreate the
  test DB - do not attempt to truncate a shared one.