# docs

Paperless-ngx (document management) + Gotenberg (document conversion) +
Tika (text extraction).

| Container | Host port | Internal port | Purpose |
|---|---|---|---|
| `docs` | `${BIND_IP:-0.0.0.0}:8000` | 8000 | Paperless-ngx web UI + API |
| `gotenberg` | (none) | 3000 | LibreOffice / Chromium for PDF conversion |
| `tika` | (none) | 9998 | Apache Tika for OCR + text extraction |

## Networks

- `internal`
- `database` (PostgreSQL + Redis for the consume queue)

## Configuration

- `.env` (template: `.env.example`) — `POSTGRES_PASSWORD`,
  `REDIS_PASSWORD`, plus Paperless-specific variables. The
  PostgreSQL/Redis passwords must match `../databases/.env`.
- `docs/Dockerfile` extends the official Paperless image and adds the
  Tesseract language packs (`deu`, `eng`, `fra`, `ita`, `spa`, `ukr`,
  `osd` by default — edit the Dockerfile to change).

## First-start

- Open `http://<host>:8000` and create the superuser.
- Configure consumption folder paths in the web UI under
  Settings → Administration.
- The default consume folder is `./data/docs/consume/`. Drop a
  scanned PDF there to test the pipeline.

## Data layout

```
data/
└── docs/
    ├── consume/        # drop files here to ingest
    ├── media/          # original + processed documents
    ├── export/         # exports from the web UI
    ├── index/          # Whoosh full-text index
    ├── classification/ # trained auto-classifier models
    └── pgdata/         # NOT used (PostgreSQL is shared, external)
```

## Object storage

`/mnt/object-storage/data/docs` can be mounted in place of `./data/docs`
for large libraries — see the comment block in `docker-compose.yml`.

## Resource caps

- Paperless: `cpus: '2'`, `memory: 2G` (CPU-bound during OCR / Tika)
- Gotenberg: `cpus: '1'`, `memory: 1G`
- Tika: `cpus: '1'`, `memory: 1G`
