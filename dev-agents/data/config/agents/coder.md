---
description: Executes one narrow coding step (one file/function). Use for implementation.
mode: subagent
model: b_ai/qwen3.8-flash
hidden: true
permission:
  edit: allow
  task: deny
  # webfetch accepts only a flat action, not patterns.
  webfetch: allow
  bash:
    "*": ask
    ls: allow
    "ls *": allow
    "cat *": allow
    "head *": allow
    "xargs *": allow
    "tail *": allow
    "grep *": allow
    "rg *": allow
    "sed *": allow
    "find *": allow
    "stat *": allow
    "mkdir *": allow
    "less *": allow
    "sort *": allow
    "rm *": allow
    "uniq *": allow
    "wc *": allow
    "printf *": allow
    "echo *": allow
    "sleep": allow
    "sleep *": allow
    "cp *": allow
    pwd: allow
    "git *": allow
    "gh *": allow
    "dart *": allow
    "flutter *": allow
    "serverpod *": allow
    "jaspr *": allow
    # env only as a wrapper around already-allowed tools (e.g. unsetting
    # vars before "dart run"): a blanket "env *" would let "env gh pr merge"
    # / "env git push ... main" bypass every anchored deny below.
    "env * dart *": allow
    "env * flutter *": allow
    "env * serverpod *": allow
    "env * jaspr *": allow
    "cd": allow
    "cd *": allow
    "type *": allow
    "realpath *": allow
    "readlink *": allow
    "md5sum *": allow
    "sha256sum *": allow
    # Package installs inside the container are allowed by AGENTS.md;
    # granting them keeps implementation steps from stalling on approval.
    "sudo apt-get update*": allow
    "sudo apt-get install *": allow
    "sudo apt-get -y install *": allow
    "git push* main*": deny
    "git push* master*": deny
    "git push* develop*": deny
    "git push*--force*": deny
    # -f guard anchored to token boundaries; the old "git push*-f*" form
    # also denied legitimate pushes whose branch name merely contains "-f"
    # (e.g. feature/git-flow-*). See notes in opencode.jsonc.
    "git push*-f": deny
    "git push*-f *": deny
    "git push*:main*": deny
    "git push*:master*": deny
    "git push*:develop*": deny
    # Branch-deletion pushes are operator actions (git-flow) and would
    # otherwise match only the broad "git *" allow.
    "git push --delete*": deny
    "git push * --delete*": deny
    "git push :*": deny
    "git push * :*": deny
    # The guards above anchor on "git push", but "git *" allows the
    # "git -C <path> push ..." form too -- mirror the complete deny set,
    # or every protected-push rule is bypassable by prefixing "-C .".
    "git -C * push * main*": deny
    "git -C * push * master*": deny
    "git -C * push * develop*": deny
    "git -C * push*--force*": deny
    "git -C * push*-f": deny
    "git -C * push*-f *": deny
    "git -C * push*:main*": deny
    "git -C * push*:master*": deny
    "git -C * push*:develop*": deny
    "git -C * push --delete*": deny
    "git -C * push * --delete*": deny
    "git -C * push :*": deny
    "git -C * push * :*": deny
    # gh: merging PRs and managing repo secrets/settings are operator actions
    # (Git Flow); last match wins, so these trail the broad "gh *" allow.
    "gh pr merge*": deny
    "gh secret*": deny
    "gh repo delete*": deny
    # Close is fine (reversible via gh pr reopen); deleting the head branch
    # and printing the raw token are not (see notes in opencode.jsonc).
    "gh pr close*--delete-branch*": deny
    "gh auth status*--show-token*": deny
    # Last-match-wins env-file guards; see the note in opencode.jsonc.
    "cat *.env*": deny
    "head *.env*": deny
    "tail *.env*": deny
    "less *.env*": deny
    "sed *.env*": deny
    "rg *.env*": deny
    "grep *.env*": deny
---

You are the coder subagent. Execute ONE narrow step delegated by orchestrator.

## Rules

- Read the target file(s) first, edit minimally.
- For unfamiliar packages/APIs, resolve questions via docs first (dart/serverpod/jaspr MCP doc tools, README/examples, pub.dev); read sources under ~/.pub-cache only as a last resort, surgically.
- Follow project AGENTS.md and dart analyze/format rules.
- Make the change, verify with dart analyze if relevant.
- Keep scope tight: one file or one function per call. Do not expand scope.
- Return what was changed and next step if blocked.
