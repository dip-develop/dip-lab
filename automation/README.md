# automation

n8n (workflow automation). The only automation service in DIP-Lab;
replaces Zapier / Make for self-hosted use.

| Container | Host port | Internal port |
|---|---|---|
| `automation` | `${BIND_IP:-0.0.0.0}:5678` | 5678 |

## Networks

- `internal` (for all other DIP-Lab peers, including dev-agents and
  the databases on which the consume queue sits)
- `database` (PostgreSQL backend)

## Configuration

- `.env` (template: `.env.example`) — `POSTGRES_PASSWORD`,
  `AUTOMATION_ENCRYPTION_KEY`, `AUTOMATION_DB_NAME`. The
  PostgreSQL credentials must match `../databases/.env`.
- The `automation` database is created by `../databases/init.sql`.
- `N8N_ENCRYPTION_KEY` is required to encrypt credentials stored in
  the n8n database. If you change it, existing credentials become
  unrecoverable. Generate with `openssl rand -hex 32`.

## First-start

- Open `http://<host>:5678`, set up the owner account.
- The first workflow should be a simple webhook + email to confirm
  SMTP is wired up (set `N8N_SMTP_*` env vars in `docker-compose.yml`).

## Object storage / cross-service mounts

`/mnt/object-storage` is mounted into the container for storing large
execution data. Optional read-only mounts of other services' data are
configured by uncommenting the relevant `volumes:` lines in
`docker-compose.yml`:

- `/mnt/cloud` — read Seafile libraries
- `/mnt/gallery` — read Immich photos
- `/mnt/docs` — read Paperless documents

## Data layout

```
data/
└── automation/    # n8n's internal data: .n8n, logs, custom nodes
```

## Resource caps

- `cpus: '1'`, `memory: 1G` — increase for workflows that process large
  files or many concurrent executions.

## Security

- `N8N_TRUST_PROXY=true` is set; ensure n8n is only reachable from
  Traefik (or `127.0.0.1`) so the `X-Forwarded-*` headers cannot be
  spoofed.
- `N8N_SECURE_COOKIE=false` is set because Traefik terminates TLS
  upstream — change to `true` if exposing n8n directly over HTTPS.

## Cross-service: opencode (dev-agents)

The `dev-agents` container ships with the `default` profile and
starts alongside the rest of the lab. n8n workflows can call the
opencode serve API. Fill in `OPENCODE_URL` and
`OPENCODE_SERVER_PASSWORD` in `automation/.env` (same password as
`dev-agents/.env`).

Use the **HTTP Request** node in a workflow:

- Method: `POST`
- URL: `{{ $env.OPENCODE_URL }}/api/sessions`
- Authentication: Generic Credential Type → Header Auth
  - Header name: `Authorization`
  - Header value: `Bearer {{ $env.OPENCODE_SERVER_PASSWORD }}`
- Body: JSON, depends on the opencode API you target
  (see `https://opencode.ai/docs/` for the current endpoint list)

The `dev-agents` service must be running for the `dev-agents`
hostname to resolve:

```bash
./manager.sh start dev-agents
```

## Cross-service: Seafile (cloud)

n8n workflows can call the Seafile HTTP API on the `internal` network.
Hostname `cloud` is the Docker container name; port 80 is the Seafile
web UI / seahub API.

Fill in `SEAFILE_URL` plus at least one of (`SEAFILE_ADMIN_EMAIL` +
`SEAFILE_ADMIN_PASSWORD`) or `SEAFILE_API_TOKEN` in
`automation/.env`. Token auth is preferred.

Example workflow node (list libraries):

- Method: `GET`
- URL: `{{ $env.SEAFILE_URL }}/api2/repos/`
- Auth: Generic Credential Type → Header Auth
  - Header: `Authorization`
  - Value: `Token {{ $env.SEAFILE_API_TOKEN }}`

## Cross-service: Immich (gallery)

n8n workflows can call the Immich REST API on the `internal` network.
Hostname `gallery` is the Docker container name; port 2283 is Immich.

Fill in `IMMICH_URL` and `IMMICH_API_KEY` in `automation/.env`.
Generate the key in the Immich web UI:
Admin → Settings → API Keys → New API Key.

Example workflow node (server health check):

- Method: `GET`
- URL: `{{ $env.IMMICH_URL }}/api/server/ping`
- Headers: `x-api-key: {{ $env.IMMICH_API_KEY }}`

For richer queries (search assets, albums, etc.) see the Immich API
docs at `https://immich.app/docs/api/`.

## Cross-service: Paperless (docs)

n8n workflows can call the Paperless-ngx REST API on the `internal`
network. Hostname `docs` is the Docker container name; port 8000 is
Paperless inside the container.

Fill in `DOCS_URL` and `DOCS_API_TOKEN` in `automation/.env`. Get the
token in the Paperless web UI: top-right user menu → My Profile →
Authentication Token.

Example workflow node (list documents):

- Method: `GET`
- URL: `{{ $env.DOCS_URL }}/api/documents/`
- Headers: `Authorization: Token {{ $env.DOCS_API_TOKEN }}`

## Cross-service: Vaultwarden (passwords)

n8n workflows can call the Vaultwarden (Bitwarden-compatible) API on
the `internal` network. Hostname `passwords` is the Docker container
name; port 80 is the Vaultwarden API inside the container.

Fill in `PASSWORDS_URL` and `PASSWORDS_API_KEY` in `automation/.env`.
Get a token by logging in once via the OAuth2 password grant
(`POST /identity/connect/token` with `grant_type=password&...`), or
use a long-lived client_credentials token from the Vaultwarden web UI
under Account → Security.

Example workflow node (fetch org members):

- Method: `GET`
- URL: `{{ $env.PASSWORDS_URL }}/api/public/members`
- Headers: `Authorization: Bearer {{ $env.PASSWORDS_API_KEY }}`

