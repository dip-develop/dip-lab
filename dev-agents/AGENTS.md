# Developer Workstation — Agent Guide

This file is read by opencode when you open a project inside the
developer workstation container. It defines what agents are allowed to do.

## Stack

- Container: Debian Bookworm + Flutter SDK (stable) + Dart + opencode CLI
- Build entrypoint: `opencode serve --hostname 0.0.0.0 --port 4096`
- Companion tmux session: `tmux attach -t dev` (started by ENTRYPOINT)

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
| PostgreSQL (test user only) | `postgres:5432` (use `TEST_POSTGRES_USER` / `TEST_POSTGRES_PASSWORD` from `dev-agents/.env`) |
| MySQL (test user only) | `mysql:3306` (use `TEST_MYSQL_USER` / `TEST_MYSQL_PASSWORD` from `dev-agents/.env`) |
| Redis (test DB index only) | `redis:6379` (use `TEST_REDIS_PASSWORD` and `TEST_REDIS_DB` from `dev-agents/.env`) |

The opencode web UI/API itself is on `http://localhost:4096` (host:
`http://${BIND_IP}:4096`, default `${BIND_IP}=127.0.0.1`). It is protected
by `OPENCODE_SERVER_PASSWORD` from `dev-agents/.env`.

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
  globally by setting `DB_SAFETY_GUARD=false` in `dev-agents/.env`.
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
values (see `~/.config/dev-agents/env.sh`).

## Docker

- This container runs **without** `docker.sock` and **without**
  `--privileged`. The user inside is not in the `docker` group, so
  `docker` and `docker compose` are not even installed.
- If a task seems to need to build/run containers, say so explicitly and
  the operator will run those steps or grant a scoped exception. Do not
  try to work around the permission denial.

## Git workflow (Git Flow)

- The full branch/PR policy is injected into every agent as
  `instructions/git-flow.md` — it is the single source of truth; this
  section only summarizes the consequences.
- Supporting branches (`feature/`, `bugfix/`, `release/`) base on
  `develop`; `hotfix/` bases on `main`. Never commit directly to
  `main`/`develop`.
- Push your branch, open a PR with `gh pr create --base develop`
  (hotfix/release: two PRs — into `main` AND `develop`), then stop
  and summarize what's ready for review.
- Merging into `main`/`develop`, tagging releases, and force-pushes
  are operator actions. Pushes to `main`/`develop` (including refspec
  forms like `HEAD:develop`) are denied at the permission level.
- After a release/hotfix lands on `main`, propose the back-merge PR
  (`backmerge/*` cut from `origin/main`, base `develop`) right away;
  dependency/CI maintenance targets `develop`
  (`target-branch: develop`). Details in `instructions/git-flow.md`.

## Roadmap & TODO

- Long-lived plans and ideas go to GitHub issues; the current working
  list is `TODO.md` in the project root. Details:
  `instructions/roadmap.md` (injected into every agent).
- Multi-step plans get a tracking issue before implementation (the
  operator approves filing); PR bodies link it via `Refs #<n>` and
  the orchestrator closes it after the merge — GitHub's `Closes`
  keyword does not fire for develop-based merges.

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

- Docs before sources: the full policy is injected into every agent as
  `instructions/package-docs-first.md` — MCP doc servers first, then
  README / `example/` / pub.dev docs; `~/.pub-cache` sources only as a
  surgical last resort (search for a symbol, never whole-file browsing).

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