# ai-agent

Hermes AI agent — exposes an API and a web dashboard for orchestrating
LLM-driven agents and tools.

| Container | Host port | Internal port | Purpose |
|---|---|---|---|
| `hermes` | `${BIND_IP:-0.0.0.0}:18789`, `${BIND_IP:-0.0.0.0}:18790` | 8642, 9119 | API + web dashboard |

## Networks

- `internal` only

## Configuration

- `.env` (template: `.env.example`) — `BIND_IP`, `DOMAIN`,
  `HERMES_DASHBOARD_BASIC_AUTH_*`, `API_SERVER_KEY`,
  `HERMES_ALLOWED_ORIGINS`, `TELEGRAM_BOT_TOKEN`,
  `TELEGRAM_ALLOWED_USERS`, `DEEPSEEK_API_KEY`, `ANTHROPIC_API_KEY`,
  `OPENAI_API_KEY`
- At minimum, set a strong `HERMES_DASHBOARD_BASIC_AUTH_PASSWORD` and
  `API_SERVER_KEY` before exposing the service.
- LLM provider keys are optional — the agent will only use the
  providers whose keys are present.

### Cross-service: opencode (dev-agents)

To let Hermes call the `dev-agents` opencode serve API:

```bash
# Generate a strong password (one-time)
openssl rand -hex 32
# Use the same value you put in dev-agents/.env
```

In `ai-agent/.env`:

```bash
OPENCODE_URL=http://dev-agents:4096
OPENCODE_SERVER_PASSWORD=<the same password as in dev-agents/.env>
HERMES_OPENCODE_AUTOCALL=false   # set to true if you want Hermes to
                                 # invoke opencode without explicit
                                 # operator approval
```

Notes:
- `dev-agents` must be started for the hostname to resolve:
  `./manager.sh start dev-agents`
- If `dev-agents` is down, Hermes's calls to opencode will fail and
  be retried by the agent runtime — Hermes itself stays healthy.
- The same `OPENCODE_SERVER_PASSWORD` is required in
  `dev-agents/.env` for the `opencode serve` web UI/API to accept
  the request.

## First-start

1. Open `http://<host>:18790` (dashboard) and log in with the basic-auth
   credentials from `.env`.
2. Open `http://<host>:18789` (API) — the OpenAPI schema is served
   there.

## Data layout

```
data/
└── aiagent/    # persistent agent state, conversation history
```

(Backwards-compat: the data directory is still named `data/aiagent/` to
match the volume path in `docker-compose.yml`; do not rename or the
container will start with a fresh empty state.)

## Connectivity with other DIP-Lab services

Hermes is on the `internal` network and can reach every other
`internal`-attached service by hostname. Whether a call **succeeds**
depends on whether credentials are configured for that service.

| Service | URL (from inside ai-agent) | Auth | Configured via |
|---|---|---|---|
| n8n (automation) | `http://automation:5678` | n8n user session | (no API key by default) |
| opencode (dev-agents, opt-in) | `http://dev-agents:4096` | `Authorization: Bearer $OPENCODE_SERVER_PASSWORD` | `OPENCODE_*` in `.env` |
| Seafile (cloud) | `http://cloud` | admin email+password **or** `Token $SEAFILE_API_TOKEN` | `SEAFILE_*` in `.env` |
| Immich (gallery) | `http://gallery:2283` | `x-api-key: $IMMICH_API_KEY` | `IMMICH_*` in `.env` |
| Paperless (docs) | `http://docs:8000` | `Authorization: Token $DOCS_API_TOKEN` | `DOCS_*` in `.env` |
| Vaultwarden (passwords) | `http://passwords` | `Authorization: Bearer $PASSWORDS_API_KEY` | `PASSWORDS_*` in `.env` |
| Traefik (proxy) | n/a (Hermes is not exposed via Traefik by default) | — | — |

Hermes is **not** on the `database` network, so it cannot reach
PostgreSQL, MySQL, or Redis directly. Always go through the service's
HTTP API.

The opt-in `dev-agents` container is also on `internal` and can reach
Hermes at `http://ai-agent:8642` (API) or `http://ai-agent:9119`
(dashboard) for cross-agent calls. See `../dev-agents/AGENTS.md` for
the inverse table.

### Seafile (cloud)

In `ai-agent/.env`, fill in at least one of:

- `SEAFILE_ADMIN_EMAIL` + `SEAFILE_ADMIN_PASSWORD` (set during
  Seafile's first-run setup), or
- `SEAFILE_API_TOKEN` (preferred) — generate it in the Seafile web UI
  under User Settings → Personal Access Tokens.

Without either, calls to Seafile will return 401.

### Immich (gallery)

In `ai-agent/.env`, set `IMMICH_API_KEY`. Generate it in the Immich
web UI: Admin → Settings → API Keys → New API Key.

Without it, calls to Immich will return 401.

### Paperless (docs)

In `ai-agent/.env`, set `DOCS_API_TOKEN`. Generate it in the
Paperless web UI: top-right user menu → My Profile →
Authentication Token.

Without it, calls to Paperless will return 401.

### Vaultwarden (passwords)

In `ai-agent/.env`, set `PASSWORDS_API_KEY`. Get a token by logging
into Vaultwarden once (e.g. with the master account via the
`/identity/connect/token` OAuth2 password grant), or use a
long-lived client_credentials token from the web UI under
Account → Security.

Without it, calls to Vaultwarden will return 401.

## Resource caps

- `cpus: '2'`, `memory: 4G` (Hermes is CPU-bound on LLM routing / tool
  orchestration)

## Security

- The dashboard is `insecure` by default (no built-in TLS). Put Hermes
  behind Traefik (`traefik.enable=true` labels in `docker-compose.yml`)
  for HTTPS.
- `HERMES_ALLOWED_ORIGINS` should be locked down to your actual
  front-end hostnames once you go beyond local testing.
