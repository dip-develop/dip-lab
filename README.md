# DIP-Lab

A self-hosted home-lab stack of 11 services orchestrated by a single
`manager.sh` script. Targeted at a single Linux host (12 GB RAM, 100 GB
NVMe, optional object-storage mount) running behind a Traefik reverse
proxy.

## Services

| Directory | What |
|---|---|
| `databases/` | PostgreSQL (pgvector), MySQL, Redis |
| `proxy/` | Traefik v3 (reverse proxy) |
| `monitoring/` | Grafana, Prometheus, Loki, Promtail, cAdvisor, node-exporter |
| `passwords/` | Vaultwarden (password manager) |
| `containers/` | Portainer CE (container management UI) |
| `cloud/` | Seafile + memcached (file cloud) |
| `docs/` | Paperless-ngx + Gotenberg + Tika (document management) |
| `automation/` | n8n (automation) |
| `gallery/` | Immich server + ML (photo gallery) |
| `ai-agent/` | Hermes AI agent + dashboard |
| `dev-agents/` | **Opt-in.** Developer workstation container: Flutter SDK + opencode CLI |

## Quick start

```bash
git clone https://github.com/dip-develop/dip-lab.git
cd dip-lab

# Create networks and data directories
./manager.sh setup

# Fill in secrets (one .env per service, see below)
cp databases/.env.example databases/.env
cp proxy/.env.example proxy/.env
# ...repeat for each service you intend to run

# Fix ownership
./manager.sh perm

# Start everything
./manager.sh start
./manager.sh status
```

## Service ports (defaults)

All services bind to `0.0.0.0` on the host; Traefik is the only one
exposed externally (80, 443).

| Service | Host port | Purpose |
|---|---|---|
| Passwords (Vaultwarden) | 8200 | Password manager |
| DockerUI (Portainer) | 9000 | Docker management UI |
| Cloud (Seafile) | 8383 | File hosting |
| Docs (Paperless) | 8000 | Document management |
| Automation (n8n) | 5678 | Automation |
| Gallery (Immich) | 2283 | Photo gallery |
| Hermes API / Dashboard | 18789 / 18790 | AI agent |
| Grafana / Prometheus | 3000 / 9090 | Monitoring |
| Traefik | 80, 443 | Reverse proxy (external) |

The optional `dev-agents` container exposes `opencode serve` on
`127.0.0.1:4096` by default — see `dev-agents/README.md`.

## Database

Shared PostgreSQL, MySQL, and Redis for all services:

- `databases/init.sql` — creates `gallery`, `automation`, `docs`
  databases, enables `pgvector`
- `databases/mysql-init.sql` — creates `cloud` user and grants on
  Seafile databases. Passwords are placeholders; `databases/entrypoint.sh`
  substitutes real values from `databases/.env` at container start.
- PostgreSQL: `max_connections=200`, `shared_buffers=2GB`
- MySQL: `utf8mb4`, `max_connections=200`
- Redis: password required, `maxmemory 512mb`, `allkeys-lru`, RDB only

Inside the lab, services reach databases by hostname on the `database`
Docker network (`postgres:5432`, `mysql:3306`, `redis:6379`).

## Networks

- `web` — Traefik reverse proxy (80, 443 on host)
- `internal` — all app services, port-mapped to `0.0.0.0:{port}`.
  `dev-agents` is also on `internal` so its opencode agents can reach
  `automation`, `ai-agent`, and `postgres` by hostname.
- `database` — PostgreSQL, MySQL, Redis (isolated)
- `monitoring` — Prometheus/Grafana/Loki/cAdvisor/node-exporter
  (defined inline, not pre-created)

Services that need DB access attach to both `internal` and `database`.
Others attach only to `internal`.

## Management

### `./manager.sh <command> [service]`

| Command | Description |
|---|---|
| `setup` | Create networks + data directories |
| `start [svc]` | Start all (db→proxy→rest) or one service |
| `stop [svc]` | Stop all (databases last) or one service |
| `restart [svc]` | Restart all or one service |
| `update [svc]` | `docker compose pull` then recreate containers |
| `build <svc>` | Build image for a service |
| `logs <svc> [--tail N]` | Follow logs for a service |
| `status` | `docker compose ps` for every enabled service |
| `exec <svc> <cmd>` | Run command inside a service container |
| `perm` | Fix file permissions / ownership |
| `profile <action>` | Manage disabled-service profiles |
| `backup [dir]` | Backup data directories to `diplab-backup-<timestamp>.tar.gz` |
| `restore <file>` | Restore data from backup archive |
| `clean` | Prune unused Docker volumes / networks |
| `stop-all` | `docker stop` every running container |
| `full-cleanup` | Nuke containers, images, volumes, networks |
| `-n <command>` | Dry-run (show what would happen) |

### Examples

```bash
./manager.sh setup           # create networks and folders
./manager.sh start           # start enabled services
./manager.sh start dev-agents # start the opt-in developer workstation
./manager.sh logs gallery --tail 50
./manager.sh status
./manager.sh update
./manager.sh profile core # switch to core profile
./manager.sh backup          # create backup archive
```

### Shell autocomplete

```bash
source completions.bash
```

### Disabled services & profiles

Two mechanisms to exclude a service from bulk commands:

1. **`.disabled_services`** — list one service per line (gitignored;
   see `.disabled_services.example`).
2. **`profile` command** — `./manager.sh profile disable dev-agents`,
   `./manager.sh profile enable dev-agents`, or
   `./manager.sh profile <name>` to switch profile.

Disabled services can still be targeted explicitly:
`./manager.sh start dev-agents`.

Built-in profiles (in `.profiles/`, listed in order of how much they
enable):

- `core` — foundation only: `databases` + `proxy` + `containers`. No
  app services. Use for the very first start, or a host that only
  runs infrastructure.
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

`dev-agents` is included only in `dev` and `full`. In every other
profile you must enable it explicitly:
`./manager.sh profile enable dev-agents`.

### Object storage

Optional `/mnt/object-storage/data` mount. When present:
- Gallery (Immich) mounts upload, thumbs, profile, backups, library,
  encoded-video
- Docs (Paperless) mounts `/mnt/object-storage/data/docs` as data root
- Automation (n8n) mounts at `/mnt/object-storage`
- Cloud (Seafile) and automation have optional cross-service read-only
  mounts

When the mount is absent, `manager.sh setup` skips the object-storage
subdirectory creation. Docker will create empty root-owned dirs under
the bind paths instead, which is harmless but visible.

### Traefik

- Config: `proxy/traefik.yml` + `proxy/dynamic/security.yml`
- Dashboard password: `proxy/entrypoint.sh` hashes via `htpasswd` at
  startup
- ACME certs: `proxy/acme.json` (gitignored)
- `exposedByDefault: false` — services opt in with `traefik.enable=true`
  labels
- All services have Traefik labels commented out by default
  (direct port access pattern)

## Security

- All services accessible only via the internal Docker network except
  Traefik
- Traefik has direct internet access (for reverse proxy + ACME)
- TLS 1.2+ with secure cipher suites via `proxy/dynamic/security.yml`
- Strict-Transport-Security headers
- Rate limiting on Traefik (`ratelimit` middleware, 100 req/s burst 50)
- Secrets stay in `.env` (gitignored) — every service has a
  `<dir>/.env.example` template
- Strict permissions on sensitive data (`chmod 600` on `.env` and
  `acme.json`)
- Every service uses `security_opt: no-new-privileges:true` +
  `deploy.resources.limits` for CPU/memory
- `dev-agents` runs with no `docker.sock`, no `--privileged`, and
  `opencode` agents are denied at the permission level from reading
  `.env` files, SSH keys, WireGuard configs, or pushing to `main`

See `SECURITY.md` for the responsible-disclosure policy.

## License

MIT. See `LICENSE`.

## Contributing

See `CONTRIBUTING.md`.
