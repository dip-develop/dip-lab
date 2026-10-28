# Developer Workstation: Agent Guide

Read by opencode and pi in every session. Role detail lives in the agent prompts, domain detail in skills. Projects may add their own AGENTS.md with stack rules.

## Services and test databases

- For a database or internal service, load the `container-services` skill.
- Only test databases (`dev_test_*`) are allowed.

## Git workflow

`main` is production (tagged), `develop` is integration. Changes reach either branch only through a PR. The operator merges and tags.

| Branch | From | PR into |
|---|---|---|
| `feature/<topic>` | `develop` | `develop` |
| `bugfix/<topic>` | `develop` | `develop` |
| `chore/<topic>` (deps, CI) | `develop` | `develop` |
| `hotfix/<topic>` | `main` | `main` and `develop` (two PRs) |
| `release/<version>` | `develop` | `main` and `develop` (two PRs) |
| `backmerge/<version>` | `main` | `develop` |

1. Branch from the base in the table. In a repo with only `main`, branch from `main` and use `--base main`. Check `git branch -a` first.
2. Commit in small, single-purpose chunks.
3. `git push -u origin <branch>`, then `gh pr create --base <base>`. The base must match the table.
4. PR body: `Refs #<n>`. Use `Closes #<n>` only when the base is the default branch.
5. Stop and summarize. The operator merges, tags and pushes.

Back-merge after every release: `main` must stay a subset of `develop`. Check `git rev-list --count develop..origin/main`. If the count is non-zero and no back-merge PR is open, propose `backmerge/<version>` from `origin/main` into `develop`. Merge releases and hotfixes into `main` with merge commits, never squash. Dependency and CI work targets `develop`.

Never commit or push to `main` or `develop` directly. Never merge, tag, delete branches or force-push. Never open a PR with `main` or `develop` as the head.

## Roadmap and TODO

- Chat history is not durable. Keep state in the repo.
- Roadmap: GitHub issues, one per topic (`gh issue create`). Check `gh issue list` before filing a near-duplicate.
- Current work: `TODO.md` in the project root. One item per line (`- [ ]` or `- [x]`), newest first, about 20 items. Changes ride in the feature branch.
- Multi-step plans get a tracking issue before implementation starts.
- Close an issue only after its implementing PR has merged: `gh issue close <n> --comment "Done in PR #<m>"`.

## Scheduled jobs

Agents may propose a cron job (what it runs, how often). Do not create one. Creating a recurring job is an operator action.

## Never do

- Edit `.env` files, secrets, SSH keys, VPN or firewall config, or anything outside the project directory.
- Read or print secrets: `.env` files, `printenv`, `gh auth token`. `*.env.example` templates are fine.
- Run `docker`, `systemctl` or firewall commands, or touch other services.
- Run destructive statements outside the test databases.

## Package research

Docs first, sources last:

1. Doc tools for the package, if your role has them.
2. The package README, CHANGELOG and `example/`.
3. pub.dev or the project website.

Read `~/.pub-cache` surgically, and only when the docs do not answer. Cite the package, symbol and version. Docs match the resolved version; cached sources may not.

## Shell

- Keep lines flat and single-purpose. Lines starting with `for`, `while`, `if` or `case` always ask: split them into repeated calls.
- Do not put bare `|`, `||` or `&&` inside a quoted regex. Use separate `-e` patterns or the grep tool.
- Poll slow results with repeated `sleep 45` and status calls, not a loop.
- Use `od` for hex dumps. `hexdump` and `xxd` are not installed.

## Testing

- Before calling a change done, run the project's analyze, format and test commands (`dart analyze`, `dart test`, `flutter analyze`, `flutter test`).
- The orchestrator runs `tester` once per batch of edits.
