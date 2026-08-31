# databases

Shared PostgreSQL, MySQL, and Redis used by every other DIP-Lab service.

| Service | Container | Internal port | Notes |
|---|---|---|---|
| PostgreSQL 16 + pgvector | `postgres` | 5432 | Hosts `gallery`, `automation`, `docs` databases |
| MySQL 8.0 | `mysql` | 3306 | Hosts Seafile (cloud) databases |
| Redis 7 | `redis` | 6379 | Cache + queue backend |

## Networks

- All three are on the external `database` network. Services that need
  them attach to `database` **in addition to** `internal`.
- No host port mappings — only other containers can reach the databases.

## Configuration

- `.env` (template: `.env.example`) — read by all three services.
  Required variables: `POSTGRES_PASSWORD`, `REDIS_PASSWORD`,
  `MYSQL_ROOT_PASSWORD`, `MYSQL_PASSWORD`, plus per-service `*_DB_NAME`
  values used by the consuming services.
- The same `POSTGRES_USER` / `POSTGRES_PASSWORD` / `REDIS_PASSWORD` must
  be replicated in every consuming service's `.env` (see
  `../AGENTS.md` → "Secrets & env").
- Test credentials (`TEST_POSTGRES_*`, `TEST_MYSQL_*`, `TEST_REDIS_*`)
  are optional. If set, the databases init scripts create a `dev_test`
  user with grants limited to `dev_test_*` databases. The
  `../dev-agents/` container uses these creds; mirroring them into
  `dev-agents/.env` enables isolated test runs. See
  `../dev-agents/README.md` → "Database isolation" for details.

## Initialization

- `init.sql` (mounted into PostgreSQL) creates `gallery`, `automation`,
  `docs` databases and enables the `pgvector` extension. It also
  creates the test user (`dev_test`) and a pre-named `dev_test_main`
  database when `TEST_POSTGRES_*` env vars are set.
- `mysql-init.sql` (mounted into MySQL) creates the `cloud` user and
  grants on the Seafile databases, plus the test user (`dev_test`)
  with grants only on `dev_test_*` databases when `TEST_MYSQL_*`
  env vars are set.
- `entrypoint.sh` (mounted into MySQL) substitutes real passwords from
  `.env` into the `__MYSQL_*_PASSWORD__` / `__TEST_MYSQL_*__`
  placeholders in `mysql-init.sql` before MySQL's own entrypoint runs.
  This keeps real passwords out of the committed SQL file.
- `postgres-entrypoint.sh` (mounted into PostgreSQL) does the same
  for `${TEST_POSTGRES_*}` placeholders in `init.sql` (the official
  Postgres image is minimal and lacks `envsubst`, so this wrapper
  uses `sed` for the substitution).

## PostgreSQL tuning

Tuning is applied via the `command:` block in
`docker-compose.yml` (no separate `postgres.conf` is mounted):

```
max_connections=200
shared_buffers=2GB
```

## MySQL tuning

Applied via `command:` in `docker-compose.yml`:

```
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci
max_connections=200
```

## Redis tuning

Applied via `command:` in `docker-compose.yml`:

```
maxmemory 512mb
maxmemory-policy allkeys-lru
RDB snapshots only (no AOF)
```

## First-start caveat

`mysql-init.sql` only runs on a fresh `databases/data/mysql` volume.
Changing `MYSQL_CLOUD_PASSWORD` or `MYSQL_ROOT_PASSWORD` in `.env` after
first start does NOT update the existing users — drop the volume and
re-initialize (and re-initialize Seafile too, since it stores its data
in MySQL). The same applies to the test user: changing
`TEST_MYSQL_PASSWORD` after first start does not retroactively update
it.

`init.sql` only runs on a fresh `databases/data/postgres` volume.
The same caveat applies to `POSTGRES_PASSWORD`, the per-service
`POSTGRES_DB`, and `TEST_POSTGRES_PASSWORD`.

The Redis test DB index (`TEST_REDIS_DB`) does not need a first-start
cycle - it is selected on every connection.
