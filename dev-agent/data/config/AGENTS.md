# Developer Workstation — Agent Guide

Read by opencode in every session in this container. Scope: what agents may do.

## Stack

- Debian Bookworm + Flutter SDK (stable) + Dart + opencode CLI v2 + Node.js 24 LTS.
- `opencode serve --hostname 0.0.0.0 --port 4096`; tmux `dev`; container `dev-agent`.

## Database Quick Reference (Always Available)

Only `dev_test_*` databases are reachable. Prod names (`production`, `app`,
`cloud`, `gallery`) are forbidden — the `db-safe` wrapper refuses them.

| Service | Host | Creds |
|---|---|---|
| PostgreSQL | `postgres:5432` | `$TEST_POSTGRES_USER` / `$TEST_POSTGRES_PASSWORD` / `$TEST_POSTGRES_DB` |
| MySQL | `mysql:3306` | `$TEST_MYSQL_USER` / `$TEST_MYSQL_PASSWORD` / `$TEST_MYSQL_DB` |
| Redis | `redis:6379` | `$TEST_REDIS_PASSWORD`, DB index `$TEST_REDIS_DB` (default 15) |

Creds come from `dev-agent/.env`; `PGPASSWORD`/`MYSQL_PWD`/`REDISCLI_AUTH` are
already exported. The test users hold server-side grants on `dev_test_%` only.

```bash
psql -h postgres -U "$TEST_POSTGRES_USER" -d "$TEST_POSTGRES_DB"   # connect
mysql -h mysql -u "$TEST_MYSQL_USER" "$TEST_MYSQL_DB"
redis-cli -h redis set dev_test:counter 1                          # namespace keys
# one per-feature database, created and dropped through the same test DB:
psql -h postgres -U "$TEST_POSTGRES_USER" -d "$TEST_POSTGRES_DB" -c "CREATE DATABASE dev_test_feature_x;"
psql -h postgres -U "$TEST_POSTGRES_USER" -d "$TEST_POSTGRES_DB" -c "DROP DATABASE dev_test_feature_x;"
```

- Never `DROP`/`TRUNCATE`/`FLUSHDB` a non-`dev_test_` DB or a non-`$TEST_REDIS_DB`
  Redis index. Never `DELETE`/`UPDATE` prod rows. Don't bypass the wrapper
  (`DBSAFE=0`) without operator approval.
- Need a clean slate mid-run? Drop and recreate the test DB — never truncate a
  shared one.

## Network

| Service | URL |
|---|---|
| Automation (n8n) | `http://automation:5678` (`/healthz`) |
| Hermes API Gateway | `http://hermes:8642` (`/health`), dashboard `:9119` |
| PostgreSQL / MySQL | `postgres:5432` / `mysql:3306` (test creds only) |
| Redis | `redis:6379` (test DB index only) |
| opencode UI/API | `http://localhost:4096` (host `${BIND_IP:-127.0.0.1}:4096`, `OPENCODE_SERVER_PASSWORD`) |

Reach other services only over HTTP/TCP from inside the container. Never touch
their Docker containers.

## Docker

No `docker.sock`, no `--privileged`, no `docker`/`docker compose` installed. If a
task seems to need a container build/run, say so — the operator runs it. Never run
`docker`, `systemctl`, or firewall commands. `sudo` is fine for installing
packages inside the container only.

## Git workflow (Git Flow)

`main` = production (tagged), `develop` = integration. Nothing lands on either
except via PR; the operator merges and tags.

| Branch | From | PR into |
|---|---|---|
| `feature/<topic>` | `develop` | `develop` |
| `bugfix/<topic>` | `develop` | `develop` |
| `chore/<topic>` (deps/CI) | `develop` | `develop` |
| `hotfix/<topic>` | `main` | `main` AND `develop` (two PRs) |
| `release/<version>` | `develop` | `main` AND `develop` (two PRs) |
| `backmerge/<version>` | `main` | `develop` |

1. Branch off the table's base. A repo that only has `main` and no `develop`
   is single-branch: branch `feature/*` off `main` and open the PR with
   `--base main`. Check `git branch -a` rather than assuming the two-branch
   flow.
2. Commit in small, single-purpose chunks.
3. `git push -u origin <branch>`, then `gh pr create --base <base>`. **The base
   must match the table** — plain `gh pr create` defaults to the repo default
   branch, which is usually wrong.
4. Stop and summarize; the operator merges, tags and pushes `main`/`develop`.

Every PR body references its issue: `Refs #<n>`, or `Closes #<n>` **only** when
the PR's base is the repo's default branch (the auto-close keyword is inert for
merges into non-default branches).

**Back-merge `main` into `develop` after every release.** `main` must stay a
subset of `develop`'s history. Before starting work, check drift with
`git rev-list --count develop..origin/main`; if non-zero and no back-merge PR is
open, propose one first: cut `backmerge/<version>` from `origin/main`, push, and
open `gh pr create --base develop`. Never `--head main`. Release/hotfix merges
into `main` use merge commits, never squash (squashing rewrites history and
breaks every later back-merge).

**Dependabot & CI maintenance** belongs on `develop`: every ecosystem entry in
`.github/dependabot.yml` needs `target-branch: develop`, and an incoming
dependency/CI PR must never be retargeted onto `main` — redo it on `chore/*`.

### Git flow — never

- Never commit or push directly to `main`/`develop`.
- Never merge into `main`/`develop`, tag a release, delete a branch, or
  force-push. Those are operator actions.
- Never open a PR with `main`/`develop` as the head; `backmerge/*` is the only
  sanctioned path toward `develop`, and branches always come off the table's base.

## Roadmap & TODO

Chat history is not durable — keep state in the repo.

- **Roadmap (long-lived)** → GitHub issues via `gh issue create --repo
  <owner/repo>`: one issue per topic, descriptive title, body with context and
  acceptance criteria. Check `gh issue list` before filing a near-duplicate.
- **Working TODO (current)** → `TODO.md` in the project root: one item per line,
  `- [ ]` / `- [x]`, newest at top, ~20 items max. The planner reads it before
  planning; the orchestrator checks items off as steps land. `TODO.md` changes
  ride in the feature branch, never land directly on `develop`.
- **Multi-step plans** get a tracking issue before coders are dispatched (steps
  as `- [ ]` checkboxes). Once the operator merges, close it explicitly:
  `gh issue close <n> --comment "Done in PR #<m> (<sha>)"` — `Closes #N` in a
  develop-based PR does *not* auto-close.
- Never keep progress only in chat; never duplicate a task in both an issue and
  `TODO.md` without a pointer to the other.

## Scheduled jobs

Creating a recurring job is an operator action, same as installing the
auto-back-merge GitHub Action. Agents may propose a cron job (what it runs, how
often) but must not create one — an unattended run burns a model's own usage cap
with no approval step in the loop.

## Things to never do

- Never edit `.env`, secrets, SSH keys, WireGuard config, or anything outside the
  project directory under `/home/develop/projects`.
- Never push to `main`/`develop` or delete branches.
- Never touch other services' containers; never run `docker`/`systemctl`/
  firewall commands.
- Never read or print secrets: `.env` files, `printenv`, `gh auth token`.
  `*.env.example` templates are fine.
- Never `DELETE FROM <prod_table>` or `UPDATE` prod data.

## Package research policy

Docs first, sources last:

1. MCP doc servers — `dart` (`pub_dev_search`, `read_package_uris`,
   `rip_grep_packages`), `serverpod` (`ask-docs`, `get-guide`, `list-guides`),
   `jaspr` (`list_doc_files`, `read_doc_page`).
2. README, CHANGELOG, `example/`.
3. pub.dev / project website.

Only if docs don't answer: read `~/.pub-cache` **surgically** — search for the
symbol, never browse whole files. Cite package + symbol + version. Rationale:
docs match the resolved version; cached sources may not.

## Shell execution policy: how permissions match a command

The checker splits a shell line into fragments and matches each against the
allow/ask/deny rules. Two rules:

- **Choosing the rule** — for one action + resource pair the *last* match wins.
  Write a catch-all first and the specific rule after it.
- **Combining fragments** — across the fragments of one line the strictest wins:
  any `deny` denies the line, else any `ask` asks, else it runs.

So one unlisted stage inside a pipe asks for the whole line. `&&`, `;`, `||` and
pipes are checked stage by stage, not rejected wholesale — split into separate
calls only when a stage is *not* allow-listed, or you want the approval.

- Lines starting with a shell keyword (`for`, `while`, `if`, `case`) have no
  first command to match, so they always ask in full. Rewrite as repeated
  single-purpose calls, or accept the prompt.
- Poll slow results (CI, long builds) with repeated `sleep 45` then `gh pr view`
  calls — never a shell loop.
- Never put bare `|`, `||` or `&&` characters inside a quoted regex the splitter
  sees (e.g. `grep 'a|b'`). Use separate `-e` patterns or the grep tool.
- Hex dumps: use `od` (coreutils). `hexdump` and `xxd` are **not installed** —
  an allow rule for a missing binary turns a visible prompt into a silent
  exit 127.

## Testing expectations

- Run `dart analyze` and `dart test` (Flutter: `flutter analyze` /
  `flutter test`) before calling a change done — delegate to `tester`.
- DB-backed tests: `dev_test_*` databases with the `TEST_*` creds above, one
  per-feature database (`dev_test_<feature>`), dropped after the run.
