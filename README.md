# Home Lab - dm-home.de

## Structure

```
dm-home.de/
├── databases/      # Shared PostgreSQL, MySQL, Redis
├── proxy/          # Traefik (reverse proxy)
├── monitoring/     # Grafana, Prometheus, Loki
├── passwords/      # Password manager
├── dockerui/       # Docker management UI
├── cloud/          # File cloud (Seafile)
├── docs/           # Document management
├── automation/     # Automation (n8n)
├── gallery/        # Photo gallery (Immich)
├── llm/            # LLM API (vLLM)
└── mail/           # Corporate mail (Mailcow)
```

## Server Resources

- **RAM**: 12 GB
- **NVMe**: 100 GB (for databases and fast operations)
- **Object Storage**: /mnt/object-storage (limited speed, permission limits)

## Database

Shared PostgreSQL and Redis for all services:

| Service | Database | Description |
|---------|----------|-------------|
| databases | PostgreSQL, Redis | Shared DBs |
| mail | MySQL (built-in) | Mail |

## Networks

- `web` - Traefik reverse proxy (80, 443 on host)
- `internal` - LLM, lmagent (isolated)
- `database` - shared PostgreSQL, Redis, MySQL

## Access and Ports

### Internal Access (10.0.0.1)

All services accessible via internal network at **10.0.0.1** (except mail and traefik which are externally accessible)

| Service | Port | Description |
|---------|------|--------------|
| **Services** | | |
| Passwords | 10.0.0.1:8200 | Password manager |
| DockerUI | 10.0.0.1:9000 | Docker UI |
| Cloud | 10.0.0.1:8383 | File hosting |
| Docs | 10.0.0.1:8000 | Document management |
| Automation | 10.0.0.1:5678 | Automation |
| Gallery | 10.0.0.1:2283 | Photo gallery |
| LMagent | 10.0.0.1:18789 | AI agent |
| LLM (vLLM) | 10.0.0.1:8001 | OpenAI-compatible API |
| **Monitoring** | | |
| Grafana | 10.0.0.1:3000 | Monitoring and logs |
| Prometheus | 10.0.0.1:9090 | Metrics |
| **Proxy** | | |
| Traefik | 80, 443 (external) | Reverse proxy (HTTP/HTTPS) |

### External Access (Direct)

These services are accessible directly from outside:

| Service | Port | Description |
|---------|------|--------------|

| Service | Port | Description |
|---------|------|--------------|
| **Traefik** | 80, 443 | Reverse proxy (HTTPS) |
| **Mail SMTP** | 25, 465, 587 | Email sending |
| **Mail IMAP** | 143, 993 | Email receiving |
| **Mail POP3** | 110, 995 | POP3 access |
| **Mail Sieve** | 4190 | Email filtering |

### Database (Internal Network)

| Service | Host | Port | Description |
|---------|------|------|-------------|
| PostgreSQL | postgres | 5432 | Main DB (passwords, docs, automation, gallery) |
| MySQL | mysql | 3306 | Mail MySQL |
| Redis | redis | 6379 | Cache and queues |

## Management

### manager.sh Script

```bash
./manager.sh <command> [service]
```

| Command | Description |
|---------|-------------|
| `start [svc]` | Start all or specific service |
| `stop` | Stop all services |
| `restart [svc]` | Restart |
| `update [svc]` | Update (pull) |
| `logs svc` | Service logs |
| `status` | Status of all services |
| `setup` | Create networks and directories |
| `perm` | Fix permissions |

### Examples

```bash
./manager.sh setup           # create networks and folders
./manager.sh start           # start all
./manager.sh start databases # ALWAYS DB FIRST
./manager.sh start proxy     # then proxy
./manager.sh start           # then rest
./manager.sh logs gallery    # logs for gallery
./manager.sh status          # status
./manager.sh update          # update all
```

## Security

- All services accessible only via internal network (10.0.0.1) except Traefik and Mail
- Traefik and Mail have direct internet access (for mail and reverse proxy)
- TLS 1.2+ with secure cipher suites
- Strict-Transport-Security headers
- Rate limiting on Traefik
- Passwords manager for password management
- Passwords not in git (use .env)
- Strict permissions on sensitive data

## Deployment from Scratch

```bash
# 1. Clone repository
git clone https://github.com/Dimoshka/server.git
cd server

# 2. Create networks and directories
./manager.sh setup

# 3. Fill passwords in .env files
vim databases/.env
vim passwords/.env
vim cloud/.env
vim mail/mail.env

# 4. Fix permissions
./manager.sh perm

# 5. Start DB and proxy first (CRITICAL!)
./manager.sh start databases
./manager.sh start proxy

# 6. Start remaining services
./manager.sh start

# 7. Check status
./manager.sh status
```

## Service Access

### Internal Connection

All services accessible only via internal network at **10.0.0.1**:

```bash
# Passwords (Vaultwarden)
http://10.0.0.1:8200

# Docker UI
http://10.0.0.1:9000

# Cloud (Seafile)
http://10.0.0.1:8383

# Docs (Paperless)
http://10.0.0.1:8000

# Automation (n8n)
http://10.0.0.1:5678

# Gallery (Immich)
http://10.0.0.1:2283

# LMagent (AI agent)
http://10.0.0.1:18789

# LLM API (vLLM)
http://10.0.0.1:8001

# Monitoring
http://10.0.0.1:3000  # Grafana
http://10.0.0.1:9090  # Prometheus
```

### API Access

```bash
# vLLM OpenAI-compatible API (inside docker network)
http://llm:8000/v1/chat/completions

# or via internal network
http://10.0.0.1:8001/v1/chat/completions
```

## Notes

- Services isolated in `internal` network, ports bound to 10.0.0.1
- databases starts first (all services depend on it)
- Traefik listens on 80,443 (external access) for reverse proxy
- Mail ports (25, 465, 587, 143, 993, 110, 995, 4190, 9993) available on host for mail
- Services isolated in `internal` network, ports bound to 10.0.0.1
- Logs in `proxy/logs/`
- TLS certificates in `proxy/acme.json` (do not commit)
- Without DNS, add entries to `/etc/hosts` on client