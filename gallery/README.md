# gallery

Immich (self-hosted photo & video backup) — server + machine-learning.

| Container | Host port | Internal port | Purpose |
|---|---|---|---|
| `immich-server` | `${BIND_IP:-0.0.0.0}:2283` | 2283 | API + web UI |
| `immich-ml` | (none) | 3003 | CLIP embeddings, face recognition, etc. |
| `redis` (external) | (none) | 6379 | Job queue |
| `postgres` (external) | (none) | 5432 | Metadata DB |

## Networks

- `internal` (for web + Traefik)
- `database` (for the shared PostgreSQL + Redis)

## Configuration

- `.env` (template: `.env.example`) — `POSTGRES_PASSWORD`,
  `REDIS_PASSWORD`, plus the Immich-specific variables. The
  PostgreSQL/Redis passwords must match `../databases/.env`.
- The `gallery` database is created by `../databases/init.sql`. The
  `pgvector` extension is enabled in the same script.

## Object storage

Immich stores its media in six subdirectories (upload, thumbs, profile,
backups, library, encoded-video). This compose file bind-mounts them
**unconditionally** to `/mnt/object-storage/data/gallery/*` (and the
local `data/gallery/*` paths are commented out). If the object-storage
mount is absent, Docker creates empty root-owned directories — the
gallery service will still start, but uploads will fail until you
either mount object storage or uncomment the local bind paths.

Each subdirectory needs a `.immich` marker file. `manager.sh setup`
creates them automatically when `/mnt/object-storage/data` exists.

## Data layout

```
data/
└── gallery/                 # gitignored, but commented-out fallback path
    ├── upload/
    ├── thumbs/
    ├── profile/
    ├── backups/
    ├── library/
    └── encoded-video/
```

In production, all six live under `/mnt/object-storage/data/gallery/`.

## First-start

- Open `http://<host>:2283`, create the admin user, set up the
  mobile-app pairing (or use the web upload UI to test).
- Initial ML model downloads happen on first use — expect a large
  one-time bandwidth + disk hit.

## Resource caps

- immich-server: `cpus: '2'`, `memory: 2G`
- immich-ml: `cpus: '2'`, `memory: 4G` (ML inference is RAM-heavy;
  raise for large libraries)
