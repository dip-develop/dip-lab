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

When deploying this home lab:

1. **Change all default passwords** - All secrets in `.env` files should be changed
2. **Use strong passwords** - Use a password manager (included in this repo)
3. **Keep services updated** - Run `./manager.sh update` regularly
4. **Restrict network access** - Services run on internal network (0.0.0.0)
5. **Review container permissions** - Avoid running containers as root when possible
6. **Enable firewall** - Only expose necessary ports to the internet (80, 443, 25, etc.)

## Known Considerations

- **Traefik API** - Dashboard is disabled by default (insecure=false)
- **Docker socket** - DockerUI has access to Docker socket (needed for management)
- **Mail server** - Requires proper DNS configuration (SPF, DKIM, DMARC)
- **LLM service** - Requires significant RAM/VRAM for model inference