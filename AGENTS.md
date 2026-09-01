# Docker Compose Lab — Agent Guide

This project uses a `manager.sh` script to orchestrate multiple Docker Compose services. Services are organized in subdirectories, each with their own `docker-compose.yml` and `.env` files.

## Boot Order

`./manager.sh start` starts services in stages:
1. **Databases** (PostgreSQL, MySQL, Redis, etc.) — blocking, waits for health checks
2. **Proxy** (Traefik/NGINX) — blocking, waits for health checks
3. **All remaining services** — parallel startup

`./manager.sh setup` is called implicitly on every `start` to create networks and data directories.

## Key Commands

| Command | Description |
|---------|-------------|
| `./manager.sh setup` | Create Docker networks + data dirs; runs `<svc>/setup.sh` |
| `./manager.sh start [svc]` | Start all (db→proxy→rest) or one service |
| `./manager.sh stop [svc]` | Stop all (databases last) or one service |
| `./manager.sh restart [svc]` | Restart all or one service |
| `./manager.sh update [svc]` | Pull/rebuild images then recreate containers |
| `./manager.sh build <svc>` | Build service image |
| `./manager.sh logs <svc> [--tail N]` | Follow service logs |
| `./manager.sh status` | Show container status for enabled services |
| `./manager.sh exec <svc> <cmd>` | Run command in service container |
| `./manager.sh perm` | Fix UID/GID ownership on data dirs |
| `./manager.sh profile <action>` | Manage disabled-service profiles |
| `./manager.sh backup [dir]` | Backup data dirs to tar.gz |
| `./manager.sh restore <file>` | Restore data dirs from backup |
| `./manager.sh -n start` | Dry-run: show what would happen |
| `./manager.sh clean` | Prune unused Docker volumes/networks |
| `./manager.sh stop-all` | `docker stop` every running container |
| `./manager.sh full-cleanup` | Nuke containers, images, volumes, networks |

## Disabled Services & Profiles

- **`.disabled_services`** — one service per line in project root (gitignored). Explicit targeting still works: `./manager.sh start <service>`.
- **`profile` command** — `./manager.sh profile disable <svc>`, `enable <svc>`, or `./manager.sh profile <name>` to switch profile.
- Profiles live in `.profiles/` — each file lists services to disable (one per line). Profiles are applied by copying to `.disabled_services`.

Example profiles:
- `core` — infrastructure only (databases + proxy + container mgmt)
- `default` — everyday stack (core + app services)
- `full` — all services enabled

## Service Structure

Each service lives in its own directory:

```
<service-name>/
├── docker-compose.yml    # Required
├── .env.example          # Template for .env
├── .env                  # Gitignored, copy from .env.example
├── setup.sh              # Optional, run by manager.sh setup
├── entrypoint.sh         # Optional, container entrypoint
└── Dockerfile            # Optional, for locally built images
```

Services define their own:
- Networks (attach to shared `internal`, `database`, `web` networks)
- Volumes (data persisted in `<service>/data/`)
- Resource limits (CPU, memory, pids)
- Health checks
- Security options (`no-new-privileges:true`)

## Networks

Standard networks (created by `setup_nets`):
- `web` — Reverse proxy, ports 80/443 externally
- `internal` — All app services, inter-service communication
- `database` — Databases only (PostgreSQL, MySQL, Redis)
- `monitoring` — Observability stack (created inline in monitoring compose)

Services needing DB access attach to both `internal` and `database`.

## Secrets & Environment

- Every service has `<dir>/.env` (gitignored) and `<dir>/.env.example`.
- Never commit `.env` files.
- Each container loads **only its own** `<dir>/.env` via `env_file`.
- Shared credentials (DB passwords, etc.) must be kept identical across all service `.env` files.
- Use placeholder substitution in init scripts (e.g., `__MYSQL_PASSWORD__` in SQL, replaced by entrypoint.sh from `.env`).

## Database Initialization

- `init.sql` files create application databases and extensions.
- Test users/databases can be created conditionally via `TEST_*` env vars.
- Redis: dedicated DB index for test clients (e.g., `TEST_REDIS_DB=15`).
- Configure connection limits, buffers, charset as needed.

## Object Storage (Optional)

Services can mount external object storage at `/mnt/object-storage/data/<service>/`:
- Create marker files (e.g., `.immich`) in subdirectories if required by the application.
- `manager.sh setup` creates directories + markers when `/mnt/object-storage/data` exists.
- Local `./data/` mounts can be used as fallback (commented out by default).

## Reverse Proxy (Traefik/NGINX)

- Config in `proxy/` directory.
- Dashboard protected by htpasswd (generated at startup).
- ACME certs in `proxy/acme.json` (gitignored).
- `exposedByDefault: false` — services opt in with labels.
- Labels commented out by default for direct port access pattern.

## Conventions

- Every service: `security_opt: no-new-privileges:true` + `deploy.resources.limits`
- Non-root users where possible (specify UID/GID in compose or Dockerfile)
- `manager.sh restart <svc>` does `docker compose restart` (no config reload) — after editing compose, use `./manager.sh update <svc>` or `docker compose up -d`
- `.env.example` files are templates: copy to `.env` and fill
- Pure Docker Compose YAML + shell scripts — no test suite, CI, linter, or codegen required
- `manager.sh` is the primary executable
- Shell autocomplete: `source completions.bash`

## For Locally Built Images

Services with a `build:` section in docker-compose.yml:
- Use `./manager.sh build <svc>` to build/rebuild
- Use `./manager.sh update <svc>` — detects local build and runs build instead of pull
- Image tag should be local (e.g., `myorg/my-service:local`)

## Extending

Add new services by:
1. Creating `<service>/docker-compose.yml`
2. Adding service to `SERVICES_ALL` array in `manager.sh`
3. Creating `<service>/.env.example`
4. Running `./manager.sh setup` to create networks/dirs
5. Running `./manager.sh start <service>` to start

Disable by default by adding to a profile in `.profiles/` or `.disabled_services`.