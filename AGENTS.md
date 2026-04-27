# Home Lab - dm-home.de

## Quick Start

```bash
./manager.sh setup      # Create networks and directories first
./manager.sh start databases  # ALWAYS start databases first (all services depend on it)
./manager.sh start proxy      # Then proxy (reverse proxy/Traefik)
./manager.sh start           # Then everything else
```

## Orchestration

All management via `./manager.sh`:
- `start [svc]` - Start all or one service (databases MUST be first)
- `stop` - Stop all in reverse order
- `restart [svc]` - Restart all or one service
- `update [svc]` - Pull + restart
- `logs <svc>` - Follow logs (e.g., `./manager.sh logs immich`)
- `status` - Show all service status
- `setup` - Create Docker networks (`web`, `internal`, `database`) + data dirs
- `perm` - Fix file permissions and ownership
- `clean` - Prune unused Docker volumes/networks

## Services (in startup order)

1. **databases** - PostgreSQL (pgvector), MySQL, Redis (all on `database` network)
2. **proxy** - Traefik reverse proxy on ports 80/443 (`web` network)
3. **monitoring** - Grafana, Prometheus, Loki
4. **vaultwarden** - Password manager
5. **portainer** - Docker management UI
6. **nextcloud** - File cloud
7. **paperless** - Document management
8. **n8n** - Automation
9. **immich** - Photo gallery
10. **llm** - LLM API (vLLM, on `internal` network)
11. **openclaw** - AI gateway (on `internal` network)

Note: `mailcow` is managed separately (corporate mail, not in this repo).

## Docker Networks

- `web` - External-facing (Traefik)
- `internal` - LLM, OpenCLAW (isolated)
- `database` - PostgreSQL, MySQL, Redis (shared)

## Sensitive Files (NOT to commit)

All `*.env` files, `proxy/acme.json`, `proxy/logs/`, `proxy/certs/`, `*/data/` directories.

## Aliases

- `docs` alias for `paperless` service
- `all` starts all services in order

## Traefik Notes

- Traefik uses file-based dynamic config in `proxy/dynamic/`
- Docker provider watches `/var/run/docker.sock` but `exposedByDefault: false`
- Services must have appropriate labels to be discovered