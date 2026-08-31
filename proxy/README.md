# proxy

Traefik v3 reverse proxy. Only service exposed to the public internet
(ports 80, 443).

| Container | Ports | Purpose |
|---|---|---|
| `traefik` | 80, 443 (host) | Reverse proxy + ACME + dashboard |

## Networks

- `web` (external) — receives public traffic on 80/443
- `internal` (external) — reaches the other services

## Configuration

- `traefik.yml` — static config (entry points, log level, ACME
  resolver, provider `exposedByDefault: false`)
- `dynamic/security.yml` — security headers, rate limiting middleware,
  large-upload buffer
- `.env` (template: `.env.example`) — `TRAEFIK_DASHBOARD_USER`,
  `TRAEFIK_DASHBOARD_PASS`, `ACME_EMAIL`
- `entrypoint.sh` — hashes the dashboard password with `htpasswd` and
  writes `dynamic/.htpasswd` (mode 600) at startup

## ACME / TLS

- Certs stored in `acme.json` (gitignored, mode 600)
- `httpChallenge` over the `web` entrypoint
- Let's Encrypt staging/production is selected by the standard
  `certresolver=letsencrypt` label

## Service opt-in

By default `exposedByDefault: false` is set, so services are NOT
exposed through Traefik unless they add `traefik.enable=true` labels.
All service `docker-compose.yml` files in this repo ship with those
labels commented out — uncomment to expose.

## Required reads

- `traefik.yml` for entrypoint names (`web`, `websecure`)
- `dynamic/security.yml` for the named middlewares (`security-headers`,
  `ratelimit`, `large-upload`, `strip-trailing-slash`)

## First-start notes

- ACME cert issuance requires the hostname to resolve to this host
  (DNS A/AAAA record) AND ports 80/443 to be reachable from the
  internet.
- For local-only testing, set up `/etc/hosts` entries and use
  self-signed certs (out of scope here).
