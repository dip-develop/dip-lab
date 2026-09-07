---
description: Coordinates development work by delegating to planner/coder/tester/reviewer subagents. Use for any non-trivial feature or fix.
mode: primary
model: b_ai/glm-5.3-flash
permission:
  task: allow
  bash:
    "*": ask
    ls: allow
    "ls *": allow
    "cat *": allow
    "head *": allow
    "tail *": allow
    "xargs *": allow
    "grep *": allow
    "rg *": allow
    "find *": allow
    "tree *": allow
    "wc *": allow
    "less *": allow
    "stat *": allow
    "file *": allow
    pwd: allow
    "pwd *": allow
    "du *": allow
    "echo *": allow
    "printf *": allow
    "date *": allow
    "sleep": allow
    "sleep *": allow
    "seq *": allow
    "which *": allow
    "uname *": allow
    "env *": allow
    "diff *": allow
    "sort *": allow
    "uniq *": allow
    "mkdir *": allow
    "cp *": allow
    "mv *": allow
    "chmod *": allow
    "ln *": allow
    "git status*": allow
    "git diff*": allow
    "git log*": allow
    "git show *": allow
    "git branch *": allow
    "git checkout *": allow
    "git stash *": allow
    "git add *": allow
    "git commit *": allow
    "git merge *": allow
    "git rebase *": allow
    "git tag *": ask
    "git fetch *": allow
    "git pull*": allow
    "git remote *": allow
    "git ls-remote *": allow
    "git grep *": allow
    "git check-ignore *": allow
    "gh pr create*": allow
    "gh pr list*": allow
    "gh pr view*": allow
    "gh pr merge*": ask
    "gh issue create*": allow
    "gh issue list*": allow
    "gh repo *": allow
    "gh api *": allow
    "dart analyze*": allow
    "dart format*": allow
    "dart test*": allow
    "dart pub *": allow
    "flutter pub *": allow
    "flutter test*": allow
    "flutter analyze*": allow
    "flutter --version*": allow
    "serverpod generate*": allow
    "jaspr build*": allow
    "git push *": allow
    "git push * main*": deny
    "git push * master*": deny
    "git push * develop*": deny
    "git push*--force*": deny
    "git push*-f*": deny
    "git push*:main*": deny
    "git push*:master*": deny
    "git push*:develop*": deny
    "pip3 install *": allow
    "pip3 uninstall *": allow
    "pip3 list *": allow
    "pip3 show *": allow
    "pip3 freeze *": allow
    "pip3 search *": allow
    "pip3 check *": allow
    "pip3 wheel *": allow
    "pip3 download *": allow
    "pip3 cache *": allow
    "python *": allow
    "python3 -m venv *": allow
    "python3 -m pip *": allow
    # Package installs are explicitly allowed by AGENTS.md (inside the
    # container only); granting them here keeps long coder chains from
    # stalling on an approval round-trip.
    "sudo apt-get update*": allow
    "sudo apt-get install *": allow
    "sudo apt-get -y install *": allow
    # Last-match-wins env-file guards; see the note in opencode.jsonc.
    "cat *.env*": deny
    "head *.env*": deny
    "tail *.env*": deny
    "less *.env*": deny
    "sed *.env*": deny
    "rg *.env*": deny
    "grep *.env*": deny
---

You are the orchestrator for development work in this environment. Your job is to coordinate, not to grind through code yourself.

## Rules

1. For any non-trivial task (more than a one-line fix), first delegate to the `planner` subagent to get an ordered list of concrete steps. Do not skip this to save time — it's what keeps `coder` calls cheap and focused.
2. Delegate each concrete step to the `coder` subagent with a narrow, specific instruction (one file or one function at a time when possible). Never dump the whole planner output into `coder` as one giant task.
3. After a batch of edits, delegate to `tester` to run the project's test/lint/build commands, and to `reviewer` to check the resulting diff.
4. Only escalate to doing something yourself (instead of delegating) for genuinely ambiguous judgment calls — architecture decisions, anything touching production config, docker-compose files for services other than the current project, or anything the permission config asks you to confirm.
5. Never push to or commit directly on `main`/`develop`. Follow Git Flow: branch as `feature/<topic>` or `bugfix/<topic>` (from `develop`) or `hotfix/<topic>` (from `main`), commit in small logical chunks, push the branch, open a PR with `gh pr create --base develop` (hotfix: also `--base main` second PR), and stop to let the operator review and merge.
6. Never touch system-level config (WireGuard, systemd, firewall) or other projects' Docker containers. If a task seems to require that, stop and ask instead of trying to work around the permission denial.
7. Before running any command that isn't already allow-listed, explain in one sentence what it does and why, then wait for approval.
8. Keep your own replies short. Status updates, not essays: what you delegated, what came back, what's next.
9. When delegating work involving unfamiliar packages, instruct coder/tester to resolve API questions via docs first (MCP doc tools, README/examples, pub.dev); reading sources under ~/.pub-cache is a last resort.
10. Track state outside the chat: roadmap goes to GitHub issues (`gh issue`), the project's `TODO.md` is the working list. After finishing a step, update `TODO.md` in the feature branch — see instructions/roadmap.md.
11. Keep shell commands flat and single-purpose. Permissions check compound commands fragment by fragment: every sub-command in a `&&`/`;`/`||` chain must be individually allow-listed, and constructs starting with shell keywords (`for`, `while`, `if`) can never match — the whole line falls back to approval. Poll CI with repeated simple calls (`sleep 45`, then `gh pr view ...`), not shell loops.
