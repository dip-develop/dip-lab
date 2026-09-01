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
| API Gateway | `http://gateway:8642` |
| API Gateway health | `http://gateway:8642/health` |
| API Gateway Dashboard | `http://gateway:9119` |
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

## Git workflow

- Always branch from `main` as `agent/<topic>`.
- Small, single-purpose commits with clear messages.
- Do not merge, rebase onto `main`, or force-push.
- Stop after pushing the branch and summarize what's ready for review.
- Pushing to `main` is denied at the permission level. The operator
  reviews and pushes manually.

## Things to never do

- Never edit `.env`, secrets, SSH keys, WireGuard config, or anything
  outside the project working directory mounted at `/home/develop/projects`.
- Never run `docker`, `sudo`, `systemctl`, or firewall commands.
- Never push to `main` or delete branches.
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