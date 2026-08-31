# passwords

Vaultwarden (Bitwarden-compatible password manager) for self-hosted
credential storage.

| Container | Host port | Internal port |
|---|---|---|
| `vaultwarden` | `${BIND_IP:-0.0.0.0}:8200` | 80 |

## Configuration

- `.env` (template: `.env.example`) — `PASSWORDS_ADMIN_TOKEN` (long
  random string; protects the `/admin` panel)
- No database — Vaultwarden uses its own SQLite database in
  `data/passwords`.

## First-start

1. Open `http://<host>:8200` and create the first account.
2. To enable the admin panel, append `?admin_token=<PASSWORDS_ADMIN_TOKEN>`
   once and set up the admin user.
3. Configure SMTP for invitations / password resets (not enabled by
   default — edit `docker-compose.yml` to add `SMTP_*` env vars).

## Data layout

```
data/
└── passwords/    # SQLite db, attachments, icon cache
```

## Resource caps

- `cpus: '1'`, `memory: 512M` (CPU-bound when handling many
  concurrent logins / attachments; can be raised for large teams)

## Security

- `admin` panel disabled by default; the token in `PASSWORDS_ADMIN_TOKEN`
  is the only auth on it.
- Put Vaultwarden behind Traefik (`traefik.enable=true` labels) for
  TLS + a public hostname.
