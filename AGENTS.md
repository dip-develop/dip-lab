# DIP-Lab — Agent Guide

Docker Compose home lab. 11 services managed through `./manager.sh` (plus
the opt-in `dev-agents` developer workstation container).

## Boot order

`./manager.sh start` starts databases first, then proxy, then all remaining
services in parallel. Health checks wait between stages. `setup_nets` is
called implicitly on every `start`.

## Key commands

| Command | What it does |
|---------|--------------|
| `./manager.sh setup` | Create Docker networks + data dirs; runs `<svc>/setup.sh` |
| `./manager.sh start [svc]` | Start all (db→proxy→rest) or one service |
| `./manager.sh stop [svc]` | Stop all (databases last) or one service |
| `./manager.sh restart [svc]` | Restart all or one service |
| `./manager.sh update [svc]` | `docker compose pull` then recreate |
| `./manager.sh build <svc>` | Build service image |
| `./manager.sh logs <svc> [--tail N]` | Follow service logs |
| `./manager.sh status` | `docker compose ps` for enabled services |
| `./manager.sh exec <svc> <cmd>` | Run command in service container |
| `./manager.sh perm` | Fix UID/GID ownership on data dirs |
| `./manager.sh profile <action>` | Manage disabled-service profiles |
| `./manager.sh backup [dir]` | Backup data dirs to tar.gz |
| `./manager.sh restore <file>` | Restore data dirs from backup |
| `./manager.sh -n start` | Dry-run: show what would happen |
| `./manager.sh clean` | Prune unused Docker volumes/networks |
| `./manager.sh stop-all` | `docker stop` every running container |
| `./manager.sh full-cleanup` | Nuke containers, images, volumes, networks |

## Disabled services & profiles

- **`.disabled_services`** — one service per line in project root (gitignored).
  Explicit targeting still works: `./manager.sh start dev-agents`.
- **`profile` command** — `./manager.sh profile disable dev-agents`,
  `enable dev-agents`, or `./manager.sh profile <name>` to switch profile.
- Built-in profiles (in `.profiles/`, listed in order of how much they
  enable):
  - `core` — foundation only: `databases` + `proxy` + `containers`. No
    app services. Use for first start, or a host that only runs
    infrastructure.
  - `default` — everyday stack: `core` + `passwords` + `ai-agent` +
    `cloud` + `docs` + `gallery`. No monitoring, no automation, no
    dev-agents.
  - `media` — `default` + `monitoring` + `automation` (Prometheus,
    Grafana, Loki, Promtail, cAdvisor, n8n). No dev-agents.
  - `dev` — `default` + `automation` + `dev-agents`. Active
    development without the heavyweight media services.
  - `no-ai` — everything except `ai-agent` and `dev-agents`. Homelab
    without any LLM gateway.
  - `full` — everything enabled, including the opt-in `dev-agents`.
- `dev-agents` is included only in `dev` and `full` profiles. In every
  other profile you must enable it explicitly:
  `./manager.sh profile enable dev-agents`.

## Service directories & images

| Directory | What | Image |
|-----------|------|-------|
| `databases/` | PostgreSQL (pgvector/pg16), MySQL 8.0, Redis 7 | `pgvector/pgvector:pg16`, `mysql:8.0`, `redis:7-alpine` |
| `proxy/` | Traefik v3 | `traefik:v3.7.10` |
| `monitoring/` | Prometheus, Grafana, Loki, Promtail, cAdvisor, node-exporter | `prom/`, `grafana/`, `loki`, `promtail` |
| `passwords/` | Vaultwarden | `vaultwarden/server` |
| `containers/` | Portainer CE | `portainer/portainer-ce` |
| `cloud/` | Seafile + memcached | `seafileltd/seafile-mc:13.0.21` |
| `docs/` | Paperless-ngx + Gotenberg + Tika | Custom Dockerfile (adds Tesseract OCR langs) |
| `automation/` | n8n | `n8nio/n8n` |
| `gallery/` | Immich server + ML | `ghcr.io/immich-app/immich-server:v3` |
| `ai-agent/` | Hermes agent (ports 18789 API, 18790 UI) | `nousresearch/hermes-agent` |
| `dev-agents/` | **Opt-in.** Developer workstation: Flutter + opencode CLI (port 4096) | `diplab/dev-agents:local` (built locally) |

## Networks

- `web` — Traefik, ports 80/443 externally
- `internal` — all app services, port-mapped to `0.0.0.0:{port}`.
  `dev-agents` is also on `internal` so its opencode agents can reach
  `automation`, `ai-agent`, and `postgres` by hostname.
- `database` — databases only (PostgreSQL, MySQL, Redis).
  `dev-agents` is also on `database` but only connects as the
  scoped `dev_test` user / `TEST_REDIS_DB` index — see
  `dev-agents/README.md` → "Database isolation".
- `monitoring` — Prometheus/Grafana/Loki/cAdvisor/node-exporter
  (inline in `monitoring/docker-compose.yml`, not pre-created by
  `setup_nets`)

Services needing DB access attach to both `internal` and `database`.
Others attach only to `internal`.

## Secrets & env

- Every service has `<dir>/.env` (gitignored) and `<dir>/.env.example`.
  Never commit `.env` files.
- Each container loads **only its own** `<dir>/.env` via `env_file`.
  No compose file reads `../databases/.env`.
- **DB credentials must be kept identical** across all service `.env`
  files: `POSTGRES_USER` / `POSTGRES_PASSWORD` / `REDIS_PASSWORD` appear
  in `databases/.env`, `docs/.env`, `gallery/.env`, `automation/.env`,
  etc. Changing a password means editing every copy.
- **`databases/mysql-init.sql`** uses placeholders (`__MYSQL_CLOUD_PASSWORD__`
  / `__MYSQL_ROOT_PASSWORD__`). The actual values are substituted in at
  container start by `databases/entrypoint.sh` from the `databases/.env`
  environment, so real passwords never enter git.
- `databases/init.sql` similarly uses `${TEST_POSTGRES_*}` placeholders,
  substituted by `databases/postgres-entrypoint.sh` (the official
  postgres image lacks `envsubst`, so the wrapper uses `sed`).
- `dev-agents/.env` carries `TEST_*_PASSWORD` values that mirror the
  same `TEST_*_PASSWORD` values from `databases/.env` — the opt-in
  dev workstation only ever talks to databases as the scoped
  `dev_test` user on `dev_test_*` databases / `TEST_REDIS_DB` index.
- `dev-agents/.env` also carries a separate `OPENCODE_SERVER_PASSWORD`
  that protects the always-on `opencode serve` web UI.

## Database init

- `databases/init.sql` creates databases `gallery`, `automation`, `docs`
  and enables `pgvector` extension. If `TEST_POSTGRES_*` env vars are
  set, it also creates a `dev_test` user with grants only on
  `dev_test_*` databases.
- `databases/mysql-init.sql` creates `cloud` user and grants on Seafile
  databases. Passwords are placeholders, substituted by `entrypoint.sh`.
  If `TEST_MYSQL_*` env vars are set, it also creates `dev_test` user
  with grants only on `dev_test_*` databases.
- Redis: no init script. `TEST_REDIS_DB` (default `15`) is a
  dedicated DB index selected by the test client; prod keys live in
  `0`-`14`.
- PostgreSQL: `max_connections=200`, `shared_buffers=2GB`
- MySQL: `utf8mb4` charset, `max_connections=200`
- Redis: password required, `maxmemory 512mb`, eviction policy
  `allkeys-lru`, RDB snapshots only (no AOF)

## Object storage

Gallery's 6 media mounts (upload, thumbs, profile, backups, library,
encoded-video) point **unconditionally** at
`/mnt/object-storage/data/gallery/*` — local `./data/gallery/*` mounts
are commented out. If the mount is absent, Docker creates empty
root-owned dirs.

- docs (Paperless) mounts `/mnt/object-storage/data/docs` as its data root
- automation mounts at `/mnt/object-storage`
- cloud and automation have read-only cross-service mounts into
  gallery/docs
- Gallery subdirectories need `.immich` marker files — `manager.sh
  setup` (`setup_directories()`) creates dirs + markers only when
  `/mnt/object-storage/data` exists

## Traefik

- Config: `proxy/traefik.yml` + `proxy/dynamic/security.yml`
- Dashboard password: `proxy/entrypoint.sh` hashes via `htpasswd` at startup
- ACME certs: `proxy/acme.json` (gitignored)
- `exposedByDefault: false` — services must opt in with
  `traefik.enable=true` labels
- All services have Traefik labels commented out by default
  (direct port access pattern)

## Conventions

- Every service uses `security_opt: no-new-privileges:true` +
  `deploy.resources.limits` for CPU/memory
- `cloud`: seafile-mc v13 with `NON_ROOT=true` runs as **uid 8000** — data
  under `cloud/data/cloud/seafile/` must be owned by 8000:8000 (the
  compose `command` chowns on every start; `manager.sh perm` too). An
  image swap to uid 1000 silently breaks all libraries ("Commit ... is
  missing" in `seafile.log`).
- Seafile's `setup-seafile-mysql.py` runs **only when the data dir is
  empty** — later `.env` changes (S3, Redis host) are NOT applied;
  runtime config lives in `cloud/data/cloud/seafile/conf/`. `SEAFILE_USE_S3`
  etc. in `cloud/.env` only matter at first init.
- `manager.sh restart <svc>` does `docker compose restart` (no config
  reload) — after editing a compose file use `./manager.sh update <svc>`
  or `docker compose up -d` to recreate.
- The custom Dockerfiles are `docs/Dockerfile` (extends Paperless, adds
  Tesseract langs) and `dev-agents/Dockerfile` (Debian + Flutter +
  opencode CLI).
- `completions.bash` provides shell autocomplete — `source completions.bash`
- `.env.example` files are templates: copy to `.env` and fill
- No test suite, no CI, no linter, no codegen. Pure Docker Compose YAML +
  shell scripts.
- `manager.sh` is the primary executable
