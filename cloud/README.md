# cloud

Seafile (file sync & share) with memcached.

| Container | Host ports | Internal port | Purpose |
|---|---|---|---|
| `cloud` | 8383, 8386 | 80, 8000 | Seafile web + fileserver |
| `memcached` | (none) | 11211 | Session/object cache for Seafile |

## Networks

- `internal` (for app traffic)
- `database` (for MySQL — Seafile stores `ccnet_db`, `seafile_db`,
  `seahub_db` in the shared MySQL)

## Configuration

- `.env` (template: `.env.example`) — `MYSQL_ROOT_PASSWORD`,
  `MYSQL_PASSWORD`, `REDIS_PASSWORD`, `SEAFILE_ADMIN_PASSWORD`
- These passwords must match the corresponding values in
  `../databases/.env` — Seafile re-uses the shared MySQL and Redis.
- The MySQL `cloud` user is created by `../databases/mysql-init.sql`.

## First-start

- `setup-seafile-mysql.py` runs **only** when `data/cloud/seafile/`
  is empty. Subsequent changes to `SEAFILE_USE_S3`, `REDIS_HOST`, etc.
  in `.env` are NOT applied — runtime config lives in
  `data/cloud/seafile/conf/`.
- Set `SEAFILE_ADMIN_PASSWORD` in `.env` (used during the first-run
  setup). After first start, change the password through the Seafile
  web UI.

## UID / data ownership

The `seafileltd/seafile-mc` image runs as **uid 8000** (NON_ROOT).
`data/cloud/` must be owned by 8000:8000:

```bash
sudo chown -R 8000:8000 data/cloud
```

`manager.sh perm` runs this on every invocation. If `data/cloud/` is
ever owned by another UID, Seafile reports "Commit ... is missing"
errors on every library.

## Object storage

Production data is expected to live on `/mnt/object-storage/data/cloud/`
rather than in `data/cloud/`. The compose file is set up to bind-mount
that path (commented out by default — uncomment to enable). Seafile's
`SEAFILE_USE_S3` / S3 config must be set in `.env` BEFORE first start
to take effect.

## Resource caps

- Seafile: `cpus: '2'`, `memory: 2G`
- memcached: `cpus: '0.5'`, `memory: 256M`
