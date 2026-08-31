# monitoring

Prometheus + Grafana + Loki + Promtail + cAdvisor + node-exporter.
Everything is in a single `docker-compose.yml` (no subdirectories).

| Service | Container | Host port | Purpose |
|---|---|---|---|
| Prometheus | `prometheus` | 9090 | Metrics scrape + storage |
| Grafana | `grafana` | 3000 | Dashboards (uses Prometheus + Loki) |
| Loki | `loki` | 3100 | Log aggregation |
| Promtail | `promtail` | (internal) | Ships host + container logs to Loki |
| cAdvisor | `cadvisor` | 8081 | Per-container resource metrics |
| node-exporter | `node-exporter` | 9100 | Host-level metrics |

## Network

All services are on the `monitoring` network (defined inline in this
compose file, NOT pre-created by `manager.sh setup_nets`). Prometheus
scrapes the other services via the `internal` Docker network by their
container name.

## Configuration

- `.env` (template: `.env.example`) — `GRAFANA_PASSWORD`
- Prometheus scrapes its targets from the `internal` network
  (container names: `prometheus`, `postgres`, `mysql`, `redis`, etc.)

## First-start

- Grafana is on `0.0.0.0:3000` with `admin` / `$GRAFANA_PASSWORD`.
- Add Prometheus as a Grafana data source:
  `http://prometheus:9090`
- Add Loki as a Grafana data source:
  `http://loki:3100`
- Import dashboards by ID (community Prometheus / Loki dashboards).

## Resource caps

Each service has `deploy.resources.limits` set conservatively so the
monitoring stack itself doesn't dominate host resources.
