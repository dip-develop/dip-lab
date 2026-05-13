# DIP-Lab

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
- `logs <svc>` - Follow logs (e.g., `./manager.sh logs gallery`)
- `status` - Show all service status
- `setup` - Create Docker networks (`web`, `internal`, `database`) + data dirs
- `perm` - Fix file permissions and ownership
- `clean` - Prune unused Docker volumes/networks
- `stop-all` - Stop all running Docker containers
- `full-cleanup` - Stop all containers, remove all containers/images/volumes/networks

## Services (in startup order)

1. **databases** - PostgreSQL (pgvector), MySQL, Redis (all on `database` network)
2. **proxy** - Traefik reverse proxy on ports 80/443 (`web` network)
3. **monitoring** - Grafana, Prometheus, Loki
4. **passwords** - Password manager (Vaultwarden)
5. **dockerui** - Docker management UI (Portainer)
6. **cloud** - File cloud (Seafile)
7. **docs** - Document management (Paperless)
8. **automation** - Automation (n8n)
9. **gallery** - Photo gallery (Immich)
10. **llm** - LLM API (vLLM, on `internal` network)
11. **lmagent** - AI agent (on `internal` network)

## Docker Networks

- `web` - External-facing (Traefik)
- `internal` - LLM, lmagent (isolated)
- `database` - PostgreSQL, MySQL, Redis (shared)

## Sensitive Files (NOT to commit)

All `*.env` files, `proxy/acme.json`, `proxy/logs/`, `proxy/certs/`, `*/data/` directories.

## Aliases

- `all` starts all services in order

## Traefik Notes

- Traefik uses file-based dynamic config in `proxy/dynamic/`
- Docker provider watches `/var/run/docker.sock` but `exposedByDefault: false`
- Services must have appropriate labels to be discovered

---

## Project Identity

- **Public name:** DIP-Lab
- **Type:** Open-source, self-hosted home & business infrastructure stack
- **Deployment target:** VPS with 12 GB RAM, 4 CPU cores, 100 GB NVMe, expandable S3-compatible object storage

## Project Purpose

DIP-Lab provides a unified, modular environment for:

- personal cloud and file storage (Seafile)
- photo and media management (Immich)
- document processing and OCR (Paperless-ngx)
- password management (Vaultwarden)
- workflow automation (n8n)
- local LLM inference (vLLM)
- AI agent execution (Hermes/lmagent)
- monitoring and observability (Prometheus, Grafana, Loki)
- optional business backends and websites

## Architecture Overview

The project is fully containerized using **Docker** and organized into modular service stacks.

### Core architectural principles

- **Traefik** is the only public entrypoint (reverse proxy + TLS).
- All services are **internal-only** by default.
- Access to internal services is via **WireGuard VPN**.
- Optional public exposure is enabled via **commented Traefik labels** in docker-compose files.
- Shared infrastructure components:
  - PostgreSQL (with pgvector)
  - MySQL
  - Redis
  - S3-compatible object storage (optional per service)
- All services run in isolated Docker networks with explicit communication rules.

## Configuration & Secrets Management

- All sensitive data is stored in **`.env`** (not committed).
- **`.env.example`** contains placeholders only.
- Image versions, ports, credentials, and storage paths must be configurable via `.env` whenever possible.
- If a setting cannot be controlled via `.env`, it must be implemented as **commented lines** in docker-compose files.
- Never generate real passwords or secrets.

## Storage Architecture

- Local NVMe is used for active data.
- S3-compatible object storage is mounted on the host and enabled per service via `.env`.
- Storage paths must support shared access for Immich, Paperless-ngx, Seafile, and other services requiring shared directories.

## Networking & Security Model

- Only Traefik is exposed publicly.
- All other services are accessible only through WireGuard VPN.
- Optional public exposure is enabled by uncommenting Traefik labels.
- Each service runs in its own Docker network.
- Inter-service communication is minimal and explicitly defined.
- Security is a core requirement; avoid suggesting insecure shortcuts.

## Documentation Requirements

All documentation must be:

- written in **English**
- clear, structured, and beginner-friendly
- technically accurate and consistent
- suitable for open-source contributors

Documentation must include:

- architecture descriptions
- environment variable explanations
- service-specific READMEs
- comments inside docker-compose files
- instructions for enabling/disabling optional components
- storage and networking diagrams or explanations

## LLM Behavioral Rules

When responding:

- Maintain strict consistency with the project architecture.
- Do not invent services, technologies, or assumptions.
- Do not generate secrets or credentials.
- Do not perform deployment steps unless explicitly asked.
- Do not contradict the security model.
- Prefer modular, maintainable, and documented solutions.
- When suggesting improvements, ensure they align with the project's philosophy.
- Treat `.env` and `.env.example` as core configuration mechanisms.
- Respect the open-source nature of the project.
- Provide concise, technically correct, and actionable information.