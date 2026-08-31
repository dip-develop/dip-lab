# containers

Container management UI. Currently Portainer CE, but the directory is
named after the *function* (managing containers), not the implementation
— swapping in another UI (Lazydocker web, a custom one) wouldn't
require renaming the directory, the compose service, or breaking any
upstream automation that refers to "containers".

| Container | Host port | Internal port |
|---|---|---|
| `containers-ui` | `${BIND_IP:-0.0.0.0}:9000` | 9000 |

## Configuration

- `.env` (template: `.env.example`) — `CONTAINERS_ADMIN_PASSWORD`
  (set on first login). `DOCKERUI_ADMIN_PASSWORD` is also accepted for
  backward compatibility.
- No database — Portainer stores its own state in `./data/containers/`.

## Networks

- `internal` only — the container manager does not need to talk to
  other services (it manages the Docker daemon, not the apps).

## Privileged access

This service mounts `/var/run/docker.sock` to manage containers,
images, volumes, and networks. This is the same access as the host's
root user. **Treat the containers service as privileged** — put it
behind Traefik with basic auth, or bind it to `127.0.0.1` only.

## First-start

1. Open `http://<host>:9000` and set the admin password
   (`$CONTAINERS_ADMIN_PASSWORD` is the initial hint).
2. Choose "Local" environment to manage the host Docker daemon.

## Data layout

```
data/
└── containers/
    ├── bin/        # Portainer binary data
    ├── tls/        # TLS certs (if configured)
    ├── certs/
    ├── chisel/     # agent tunnel data
    ├── docker_config/
    └── compose/    # saved Compose stacks
```

(If you had data in the old `./data/dockerui/` from before the
rename, `manager.sh setup` does not migrate it — `mv
./data/dockerui/* ./data/containers/` once before the first start.)

## Resource caps

- `cpus: '0.5'`, `memory: 512M` (lightweight; raising is not
  normally necessary)

## Renaming history

- Originally `dockerui/` (port of Portainer + the name Portainer is
  known for).
- Renamed to `containers/` to abstract away the Portainer dependency
  and align with the project naming style (`databases/`,
  `monitoring/`, `passwords/`). The old `DOCKERUI_ADMIN_PASSWORD`
  env var is still honored.
