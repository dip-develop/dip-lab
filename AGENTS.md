# DIP-Lab — Agent Guide

## Overview

Docker Compose home lab. 11 services in `docker-compose.yml` files, each in its own subdirectory. All management goes through `./manager.sh`.

## Boot order (handled automatically)

`./manager.sh start` now does `databases → proxy → rest` automatically with health-check waits between stages. All non-critical services start in parallel.

## Key commands

| Command | What it does |
|---------|-------------|
| `./manager.sh setup` | Create 3 Docker networks + data directories |
| `./manager.sh start [svc]` | Start all (databases first, then parallel) or one service |
| `./manager.sh stop [svc]` | Stop all (databases last) or one service |
| `./manager.sh restart [svc]` | Restart all or one service |
| `./manager.sh update [svc]` | `docker compose pull` then recreate containers |
| `./manager.sh logs [svc] --tail 100` | Follow logs for a service |
| `./manager.sh status` | `docker compose ps` for every enabled service |
| `./manager.sh perm` | Fix UID/GID ownership on data dirs |
| `./manager.sh exec <svc> <cmd>` | Run command inside a service container |
| `./manager.sh profile <action>` | Manage disabled-service profiles |
| `./manager.sh backup [dir]` | Backup data directories to tar.gz |
| `./manager.sh restore <file>` | Restore data directories from backup |
| `./manager.sh -n start` | Dry-run (show what would happen) |

## Disabled services & profiles

Services can be excluded from bulk commands. Two ways:

1. **`.disabled_services`** — list one service per line in project root (gitignored)
2. **`profile` command** — `./manager.sh profile disable llm`, `./manager.sh profile enable llm`, or `./manager.sh profile minimal` to switch to a predefined profile

Disabled services can still be targeted explicitly: `./manager.sh start llm`

Built-in profiles: `full`, `minimal` (databases + proxy + dockerui), `media` (adds gallery + docs), `no-ai`

## Service directories & images

| Directory | What | Image |
|-----------|------|-------|
| `databases/` | PostgreSQL (pgvector/pg16), MySQL 8.0, Redis 7 | `pgvector/pgvector:pg16`, `mysql:8.0`, `redis:7-alpine` |
| `proxy/` | Traefik v3 | `traefik:v3.7.0-rc.2` |
| `monitoring/` | Prometheus, Grafana, Loki, Promtail, cAdvisor, node-exporter | `prom/`, `grafana/`, `loki:latest`, `promtail:latest` |
| `passwords/` | Vaultwarden | `vaultwarden/server:latest` |
| `dockerui/` | Portainer CE | `portainer/portainer-ce:latest` |
| `cloud/` | Seafile + memcached | `seafileltd/seafile-mc:13.0.21` |
| `docs/` | Paperless-ngx + Gotenberg + Tika | Custom Dockerfile for Paperless |
| `automation/` | n8n | `n8nio/n8n:latest` |
| `gallery/` | Immich server + ML | `ghcr.io/immich-app/immich-server:v2` |
| `llm/` | llama.cpp serving Gemma 2B | `ghcr.io/ggml-org/llama.cpp:full` |
| `aiagent/` | Hermes (AI agent) | `nousresearch/hermes-agent:latest` |

## Networks

- `web` — Traefik, ports 80/443 externally
- `internal` — all app services, port-mapped to `0.0.0.0:{port}`
- `database` — databases only (PostgreSQL, MySQL, Redis)
- `monitoring` — Prometheus/Grafana/Loki/cAdvisor/node-exporter

Services that need DB access attach to both `internal` and `database`.

## Secrets & env

Every service has `<dir>/.env` (gitignored) and `<dir>/.env.example` with variables. Never commit `.env` files. Secrets to keep in each service `.env`:

- `databases/.env`: PostgreSQL/MySQL/Redis passwords
- `proxy/.env`: ACME email, dashboard credentials
- Shared secrets (DB passwords, `REDIS_PASSWORD`) are read from `databases/.env` into dependent services via `env_file`.

## Object storage

Optional `/mnt/object-storage/data` mount. When present, gallery (Immich) and docs (Paperless) mount subdirectories from it. n8n mounts it at `/mnt/object-storage`. Gallery subdirectories require `.immich` marker files — see `manager.sh` `setup_directories()`.

## Traefik

- Config: `proxy/traefik.yml` + `proxy/dynamic/security.yml`
- Dashboard password: `proxy/entrypoint.sh` hashes via `htpasswd` at startup
- ACME certs: `proxy/acme.json` (gitignored)
- All services have Traefik labels commented out by default (direct port access pattern)

## What to expect from OpenCode agents

- This repo has **no test suite**, **no CI**, **no linter**, **no codegen**. It's Docker Compose YAML + shell scripts.
- If asked to write code, it's likely a new shell script or a `docker-compose.yml` addition.
- `manager.sh` is the only meaningful executable.
