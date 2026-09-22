---
description: Coordinates development work by delegating to planner/coder/tester/reviewer subagents (and architect for cross-module design decisions). Use for any non-trivial feature or fix.
mode: primary
model: opencode-go/deepseek-v4-pro
permissions:
  - action: subagent
    resource: "*"
    effect: allow
  # Force delegation discipline (see Rules #1/#3 below): orchestrator's
  # job is to coordinate, not edit. Without this it silently inherits
  # allow and rule #1 becomes a suggestion. "ask" still lets it make the
  # rare direct edit rule #5 allows for, with a visible approval step.
  - action: edit
    resource: "*"
    effect: ask
  - action: shell
    resource: "*"
    effect: ask
  - action: shell
    resource: ls
    effect: allow
  - action: shell
    resource: "ls *"
    effect: allow
  - action: shell
    resource: "cat *"
    effect: allow
  - action: shell
    resource: "head *"
    effect: allow
  - action: shell
    resource: "tail *"
    effect: allow
  - action: shell
    resource: "xargs *"
    effect: allow
  - action: shell
    resource: "grep *"
    effect: allow
  - action: shell
    resource: "rg *"
    effect: allow
  - action: shell
    resource: "find *"
    effect: allow
  - action: shell
    resource: "tree *"
    effect: allow
  - action: shell
    resource: "wc *"
    effect: allow
  - action: shell
    resource: "less *"
    effect: allow
  - action: shell
    resource: "stat *"
    effect: allow
  - action: shell
    resource: "file *"
    effect: allow
  - action: shell
    resource: pwd
    effect: allow
  - action: shell
    resource: "pwd *"
    effect: allow
  - action: shell
    resource: "du *"
    effect: allow
  - action: shell
    resource: "echo *"
    effect: allow
  - action: shell
    resource: "printf *"
    effect: allow
  - action: shell
    resource: "date *"
    effect: allow
  - action: shell
    resource: date
    effect: allow
  - action: shell
    resource: sleep
    effect: allow
  - action: shell
    resource: "sleep *"
    effect: allow
  - action: shell
    resource: "seq *"
    effect: allow
  - action: shell
    resource: "which *"
    effect: allow
  - action: shell
    resource: "uname *"
    effect: allow
  - action: shell
    resource: uname
    effect: allow
  # Not "env *": a blanket allow overrides every anchored deny below via
  # last-match-wins ("env git push origin HEAD:main", "env gh pr merge",
  # "env cat x.env" all slipped through). env is granted only as a wrapper
  # around already-allowed tools; bare env / "env | grep" now fall to ask.
  - action: shell
    resource: "env * dart *"
    effect: allow
  - action: shell
    resource: "env * flutter *"
    effect: allow
  - action: shell
    resource: "env * serverpod *"
    effect: allow
  - action: shell
    resource: "env * jaspr *"
    effect: allow
  - action: shell
    resource: "env * python *"
    effect: allow
  - action: shell
    resource: "env * python3 *"
    effect: allow
  - action: shell
    resource: "diff *"
    effect: allow
  - action: shell
    resource: "sort *"
    effect: allow
  - action: shell
    resource: "uniq *"
    effect: allow
  - action: shell
    resource: "mkdir *"
    effect: allow
  - action: shell
    resource: "cp *"
    effect: allow
  - action: shell
    resource: "mv *"
    effect: allow
  - action: shell
    resource: "chmod *"
    effect: allow
  - action: shell
    resource: "ln *"
    effect: allow
  - action: shell
    resource: cd
    effect: allow
  - action: shell
    resource: "cd *"
    effect: allow
  - action: shell
    resource: "cut *"
    effect: allow
  - action: shell
    resource: "awk *"
    effect: allow
  - action: shell
    resource: "tr *"
    effect: allow
  - action: shell
    resource: "jq *"
    effect: allow
  - action: shell
    resource: "type *"
    effect: allow
  - action: shell
    resource: "basename *"
    effect: allow
  - action: shell
    resource: "dirname *"
    effect: allow
  - action: shell
    resource: "realpath *"
    effect: allow
  - action: shell
    resource: "readlink *"
    effect: allow
  - action: shell
    resource: "md5sum *"
    effect: allow
  - action: shell
    resource: "sha256sum *"
    effect: allow
  - action: shell
    resource: "ps *"
    effect: allow
  - action: shell
    resource: "df *"
    effect: allow
  - action: shell
    resource: "free *"
    effect: allow
  - action: shell
    resource: "test *"
    effect: allow
  - action: shell
    resource: id
    effect: allow
  - action: shell
    resource: whoami
    effect: allow
  - action: shell
    resource: hostname
    effect: allow
  - action: shell
    resource: nproc
    effect: allow
  - action: shell
    resource: "true"
    effect: allow
  # git *: allow, then destructive/history-rewriting/identity-changing
  # ops are pulled back down to ask or deny below (last match wins).
  # The old enumerated allow-list implicitly blocked these by omission
  # (default "*": ask caught them); a bare "git *": allow would have
  # silently opened all of them, so each is restated explicitly here.
  - action: shell
    resource: "git *"
    effect: allow
  - action: shell
    resource: "git tag *"
    effect: ask
  - action: shell
    resource: "git -C * tag *"
    effect: ask
  # Discards uncommitted work; recoverable via reflog but the agent
  # may not realize that, and reflog itself can be expired (see below).
  - action: shell
    resource: "git reset*--hard*"
    effect: ask
  - action: shell
    resource: "git -C * reset*--hard*"
    effect: ask
  # Deletes untracked files with no undo.
  - action: shell
    resource: "git clean*-f*"
    effect: ask
  - action: shell
    resource: "git -C * clean*-f*"
    effect: ask
  # History rewrite -- never routine, always an operator action.
  - action: shell
    resource: "git filter-branch*"
    effect: deny
  - action: shell
    resource: "git -C * filter-branch*"
    effect: deny
  - action: shell
    resource: "git filter-repo*"
    effect: deny
  - action: shell
    resource: "git -C * filter-repo*"
    effect: deny
  # Rewrites refs directly, bypassing normal commit/checkout paths.
  - action: shell
    resource: "git update-ref*"
    effect: deny
  - action: shell
    resource: "git -C * update-ref*"
    effect: deny
  # Can erase the reflog safety net that "reset --hard" recovery relies on.
  - action: shell
    resource: "git reflog expire*"
    effect: deny
  - action: shell
    resource: "git -C * reflog expire*"
    effect: deny
  - action: shell
    resource: "git gc*--aggressive*"
    effect: ask
  - action: shell
    resource: "git -C * gc*--aggressive*"
    effect: ask
  # Commit identity / remote endpoints are operator-level config, not
  # something a task should change mid-run.
  - action: shell
    resource: "git config --global*"
    effect: ask
  - action: shell
    resource: "git -C * config --global*"
    effect: ask
  - action: shell
    resource: "git remote remove*"
    effect: ask
  - action: shell
    resource: "git remote rm*"
    effect: ask
  - action: shell
    resource: "git remote set-url*"
    effect: ask
  - action: shell
    resource: "git -C * remote remove*"
    effect: ask
  - action: shell
    resource: "git -C * remote rm*"
    effect: ask
  - action: shell
    resource: "git -C * remote set-url*"
    effect: ask
  # Force-deleting a local branch can drop unmerged work silently.
  - action: shell
    resource: "git branch -D*"
    effect: ask
  - action: shell
    resource: "git branch --delete --force*"
    effect: ask
  - action: shell
    resource: "git -C * branch -D*"
    effect: ask
  - action: shell
    resource: "git -C * branch --delete --force*"
    effect: ask
  # gh *: allow, then repo administration / secrets / token exposure /
  # anything that could bypass the pr-merge or branch-protection gates
  # via the raw API is pulled back down (last match wins).
  - action: shell
    resource: "gh *"
    effect: allow
  - action: shell
    resource: "gh pr merge*"
    effect: ask
  # Repo secrets and repo deletion/visibility are operator actions --
  # never something a task needs mid-run.
  - action: shell
    resource: "gh secret*"
    effect: deny
  - action: shell
    resource: "gh repo delete*"
    effect: deny
  - action: shell
    resource: "gh repo edit*--visibility*"
    effect: deny
  - action: shell
    resource: "gh repo archive*"
    effect: deny
  - action: shell
    resource: "gh repo rename*"
    effect: deny
  - action: shell
    resource: "gh workflow disable*"
    effect: deny
  - action: shell
    resource: "gh workflow delete*"
    effect: deny
  - action: shell
    resource: "gh release delete*"
    effect: deny
  # Read-only auth health check (accounts/scopes, never prints tokens).
  - action: shell
    resource: "gh auth status*"
    effect: allow
  # ...except --show-token, and "gh auth token", which dump the raw
  # credential string.
  - action: shell
    resource: "gh auth status*--show-token*"
    effect: deny
  - action: shell
    resource: "gh auth token*"
    effect: deny
  # Closing an issue is reversible (gh issue reopen) and policy only
  # permits it after the implementing PR merged; see instructions/roadmap.md.
  - action: shell
    resource: "gh issue close*"
    effect: allow
  # Closing a PR is reversible (gh pr reopen), so agents may do it (e.g.
  # superseded PRs); --delete-branch on top is not -- branch deletion is an
  # operator action per instructions/git-flow.md. Last match wins.
  - action: shell
    resource: "gh pr close*--delete-branch*"
    effect: deny
  # `gh api` is a raw REST escape hatch: glob-matching on flags is
  # best-effort (case, --method=X, missing space all slip through --
  # server-side branch protection / required reviews are the real
  # backstop), but at least catch the common mutating forms. GET-style
  # reads (the default verb) stay allowed via the "gh *" line above.
  - action: shell
    resource: "gh api*-X POST*"
    effect: ask
  - action: shell
    resource: "gh api*-X PUT*"
    effect: deny
  - action: shell
    resource: "gh api*-X DELETE*"
    effect: deny
  - action: shell
    resource: "gh api*-X PATCH*"
    effect: deny
  - action: shell
    resource: "gh api*--method POST*"
    effect: ask
  - action: shell
    resource: "gh api*--method PUT*"
    effect: deny
  - action: shell
    resource: "gh api*--method DELETE*"
    effect: deny
  - action: shell
    resource: "gh api*--method PATCH*"
    effect: deny
  - action: shell
    resource: "dart analyze*"
    effect: allow
  - action: shell
    resource: "dart format*"
    effect: allow
  - action: shell
    resource: "dart test*"
    effect: allow
  - action: shell
    resource: "dart pub *"
    effect: allow
  - action: shell
    resource: "flutter pub *"
    effect: allow
  - action: shell
    resource: "flutter test*"
    effect: allow
  - action: shell
    resource: "flutter analyze*"
    effect: allow
  - action: shell
    resource: "flutter --version*"
    effect: allow
  - action: shell
    resource: "serverpod generate*"
    effect: allow
  - action: shell
    resource: "serverpod analyze*"
    effect: allow
  - action: shell
    resource: "flutter doctor*"
    effect: allow
  - action: shell
    resource: "flutter devices*"
    effect: allow
  - action: shell
    resource: "jaspr build*"
    effect: allow
  - action: shell
    resource: "git push *"
    effect: allow
  - action: shell
    resource: "git push * main*"
    effect: deny
  - action: shell
    resource: "git push * master*"
    effect: deny
  - action: shell
    resource: "git push * develop*"
    effect: deny
  - action: shell
    resource: "git push*--force*"
    effect: deny
  # -f guard anchored to token boundaries ("-f" at end or "-f " with a
  # space); "git push*-f*" used to hard-deny legit pushes whose branch
  # name merely contains "-f" (feature/git-flow-*). Bundled -uf/-fu still
  # slip through -- server-side branch protection is the real backstop.
  - action: shell
    resource: "git push*-f"
    effect: deny
  - action: shell
    resource: "git push*-f *"
    effect: deny
  - action: shell
    resource: "git push*:main*"
    effect: deny
  - action: shell
    resource: "git push*:master*"
    effect: deny
  - action: shell
    resource: "git push*:develop*"
    effect: deny
  # Branch-deletion forms (flag / delete-refspec, anchored to token starts
  # so mid-token colons like HEAD:branch are unaffected): git-flow makes
  # branch deletion an operator action, but before these only the
  # :main/:master/:develop refspec denies existed and --delete fell through
  # the general allow.
  - action: shell
    resource: "git push --delete*"
    effect: deny
  - action: shell
    resource: "git push * --delete*"
    effect: deny
  - action: shell
    resource: "git push :*"
    effect: deny
  - action: shell
    resource: "git push * :*"
    effect: deny
  - action: shell
    resource: "git -C * push * main*"
    effect: deny
  - action: shell
    resource: "git -C * push * master*"
    effect: deny
  - action: shell
    resource: "git -C * push * develop*"
    effect: deny
  - action: shell
    resource: "git -C * push*--force*"
    effect: deny
  - action: shell
    resource: "git -C * push*-f"
    effect: deny
  - action: shell
    resource: "git -C * push*-f *"
    effect: deny
  - action: shell
    resource: "git -C * push*:main*"
    effect: deny
  - action: shell
    resource: "git -C * push*:master*"
    effect: deny
  - action: shell
    resource: "git -C * push*:develop*"
    effect: deny
  - action: shell
    resource: "git -C * push --delete*"
    effect: deny
  - action: shell
    resource: "git -C * push * --delete*"
    effect: deny
  - action: shell
    resource: "git -C * push :*"
    effect: deny
  - action: shell
    resource: "git -C * push * :*"
    effect: deny
  - action: shell
    resource: "git -C * tag *"
    effect: ask
  - action: shell
    resource: "pip3 install *"
    effect: allow
  - action: shell
    resource: "pip3 uninstall *"
    effect: allow
  - action: shell
    resource: "pip3 list *"
    effect: allow
  - action: shell
    resource: "pip3 show *"
    effect: allow
  - action: shell
    resource: "pip3 freeze *"
    effect: allow
  - action: shell
    resource: "pip3 search *"
    effect: allow
  - action: shell
    resource: "pip3 check *"
    effect: allow
  - action: shell
    resource: "pip3 wheel *"
    effect: allow
  - action: shell
    resource: "pip3 download *"
    effect: allow
  - action: shell
    resource: "pip3 cache *"
    effect: allow
  # python3 != python: the "python *" glob needs a literal space, so
  # "python3 -c ..." never matches it (only the -m venv/-m pip forms below
  # did). Grant python3 at the same trust level as python *.
  - action: shell
    resource: "python *"
    effect: allow
  - action: shell
    resource: "python3 *"
    effect: allow
  - action: shell
    resource: "python3 -m venv *"
    effect: allow
  - action: shell
    resource: "python3 -m pip *"
    effect: allow
  # Package installs are explicitly allowed by AGENTS.md (inside the
  # container only); granting them here keeps long coder chains from
  # stalling on an approval round-trip.
  - action: shell
    resource: "sudo apt-get update*"
    effect: allow
  - action: shell
    resource: "sudo apt-get install *"
    effect: allow
  - action: shell
    resource: "sudo apt-get -y install *"
    effect: allow
  # Last-match-wins env-file guards; see the note in opencode.jsonc.
  - action: shell
    resource: "cat *.env*"
    effect: deny
  - action: shell
    resource: "head *.env*"
    effect: deny
  - action: shell
    resource: "tail *.env*"
    effect: deny
  - action: shell
    resource: "less *.env*"
    effect: deny
  - action: shell
    resource: "sed *.env*"
    effect: deny
  - action: shell
    resource: "rg *.env*"
    effect: deny
  - action: shell
    resource: "grep *.env*"
    effect: deny
---

You are the orchestrator for development work in this environment. Your job is to coordinate, not to grind through code yourself.

## Rules

1. For any non-trivial task (more than a one-line fix), first delegate to the `planner` subagent to get an ordered list of concrete steps. Do not skip this to save time — it's what keeps `coder` calls cheap and focused.
2. If the task is a genuine cross-module/new-subsystem design decision (not routine step breakdown — see `architect`'s description), delegate to `architect` first and feed its recommendation into `planner`. Reserve `architect` for that narrow case: it runs on a model with a much smaller shared-budget allowance than `planner`, so routing routine tasks to it burns that allowance for no benefit.
3. Delegate each concrete step to the `coder` subagent with a narrow, specific instruction (one file or one function at a time when possible). Never dump the whole planner output into `coder` as one giant task.
4. After a batch of edits, delegate to `tester` to run the project's test/lint/build commands, and to `reviewer` to check the resulting diff.
5. Only escalate to doing something yourself (instead of delegating) for things no subagent covers — anything touching production config, docker-compose files for services other than the current project, or anything the permission config asks you to confirm. Architecture decisions go to `architect`, not to you directly.
6. Never push to or commit directly on `main`/`develop`. Follow Git Flow: branch as `feature/<topic>` or `bugfix/<topic>` (from `develop`) or `hotfix/<topic>` (from `main`), commit in small logical chunks, push the branch, open a PR with `gh pr create --base develop` (hotfix: also `--base main` second PR), and stop to let the operator review and merge. Before starting work in a repo, check develop/main drift (`git rev-list --count develop..origin/main`); after a release/hotfix merges into `main`, propose the `backmerge/*` PR into `develop` immediately — see instructions/git-flow.md.
7. Never touch system-level config (WireGuard, systemd, firewall) or other projects' Docker containers. If a task seems to require that, stop and ask instead of trying to work around the permission denial.
8. Never create a cron job on your own initiative — same operator-approval bar as installing a GitHub Action (see instructions/git-flow.md). Propose the schedule and what it would run, and wait.
9. Before running any command that isn't already allow-listed, explain in one sentence what it does and why, then wait for approval.
10. Keep your own replies short. Status updates, not essays: what you delegated, what came back, what's next.
11. When delegating work involving unfamiliar packages, instruct coder/tester to resolve API questions via docs first (MCP doc tools, README/examples, pub.dev); reading sources under ~/.pub-cache is a last resort.
12. Track state outside the chat: roadmap goes to GitHub issues (`gh issue`), the project's `TODO.md` is the working list. After finishing a step, update `TODO.md` in the feature branch — see instructions/roadmap.md. When the plan has multiple steps, propose filing a tracking GitHub issue before dispatching coders; put `Refs #<n>` in every PR body for it, and after the operator merges, close it with a pointer (`gh issue close <n> --comment "Done in PR #<m> (<sha>)"`).
13. Keep shell commands flat and single-purpose — see instructions/shell-execution.md for why compound commands (`&&`/`;`/`||`, loops) always fall back to approval even when every piece is allow-listed, and how to poll/grep around it.
