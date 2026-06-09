# DIP-Lab

## Structure

```
├── databases/      # PostgreSQL (pgvector), MySQL, Redis
├── proxy/          # Traefik v3 (reverse proxy)
├── monitoring/     # Grafana, Prometheus, Loki, Promtail, cAdvisor, node-exporter
├── passwords/      # Vaultwarden (password manager)
├── dockerui/       # Portainer CE (Docker management UI)
├── cloud/          # Seafile + memcached (file cloud)
├── docs/           # Paperless-ngx + Gotenberg + Tika (document management)
├── automation/     # n8n (automation)
├── gallery/        # Immich server + ML (photo gallery)
├── llm/            # llama.cpp serving Gemma 2B (OpenAI-compatible API)
└── aiagent/        # Hermes AI agent + nginx alias
```

## Server Resources

- **RAM**: 12 GB
- **NVMe**: 100 GB (for databases and fast operations)
- **Object Storage**: /mnt/object-storage (limited speed, permission limits)

## Database

Shared PostgreSQL, MySQL, and Redis for all services:

| Service | Database | Description |
|---------|----------|-------------|
| databases | PostgreSQL, MySQL, Redis | Shared DBs |

Databases are initialized with:
- `databases/init.sql` — creates `gallery`, `automation`, `docs` databases, enables `pgvector`
- `databases/mysql-init.sql` — creates `cloud` user and grants on Seafile databases
- PostgreSQL: `max_connections=200`, `shared_buffers=2GB`
- MySQL: `utf8mb4`, `max_connections=200`
- Redis: password required, `maxmemory 512mb`, `noeviction`, `appendonly yes`

## Networks

- `web` — Traefik reverse proxy (80, 443 on host)
- `internal` — all app services, port-mapped to `0.0.0.0:{port}`
- `database` — PostgreSQL, MySQL, Redis (isolated)
- `monitoring` — Prometheus/Grafana/Loki/cAdvisor/node-exporter (defined inline, not pre-created)

Services that need DB access attach to both `internal` and `database`. Others attach only to `internal`.

## Access and Ports

### Internal Access (0.0.0.0)

All services accessible via internal network at **0.0.0.0** (except Traefik which is externally accessible):

| Service | Port | Description |
|---------|------|-------------|
| **Services** | | |
| Passwords (Vaultwarden) | 0.0.0.0:8200 | Password manager |
| DockerUI (Portainer) | 0.0.0.0:9000 | Docker management UI |
| Cloud (Seafile) | 0.0.0.0:8383 | File hosting |
| Docs (Paperless) | 0.0.0.0:8000 | Document management |
| Automation (n8n) | 0.0.0.0:5678 | Automation |
| Gallery (Immich) | 0.0.0.0:2283 | Photo gallery |
| Hermes (AI agent) | 0.0.0.0:18789 | Agent API |
| Hermes Dashboard | 0.0.0.0:18790 | Agent Web UI |
| LLM (llama.cpp) | 0.0.0.0:8001 | OpenAI-compatible API |
| **Monitoring** | | |
| Grafana | 0.0.0.0:3000 | Monitoring and logs |
| Prometheus | 0.0.0.0:9090 | Metrics |
| **Proxy** | | |
| Traefik | 80, 443 (external) | Reverse proxy (HTTP/HTTPS) |

### External Access (Direct)

| Service | Port | Description |
|---------|------|-------------|
| **Traefik** | 80, 443 | Reverse proxy (HTTPS) |

### Database (Internal Network)

| Service | Host | Port | Description |
|---------|------|------|-------------|
| PostgreSQL | postgres | 5432 | Main DB (passwords, docs, automation, gallery) |
| MySQL | mysql | 3306 | Main MySQL |
| Redis | redis | 6379 | Cache and queues |

## Management

### manager.sh Script

```bash
./manager.sh <command> [service]
```

| Command | Description |
|---------|-------------|
| `setup` | Create 3 Docker networks + data directories |
| `start [svc]` | Start all (databases → proxy → rest automatically) or one service |
| `stop [svc]` | Stop all (databases last) or one service |
| `restart [svc]` | Restart all or one service |
| `update [svc]` | `docker compose pull` then recreate containers |
| `build <svc>` | Build image for a service |
| `logs <svc> [--tail N]` | Follow logs for a service |
| `status` | `docker compose ps` for every enabled service |
| `exec <svc> <cmd>` | Run command inside a service container |
| `perm` | Fix UID/GID ownership on data directories |
| `profile <action>` | Manage disabled-service profiles |
| `backup [dir]` | Backup data directories to tar.gz |
| `restore <file>` | Restore data directories from backup |
| `clean` | Prune unused Docker volumes/networks |
| `stop-all` | `docker stop` every running container |
| `full-cleanup` | Nuke containers, images, volumes, networks |
| `-n <command>` | Dry-run (show what would happen without executing) |

### Examples

```bash
./manager.sh setup           # create networks and folders
./manager.sh start           # start all (automatic boot order)
./manager.sh logs gallery    # logs for gallery
./manager.sh status          # status
./manager.sh update          # update all
./manager.sh profile minimal # switch to minimal profile
./manager.sh backup          # create backup archive
```

### Shell Autocomplete

```bash
source completions.bash
```

### Disabled Services & Profiles

Services can be excluded from bulk commands:

1. **`.disabled_services`** — list one service per line (gitignored; see `.disabled_services.example`)
2. **`profile` command** — `./manager.sh profile disable llm`, `./manager.sh profile enable llm`, or `./manager.sh profile minimal`

Disabled services can still be targeted explicitly: `./manager.sh start llm`

Built-in profiles (in `.profiles/`):
- `full` — all services enabled
- `default` — databases + proxy + dockerui + cloud + docs + gallery
- `minimal` — databases + proxy + dockerui
- `media` — databases + proxy + dockerui + monitoring + cloud + docs + gallery
- `no-ai` — all except llm + aiagent

### Object Storage

Optional `/mnt/object-storage/data` mount. When present:
- Gallery (Immich) mounts upload, thumbs, profile, backups, library, encoded-video
- Docs (Paperless) mounts `/mnt/object-storage/data/docs` as data root
- Automation (n8n) mounts at `/mnt/object-storage`
- Cloud (Seafile) and automation have optional cross-service read-only mounts

### Traefik

- Config: `proxy/traefik.yml` + `proxy/dynamic/security.yml`
- Dashboard password: `proxy/entrypoint.sh` hashes via `htpasswd` at startup
- ACME certs: `proxy/acme.json` (gitignored)
- `exposedByDefault: false` — services opt in with `traefik.enable=true` labels
- All services have Traefik labels commented out by default (direct port access pattern)

## Security

- All services accessible only via internal network (0.0.0.0) except Traefik
- Traefik has direct internet access (for reverse proxy)
- TLS 1.2+ with secure cipher suites
- Strict-Transport-Security headers
- Rate limiting on Traefik
- Passwords not in git (use .env files)
- Strict permissions on sensitive data
- Every service uses `security_opt: no-new-privileges:true` + `deploy.resources.limits`

## Deployment from Scratch

```bash
# 1. Clone repository
git clone https://github.com/Dimoshka/DIP-Lab.git
cd DIP-Lab

# 2. Create networks and directories
./manager.sh setup

# 3. Fill passwords in .env files
vim databases/.env
vim proxy/.env

# 4. Fix permissions
./manager.sh perm

# 5. Start everything
./manager.sh start

# 6. Check status
./manager.sh status
```

## Service Access

### Internal Connection

All services accessible only via internal network at **0.0.0.0**:

```bash
# Passwords (Vaultwarden)
http://0.0.0.0:8200

# Docker UI (Portainer)
http://0.0.0.0:9000

# Cloud (Seafile)
http://0.0.0.0:8383

# Docs (Paperless)
http://0.0.0.0:8000

# Automation (n8n)
http://0.0.0.0:5678

# Gallery (Immich)
http://0.0.0.0:2283

# Hermes (AI agent)
http://0.0.0.0:18789  # API
http://0.0.0.0:18790  # Web UI

# LLM (llama.cpp)
http://0.0.0.0:8001

# Monitoring
http://0.0.0.0:3000  # Grafana
http://0.0.0.0:9090  # Prometheus
```

### API Access

```bash
# LLM OpenAI-compatible API (inside docker network)
http://llm:8000/v1/chat/completions

# or via internal network
http://0.0.0.0:8001/v1/chat/completions
```

## Notes

- Services isolated in `internal` network, ports bound to 0.0.0.0
- `./manager.sh start` handles boot order automatically (databases → proxy → rest)
- Traefik listens on 80, 443 (external access) for reverse proxy
- Logs in `proxy/logs/`
- TLS certificates in `proxy/acme.json` (do not commit)
- Without DNS, add entries to `/etc/hosts` on client
- Every service has `<dir>/.env` (gitignored) and `<dir>/.env.example` with variables
- Shared secrets (DB passwords, `REDIS_PASSWORD`) are read from `databases/.env` via `env_file`
- The only custom Dockerfile is `docs/Dockerfile` (extends Paperless, adds Tesseract OCR langs)
- `.env.example` files are templates: copy to `.env` and fill
