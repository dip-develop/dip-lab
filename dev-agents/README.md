# dev-agents

Developer workstation container for DIP-Lab. Bundles the opencode
CLI (with multi-agent config), Flutter SDK, Dart, and the standard
PostgreSQL / MySQL / Redis CLI tools.
Runs `opencode serve` as its main process on port **4096** (default
bound to `127.0.0.1`).

The container ships with the `default` profile and starts alongside
the other lab services. If you switched to a smaller profile (e.g.
`core` or `no-ai`), start it explicitly:

```bash
cp dev-agents/.env.example dev-agents/.env
# edit dev-agents/.env: set DEVELOP_UID, DEVELOP_GID,
# OPENCODE_SERVER_PASSWORD, TEST_*_PASSWORD (from databases/.env)
./manager.sh start dev-agents
./manager.sh logs dev-agents --tail 50
```

The web UI is then at `http://127.0.0.1:4096` (change `BIND_IP` in
`.env` if you need LAN access and trust the LAN).

## What's in the image

- Debian Bookworm slim base
- Non-root `develop` user, UID/GID passed in as build args (matches the
  host user that owns the bind-mounted directories)
- Flutter SDK (stable channel)
- Dart (bundled with Flutter)
- `opencode` CLI installed via the official installer (version
  pinning supported via the `OPENCODE_VERSION` build arg)
- Chromium + GTK for `flutter test` web integration tests
- `tmux`, `git`, `gh`, `openssh-client`, `clang`/`cmake`/`ninja-build`/`pkg-config`
  build toolchain for ad-hoc work
- DB clients: `psql`, `mysql`, `mariadb`, `redis-cli`

## Files in this directory

| File | Purpose |
|---|---|
| `Dockerfile` | Image build (see args above) |
| `docker-compose.yml` | Service definition, joins the `internal` network |
| `.env.example` | Template - copy to `.env` and fill in |
| `setup.sh` | Creates `data/config/agents/` if missing |
| `AGENTS.md` | Read by opencode when you open a project - agent rules |
| `data/config/opencode.jsonc` | Multi-agent config: orchestrator, coder, reviewer, tester, planner, marketing, writer. Bind-mounted to `~/.config/opencode` (read-write) |
| `data/config/agents/` | Per-agent system prompts (bind-mounted read-write so you can edit from the host) |

## What the agents can do

- Read your source tree at `/home/develop/projects` (a bind mount of
  `./data/projects` - point your repo there via `.env` or a compose
  override)
- Use the Dart language server and the `dart` MCP server for analysis,
  pub search, running tests
- Reach other DIP-Lab services by hostname (see `AGENTS.md` for the
  hostname table)
- Run `git` operations inside the working tree
- **Connect to the shared PostgreSQL, MySQL, and Redis instances, but
  only as the `TEST_*` users and only on `dev_test_*` databases.**
  See "Database isolation" below.
- Install packages/tools inside the container via passwordless
  `sudo` (e.g. `sudo apt-get install <pkg>`)

## Database isolation (read this before enabling DB access)

The container joins the shared `database` Docker network so its
agents can run integration tests against real PostgreSQL / MySQL /
Redis. Access is **scoped** so a misbehaving agent cannot damage
the production data of any other DIP-Lab service:

- The `databases` stack creates dedicated **test users**
  (`dev_test`) on first start, with grants limited to databases
  whose name starts with `dev_test_`. The test user has **no
  privileges on `app`, `gallery`, `automation`, `docs`, `cloud`,
  `ccnet_db`, `seafile_db`, `seahub_db`, or any other prod DB**.
- Redis uses a dedicated DB index (`TEST_REDIS_DB`, default `15`).
  Prod keys live in indices `0`-`14` and are unreachable from the
  test index.
- The container has a `db-safe` wrapper installed at
  `/home/develop/.local/bin`, symlinked over `psql` / `mysql` /
  `mariadb` / `redis-cli`. It refuses (with a clear error and
  non-zero exit) to connect to a non-`dev_test_` database or a
  non-`TEST_REDIS_DB` Redis index. The wrapper can be disabled
  per-command with `DBSAFE=0 <cmd>` or globally with
  `DB_SAFETY_GUARD=false` in this `.env`.

To enable DB access, fill the test creds in both files with the
same values:

```bash
# 1. In databases/.env: generate the test passwords
openssl rand -hex 24   # copy into TEST_POSTGRES_PASSWORD
openssl rand -hex 24   # copy into TEST_MYSQL_PASSWORD
# TEST_REDIS_PASSWORD can be a copy of REDIS_PASSWORD

# 2. In dev-agents/.env: mirror the values (manager.sh does not
# copy them automatically - you do it by hand so secrets stay out
# of any logs / completion suggestions).
TEST_POSTGRES_USER=dev_test
TEST_POSTGRES_PASSWORD=<same value as databases/.env>
TEST_POSTGRES_DB=dev_test_main
TEST_MYSQL_USER=dev_test
TEST_MYSQL_PASSWORD=<same value as databases/.env>
TEST_MYSQL_DB=dev_test_main
TEST_REDIS_DB=15
TEST_REDIS_PASSWORD=<same value as databases/.env>
```

After a `databases` first start with these values, the test user
and a pre-created `dev_test_main` database exist. The agent can
then `CREATE DATABASE dev_test_<feature>` for a clean per-feature
test state, and `DROP DATABASE` it when done.

## What the agents cannot do

- No `docker` / `docker compose` (the binary is not even installed)
- No `systemctl` / firewall commands
- No pushing to `main`
- No reading `*.env`, `*.key`, `*.pem`, SSH keys, or WireGuard configs
- No editing files outside `/home/develop/projects` (other than the
  opencode config under `data/config/`, which is rw)
- No connecting to a non-`dev_test_` database (enforced at both the
  server side by the test-user grants and at the client side by the
  `db-safe` wrapper)

## Hardening

Same posture as every other DIP-Lab service, with one deliberate
exception:
- `no-new-privileges` is deliberately NOT set (it would block setuid
  elevation and break the in-image passwordless `sudo` that agents use
  for package installs); the rest of the posture still applies
- Resource caps: 4 CPU, 6 GB RAM, 512 PIDs
- No `docker.sock` mount, no `--privileged`, no `cap_add`
- Port 4096 bound to `127.0.0.1` by default; password-protected at the
  application layer (`OPENCODE_SERVER_PASSWORD`)
- Database access is server-side scoped to `dev_test_*` databases
  (test user) / `TEST_REDIS_DB` index (Redis), and client-side gated
  by the `db-safe` wrapper on PATH.

## Customizing model IDs

`data/config/opencode.jsonc` ships with `<set-...-model-id>` placeholders.
After starting the container and opening the web UI:

1. Run `/connect` and pick your model provider.
2. Run `/models` to list the real model IDs your provider offers.
3. Replace the placeholders in `data/config/opencode.jsonc` (it is
   bind-mounted read-write from the host - edit on the host, then
   reopen the project in opencode or restart the container to pick
   the changes up).

## Differences from a stock opencode install

- Always-on `opencode serve` (port 4096), not the TUI. Drop into a normal
  shell with `docker exec -it dev-agents tmux attach -t dev` for ad-hoc
  work.
- Multi-agent config committed to the repo so the team shares one
  orchestrator/coder/review split. Override per-project with a project
  local `.opencode/opencode.json`.
- Permission baseline blocks destructive shell and secret access by
  default; loosen in your fork as needed.
