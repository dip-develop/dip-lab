# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| latest  | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability, please:

1. **Do NOT** create a public GitHub issue
2. **Email** the maintainer directly (or use GitHub security advisories)
3. **Include** details about the vulnerability:
   - Description
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

## Security Best Practices

When deploying DIP-Lab:

1. **Change all default passwords** - All secrets in `.env` files should
   be changed from the placeholders in the corresponding `.env.example`
2. **Use strong passwords** - Use a password manager (Vaultwarden is
   included in this repo under `passwords/`)
3. **Keep services updated** - Run `./manager.sh update` regularly
4. **Restrict network access** - Services run on the internal Docker
   network; only Traefik is exposed externally
5. **Review container permissions** - Every service uses
   `no-new-privileges:true`; `dev-agents` and other developer tools
   run with explicit resource caps
6. **Enable firewall** - Only expose ports 80 and 443 (and any other
   port you intentionally need) to the internet
7. **Rotate `OPENCODE_SERVER_PASSWORD`** in `dev-agents/.env` if the
   opt-in developer container has been reachable on anything other than
   `127.0.0.1`

## Known Considerations

- **Traefik API** - Dashboard is disabled by default (`insecure: false`).
  Enable only over a trusted network.
- **Docker socket** - `proxy/traefik` mounts `/var/run/docker.sock` to
  read container labels; `containers/portainer` mounts it to provide
  Docker management. Treat those services as privileged.
- **MySQL init script** - `databases/mysql-init.sql` ships with
  placeholders. `databases/entrypoint.sh` substitutes real passwords
  from `databases/.env` at first start. If you ever change the MySQL
  password in `.env` after first start, also reset the
  `databases/data/mysql` volume (drop tables for the affected users and
  re-run the init).
- **Object storage** - The optional `/mnt/object-storage` mount is
  treated as semi-trusted. Do not put secrets on it without additional
  encryption.
- **`:latest` image tags** - Several services use `:latest` (n8n,
  Portainer, Vaultwarden, Grafana, Loki, Promtail, Prometheus,
  cAdvisor, node-exporter, Paperless, Hermes). Pin to a digest in
  production deployments where reproducibility matters.
- **dev-agents container** - The opt-in developer workstation has
  `opencode serve` always on. By default it binds to `127.0.0.1`. If
  you set `BIND_IP=0.0.0.0`, the `OPENCODE_SERVER_PASSWORD` is your
  only authentication.
