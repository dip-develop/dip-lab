---
description: Set up full deployment pipeline (Dockerfile, compose, CI/CD, Traefik) for a new project
agent: orchestrator
subagent: true
---
You are a DevOps engineer. Set up a complete deployment pipeline for this project on my VPS.

### Target infrastructure (already deployed)

- **VPS**: Linux, Docker + Docker Compose v2
- **Reverse proxy**: Traefik v3 (already running, network = `web`)
  - Entrypoints: `web` (80), `websecure` (443)
  - Cert resolver: `letsencrypt` (ACME, HTTP challenge)
  - `exposedByDefault: false` — services must explicitly set `traefik.enable=true`
- **Docker networks**:
  - `web` — Traefik external network (all externally accessible services)
  - `internal` — internal network for inter-service communication
  - `database` — isolated network for databases (PostgreSQL, MySQL, Redis)
- **GHCR**: private registry, image pushed via GitHub Actions
- **Secrets**: generated once, stored in `deploy/.secrets` (chmod 600)

### What to create

#### 1. Dockerfile (multi-stage)

Requirements:
- Build stage: full SDK (Dart/Flutter/Serverpod — depends on the project)
- Runtime stage: minimal image (alpine/debian-slim), non-root user (UID 1001)
- Healthcheck: `curl` or `wget` on the appropriate port
- Nothing extra in runtime (only binary + configs + assets)
- For Serverpod: `dart compile exe` or `dart build cli`, ENTRYPOINT in exec form
- For Jaspr: `jaspr build`, runtime = debian-slim + curl

#### 2. docker-compose.yml

Requirements:
- Main application service + dependencies (PostgreSQL/Redis if needed)
- Traefik labels:
  ```yaml
  - "traefik.enable=true"
  - "traefik.docker.network=web"
  - "traefik.http.routers.<prefix>-web.rule=Host(`<domain>`)"
  - "traefik.http.routers.<prefix>-web.entrypoints=web"
  - "traefik.http.routers.<prefix>-web.middlewares=<prefix>-https-redirect"
  - "traefik.http.routers.<prefix>-secure.rule=Host(`<domain>`)"
  - "traefik.http.routers.<prefix>-secure.entrypoints=websecure"
  - "traefik.http.routers.<prefix>-secure.tls=true"
  - "traefik.http.routers.<prefix>-secure.tls.certresolver=letsencrypt"
  - "traefik.http.middlewares.<prefix>-https-redirect.redirectscheme.scheme=https"
  - "traefik.http.middlewares.<prefix>-https-redirect.redirectscheme.permanent=true"
  - "traefik.http.services.<prefix>-app.loadbalancer.server.port=<port>"
  - "traefik.http.services.<prefix>-app.loadbalancer.healthcheck.path=/readyz"
  - "traefik.http.services.<prefix>-app.loadbalancer.healthcheck.interval=30s"
  - "traefik.http.services.<prefix>-app.loadbalancer.healthcheck.timeout=5s"
  ```
- Networks: `web` (external) + `internal` (external) + `database` (external, if DB present)
- Resource limits: `deploy.resources.limits` (cpus + memory) for each service
- Healthcheck for each service
- `restart: unless-stopped`
- `security_opt: no-new-privileges:true`
- Variables via `.env` (never hardcode secrets)

#### 3. deploy/deploy.sh

Requirements:
- Accepts arguments: `<env> <image>` (env = prod | test)
- Generates `.secrets` on first run (openssl rand -hex 32)
- Generates `.env` for docker-compose
- For Serverpod: generates `config/passwords.yaml` from secrets
- Copies `docker-compose.yml` to `$DEPLOY_DIR`
- Runs `docker compose pull && docker compose up -d --remove-orphans`
- Logs in to GHCR if `GHCR_TOKEN` is provided
- `set -euo pipefail`

#### 4. deploy/.env.example

Template with comments:
- `CONTAINER_NAME`, `ROUTER_PREFIX`, `HOST_RULE`, `IMAGE`
- `TRAEFIK_NETWORK=web`, `WEB_ENTRYPOINT=web`, `WEBSECURE_ENTRYPOINT=websecure`, `CERT_RESOLVER=letsencrypt`
- Secrets (empty, with note "generated automatically")
- Resource limits (commented out, with defaults)

#### 5. .github/workflows/deploy.yml

Requirements:
- Triggers: `push` to `main` (→ prod) and `develop` (→ staging), `workflow_dispatch`
- Jobs:
  1. Checkout
  2. Docker Buildx + login GHCR
  3. Build & push image (tag: `<env>-latest` and `sha-<env>-<sha>`)
  4. SCP `deploy.sh` + `docker-compose.yml` to VPS
  5. SSH → `bash deploy.sh <env> <image>`
- Environment secrets: `VPS_HOST`, `VPS_USER`, `VPS_SSH_KEY`, `GHCR_TOKEN`
- Concurrency: `deploy-${{ github.ref_name }}`, cancel-in-progress: false

#### 6. deploy/README.md

Brief runbook:
- How to run manually
- How to update
- How to rollback
- Where secrets are stored
- How to add a new environment

### Project specifics

Ask the user for:
- **Project name** (kebab-case, e.g. `gewerber`)
- **Router prefix** (short, e.g. `gwb`)
- **Base domain** (e.g. `example.com`)
- **Project type**: `serverpod` or `jaspr`

If `$ARGUMENTS` contains `serverpod` or `jaspr`, use that as the type and skip the type question.

- **Serverpod**: port 8080 (API), 8081 (Insights, internal only), migrations applied automatically (`SERVERPOD_APPLY_MIGRATIONS=true`), needs PostgreSQL + Redis
- **Jaspr**: port 8080, web server only, no database needed

### Naming

- Project: `<project-name>`
- Domain: `<project-name>.<domain>` (prod), `test.<project-name>.<domain>` (staging)
- Router prefix: `<prefix>`
- Container: `<project-name>` / `<project-name>-test`
- Deploy dir: `~/<project-name>/<env>/`
- Compose project: `<project-name>-<env>`

### Example structure after setup

```
.
├── Dockerfile
├── docker-compose.yml
├── .env.example
├── .github/
│   └── workflows/
│       └── deploy.yml
├── deploy/
│   ├── deploy.sh
│   ├── .env.example
│   └── README.md
└── [serverpod/jaspr specific files]
```

### Verification after setup

1. `docker compose config` — validate compose file
2. `bash -n deploy/deploy.sh` — validate script syntax
3. `docker compose build` — build image
4. `docker compose up -d` — local startup
5. `curl http://localhost:<port>/readyz` — healthcheck
6. After first GHCR deploy: `docker compose pull && docker compose up -d`

### Notes

- All secrets are generated automatically on first deploy
- For private GHCR images, `GHCR_TOKEN` (PAT with `read:packages`) is required
- Traefik will issue a Let's Encrypt certificate on first request
- Use `develop` branch → staging environment for testing deploys
