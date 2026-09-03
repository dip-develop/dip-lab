# Docker Compose Lab — Agent Guide

Self-hosted home-lab: 11 Docker Compose services on a single Linux host, orchestrated by `manager.sh`. Each service is a subdirectory with its own `docker-compose.yml`, gitignored `.env`, and `.env.example` template. Pure YAML + shell — no test suite, CI, linter, or codegen. Verify `manager.sh`/compose changes with the global dry-run flag: `./manager.sh -n <command>`.

## Boot Order (matters)

`./manager.sh start` (all services) runs in stages:
1. **databases** — blocking, waits for health checks
2. **proxy** — blocking, waits for health checks
3. Everything else — in parallel

- `start` only calls `setup_nets` (creates `web`/`internal`/`database` networks). It does **not** create data dirs or run `<svc>/setup.sh` — run `./manager.sh setup` first for fresh setups.
- `stop` runs in reverse order; databases stop last.
- `restart <svc>` is `docker compose restart` — **no config reload**. After editing a compose file use `./manager.sh update <svc>` (pull/build + `up -d`) or `docker compose up -d` in the service dir.

## Key Commands

| Command | Description |
|---------|-------------|
| `./manager.sh setup` | Create Docker networks + data dirs; runs `<svc>/setup.sh` when present |
| `./manager.sh start [svc]` | Start all (db→proxy→rest) or one service |
| `./manager.sh stop [svc]` | Stop all (databases last) or one service |
| `./manager.sh restart [svc]` | Restart all or one service |
| `./manager.sh update [svc]` | Pull/rebuild images then recreate containers |
| `./manager.sh update-all [--filter <regex>] [--no-recreate] [--prune] [--no-backup]` | Bulk-update enabled services: parallel pulls, digest checks, recreate only changed images, honors boot order, optional preflight backup |
| `./manager.sh build <svc>` | Build service image |
| `./manager.sh logs <svc> [--tail N]` | Follow service logs |
| `./manager.sh status` | Show container status for enabled services |
| `./manager.sh exec <svc> <cmd>` | Run command in service container |
| `./manager.sh perm` | Fix UID/GID ownership on data dirs |
| `./manager.sh profile list` | List available profiles |
| `./manager.sh profile show` | Show current/active disabled-service state |
| `./manager.sh profile <name>` | Apply a named profile from `.profiles/` |
| `./manager.sh profile enable <svc>` | Remove a service from `.disabled_services` |
| `./manager.sh profile disable <svc>` | Add a service to `.disabled_services` |
| `./manager.sh backup [dir]` | Backup data dirs to `backups/diplab-backup-<timestamp>.tar.gz` (gitignored) |
| `./manager.sh restore <file>` | Restore data dirs from backup (**overwrites data dirs** — stop services first; prompts for confirmation) |
| `./manager.sh -n start` | Dry-run: show what would happen (`-n`/`--dry-run` is global) |
| `./manager.sh clean` | Prune unused Docker volumes/networks |
| `./manager.sh stop-all` | `docker stop` every running container |
| `./manager.sh full-cleanup` | Nuke containers, images, volumes, networks |

Examples: `./manager.sh update-all --filter '^auto|cloud$'` (regex is unanchored — use `^`/`$` to match whole service names), `--no-recreate` (pull only), `--no-backup`.

## Services & Profiles

Services are exactly the dirs in `SERVICES_ALL` in `manager.sh`: `databases`, `proxy`, `monitoring`, `passwords`, `containers`, `cloud`, `docs`, `automation`, `gallery`, `ai-agent`, `dev-agents`. Not every directory is a service — `llm/` is data-only and `networks.yml` is unused (networks live in `manager.sh`).

- **`.disabled_services`** (project root, gitignored) — one service per line; comments/blank lines ignored. Disabled services can still be targeted explicitly: `./manager.sh start <svc>`.
- `./manager.sh profile <name>` **overwrites** `.disabled_services` with a copy of `.profiles/<name>` (not a merge).
- Available profiles:
  - `core` — infrastructure only: `databases` + `proxy` + `containers`
  - `default` — everyday stack; disables `monitoring` and `automation`, includes `dev-agents`
  - `dev` — disables `monitoring`, `cloud`, `docs`, `gallery`
  - `media` — disables `passwords` and `ai-agent`
  - `no-ai` — disables `ai-agent` and `dev-agents`
  - `full` — all services enabled (empty file)

## Conventions

- Every service: `security_opt: no-new-privileges:true`, `deploy.resources.limits`, health checks, non-root user with explicit UID/GID where possible (known gaps: `proxy` has no resource limits, `cloud` has no healthchecks, `dev-agents` intentionally omits `no-new-privileges` (passwordless `sudo` for package installs)).
- Data persisted in `<svc>/data/` (gitignored).
- Networks: `web` (reverse proxy, ports 80/443 externally) · `internal` (all app services) · `database` (DBs only). Services needing DB access attach to both `internal` and `database`. The `monitoring` network is defined inline in `monitoring/docker-compose.yml`, not by `setup_nets`.
- Optional per-service files: `setup.sh` (run by `setup`), `entrypoint.sh`, `Dockerfile`.
- `.env.example` files are templates: copy to `.env` and fill before first start.
- Shell autocomplete: `source completions.bash`.

## Secrets & Environment

- Each container loads **only its own** `<dir>/.env` via `env_file`. Never commit `.env` files.
- Shared credentials (DB passwords, etc.) must be kept identical across all service `.env` files (e.g. `MYSQL_PASSWORD` in both `databases/.env` and `cloud/.env`).
- Init SQL uses `__TOKEN__` placeholders (e.g. `__MYSQL_CLOUD_PASSWORD__`, `__TEST_MYSQL_USER__`), substituted by `databases/entrypoint.sh` from `databases/.env` at container start.

## Database Initialization

- `databases/init.sql` + `databases/mysql-init.sql` create application databases/extensions on first container start.
- Test users/databases are created conditionally via `TEST_*` env vars from `databases/.env` (defaults: user `dev_test`, DB `dev_test_main`, `TEST_REDIS_DB=15`).
- Postgres/MySQL test grants are scoped to `dev_test_%` databases — they cannot drop or alter production databases. Redis test clients use a dedicated DB index.
- Inside the `dev-agents` workstation, DB access goes through the `db-safe` wrapper (test creds only) — see `dev-agents/AGENTS.md` for container rules (no docker.sock, test-only databases, no pushes to `main`).

## Locally Built Images

`dev-agents` and `docs` have `build:` sections (local tags like `diplab/dev-agents:local`):
- `./manager.sh build <svc>` to build/rebuild.
- `./manager.sh update <svc>` detects `build:` and rebuilds instead of pulling.

## Operational Gotchas

- `update-all` runs a pre-flight data-dir backup before pulling (skip with `--no-backup`). With `-n` it only prints the target list — no pull, recreate, backup, or status table.
- `perm` fixes ownership: postgres/mysql `999:999`, redis `6379:6379`, seafile `8000:8000`, automation `1000:1000`; chmod `600` on `.env` and `proxy/acme.json`. Run after fresh setup.
- Object storage: when `/mnt/object-storage/data` exists, `setup` creates per-service subdirs + Immich `.immich` markers. Local `./data/` fallback mounts are commented out in compose files.
- Traefik: config in `proxy/traefik.yml` + `proxy/dynamic/`; dashboard htpasswd generated by `proxy/entrypoint.sh` at startup; `acme.json` gitignored; `exposedByDefault: false` — Traefik labels are commented out by default (direct-port access pattern).

## Adding a Service

1. Create `<service>/docker-compose.yml` and `.env.example` (optional: `setup.sh`, `Dockerfile`, `entrypoint.sh`)
2. Register the service in `SERVICES_ALL` in `manager.sh`
3. `./manager.sh setup` → `./manager.sh start <service>`
4. To disable it by default, add it to the relevant `.profiles/` files
