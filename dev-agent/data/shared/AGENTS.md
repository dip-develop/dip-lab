# Developer Workstation: Agent Guide

Read by opencode and pi in every session. Keep it short. Role-specific detail lives
in the agent prompts, and domain detail lives in skills. Projects may add
their own AGENTS.md with stack rules.

## Services and test databases

If a task needs a database or an internal service, load the
`container-services` skill. Only test databases (`dev_test_*`) are allowed.

## Git workflow (Git Flow)

`main` = production (tagged), `develop` = integration. Nothing lands on either
except via PR. The operator merges and tags.

| Branch | From | PR into |
|---|---|---|
| `feature/<topic>` | `develop` | `develop` |
| `bugfix/<topic>` | `develop` | `develop` |
| `chore/<topic>` (deps/CI) | `develop` | `develop` |
| `hotfix/<topic>` | `main` | `main` AND `develop` (two PRs) |
| `release/<version>` | `develop` | `main` AND `develop` (two PRs) |
| `backmerge/<version>` | `main` | `develop` |

1. Branch off the table's base. A repo with only `main` is single-branch:
   branch off `main` and use `--base main`. Check `git branch -a` first.
2. Commit in small, single-purpose chunks.
3. `git push -u origin <branch>`, then `gh pr create --base <base>`. The base
   must match the table.
4. PR body references its issue: `Refs #<n>`. Use `Closes #<n>` only when the
   base is the default branch.
5. Stop and summarize. The operator merges, tags and pushes.

Back-merge after every release: `main` must stay a subset of `develop`. Check
`git rev-list --count develop..origin/main`. If it is non-zero and no back-merge
PR is open, propose `backmerge/<version>` from `origin/main` into `develop`.
Release and hotfix merges into `main` use merge commits, never squash.
Dependency and CI maintenance targets `develop`.

Never commit or push directly to `main`/`develop`. Never merge, tag, delete
branches or force-push. Never open a PR with `main`/`develop` as the head.

## Roadmap & TODO

Chat history is not durable. Keep state in the repo.

- Roadmap: GitHub issues (`gh issue create`), one per topic. Check
  `gh issue list` before filing a near-duplicate.
- Current work: `TODO.md` in the project root. One item per line, `- [ ]` or
  `- [x]`, newest first, about 20 items max. Changes ride in the feature branch.
- Multi-step plans get a tracking issue before implementation starts.
- Close an issue only after its implementing PR has merged:
  `gh issue close <n> --comment "Done in PR #<m>"`.

## Scheduled jobs

Agents may propose a cron job (what it runs, how often). They must not create
one. Creating a recurring job is an operator action.

## Things to never do

- Edit `.env` files, secrets, SSH keys, VPN or firewall config, or anything
  outside the project directory.
- Read or print secrets: `.env` files, `printenv`, `gh auth token`.
  `*.env.example` templates are fine.
- Run `docker`, `systemctl` or firewall commands, or touch other services.
- Run destructive statements outside the test databases.

## Package research policy

Docs first, sources last:

1. Doc tools for the package, if your role has them enabled.
2. The package README, CHANGELOG and `example/`.
3. pub.dev or the project website.

Read `~/.pub-cache` only surgically and only if the docs do not answer. Cite
the package, symbol and version. Docs match the resolved version. Cached
sources may not.

## Shell execution policy

The permission checker splits a shell line into fragments. Each fragment is
matched against the rules, and the last matching rule wins. Across fragments,
the strictest result wins: any deny denies the line, otherwise any ask asks.

- Keep lines flat and single-purpose. Lines starting with `for`, `while`,
  `if` or `case` always ask. Split them into repeated calls.
- Never put bare `|`, `||` or `&&` inside a quoted regex. Use separate `-e`
  patterns or the grep tool.
- Poll slow results with repeated `sleep 45` and status calls, never a loop.
- Use `od` for hex dumps. `hexdump` and `xxd` are not installed.

## Testing expectations

Before calling a change done, run the project's analyze, format and test
commands (`dart analyze`, `dart test`, `flutter analyze`, `flutter test`). The
orchestrator runs the `tester` once per batch of edits.
