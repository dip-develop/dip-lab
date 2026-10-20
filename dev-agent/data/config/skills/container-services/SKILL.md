---
name: container-services
description: Hostnames, ports and test-database rules for the dev container (PostgreSQL, MySQL, Redis test DBs, internal HTTP services). Use when a task needs a database or talks to another service on the internal network.
---

# Container services

Use this skill only when a task actually needs a database or an internal
service. Projects that do not use them can ignore it.

## Test databases

Only `dev_test_*` databases are reachable. Production names are refused by
the `db-safe` wrapper.

| Service    | Host         | Credentials (env vars)                                                |
|------------|--------------|-----------------------------------------------------------------------|
| PostgreSQL | `postgres:5432` | `$TEST_POSTGRES_USER` / `$TEST_POSTGRES_PASSWORD` / `$TEST_POSTGRES_DB` |
| MySQL      | `mysql:3306`    | `$TEST_MYSQL_USER` / `$TEST_MYSQL_PASSWORD` / `$TEST_MYSQL_DB`          |
| Redis      | `redis:6379`    | `$TEST_REDIS_PASSWORD`, DB index `$TEST_REDIS_DB` (default 15)          |

Credentials come from the container environment. `PGPASSWORD`,
`MYSQL_PWD` and `REDISCLI_AUTH` are already exported. Never print them.

```bash
psql -h postgres -U "$TEST_POSTGRES_USER" -d "$TEST_POSTGRES_DB"
mysql -h mysql -u "$TEST_MYSQL_USER" "$TEST_MYSQL_DB"
redis-cli -h redis set dev_test:counter 1
# One database per feature, created and dropped through the test DB:
psql -h postgres -U "$TEST_POSTGRES_USER" -d "$TEST_POSTGRES_DB" -c "CREATE DATABASE dev_test_feature_x;"
psql -h postgres -U "$TEST_POSTGRES_USER" -d "$TEST_POSTGRES_DB" -c "DROP DATABASE dev_test_feature_x;"
```

- Never `DROP`, `TRUNCATE` or `FLUSHDB` a database that is not `dev_test_*`,
  or a Redis index other than `$TEST_REDIS_DB`.
- Never `DELETE` or `UPDATE` production rows. Do not bypass the wrapper
  (`DBSAFE=0`) without operator approval.
- For a clean slate, drop and recreate the test database. Never truncate a
  shared one.
- Drop per-feature databases after the run.

## Internal services

Reach them over HTTP or TCP from inside the container only.

| Service               | URL                                  |
|-----------------------|--------------------------------------|
| Automation (n8n)      | `http://automation:5678` (`/healthz`) |
| Agent gateway         | `http://hermes:8642` (`/health`)      |
| PostgreSQL / MySQL    | `postgres:5432` / `mysql:3306` (test credentials only) |
| Redis                 | `redis:6379` (test index only)        |

Never touch the Docker containers of these services. Docker, systemctl and
firewall commands are operator actions.
