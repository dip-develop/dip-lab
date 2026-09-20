---
description: Executes one narrow coding step (one file/function). Use for implementation.
mode: subagent
model: opencode-go/qwen3.8-flash
hidden: true
permissions:
  - action: edit
    resource: "*"
    effect: allow
  - action: subagent
    resource: "*"
    effect: deny
  # webfetch accepts only a flat action, not patterns.
  - action: webfetch
    resource: "*"
    effect: allow
  - action: shell
    resource: "*"
    effect: ask
  - action: shell
    resource: "ls"
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
    resource: "xargs *"
    effect: allow
  - action: shell
    resource: "tail *"
    effect: allow
  - action: shell
    resource: "grep *"
    effect: allow
  - action: shell
    resource: "rg *"
    effect: allow
  - action: shell
    resource: "sed *"
    effect: allow
  # Code inspection (line-length/field analysis over files) -- parity
  # with the same trust level already granted in orchestrator/reviewer/
  # baseline. docker remains unlisted on purpose: it is not installed
  # in this container and AGENTS.md routes such needs to the operator.
  - action: shell
    resource: "awk *"
    effect: allow
  - action: shell
    resource: "find *"
    effect: allow
  - action: shell
    resource: "stat *"
    effect: allow
  - action: shell
    resource: "mkdir *"
    effect: allow
  - action: shell
    resource: "less *"
    effect: allow
  - action: shell
    resource: "sort *"
    effect: allow
  # No blanket "rm *": unlike every other tool here, delete has no
  # undo, and combined with "cd *": allow a bare "rm *" would let
  # coder delete outside the current project tree (~/.pub-cache,
  # ~/.ssh, sibling projects under /home/develop/projects/**). Scope
  # it to relative paths inside the current project instead; anything
  # absolute or reaching for a parent dir falls through to "*": ask.
  - action: shell
    resource: "rm ./*"
    effect: allow
  - action: shell
    resource: "rm -r ./*"
    effect: allow
  - action: shell
    resource: "rm -rf ./*"
    effect: allow
  - action: shell
    resource: "rm *..*"
    effect: ask
  - action: shell
    resource: "rm /*"
    effect: ask
  - action: shell
    resource: "rm -r /*"
    effect: ask
  - action: shell
    resource: "rm -rf /*"
    effect: ask
  - action: shell
    resource: "uniq *"
    effect: allow
  - action: shell
    resource: "wc *"
    effect: allow
  - action: shell
    resource: "printf *"
    effect: allow
  - action: shell
    resource: "echo *"
    effect: allow
  - action: shell
    resource: "sleep"
    effect: allow
  - action: shell
    resource: "sleep *"
    effect: allow
  - action: shell
    resource: "cp *"
    effect: allow
  - action: shell
    resource: "pwd"
    effect: allow
  - action: shell
    resource: "git *"
    effect: allow
  - action: shell
    resource: "gh *"
    effect: allow
  # Same destructive/history-rewriting carve-outs as orchestrator --
  # a bare "git *": allow would otherwise silently open these too.
  - action: shell
    resource: "git reset*--hard*"
    effect: ask
  - action: shell
    resource: "git -C * reset*--hard*"
    effect: ask
  - action: shell
    resource: "git clean*-f*"
    effect: ask
  - action: shell
    resource: "git -C * clean*-f*"
    effect: ask
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
  - action: shell
    resource: "git update-ref*"
    effect: deny
  - action: shell
    resource: "git -C * update-ref*"
    effect: deny
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
    resource: "dart *"
    effect: allow
  - action: shell
    resource: "flutter *"
    effect: allow
  - action: shell
    resource: "serverpod *"
    effect: allow
  - action: shell
    resource: "jaspr *"
    effect: allow
  # env only as a wrapper around already-allowed tools (e.g. unsetting
  # vars before "dart run"): a blanket "env *" would let "env gh pr merge"
  # / "env git push ... main" bypass every anchored deny below.
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
    resource: "cd"
    effect: allow
  - action: shell
    resource: "cd *"
    effect: allow
  - action: shell
    resource: "type *"
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
  # Package installs inside the container are allowed by AGENTS.md;
  # granting them keeps implementation steps from stalling on approval.
  - action: shell
    resource: "sudo apt-get update*"
    effect: allow
  - action: shell
    resource: "sudo apt-get install *"
    effect: allow
  - action: shell
    resource: "sudo apt-get -y install *"
    effect: allow
  - action: shell
    resource: "git push* main*"
    effect: deny
  - action: shell
    resource: "git push* master*"
    effect: deny
  - action: shell
    resource: "git push* develop*"
    effect: deny
  - action: shell
    resource: "git push*--force*"
    effect: deny
  # -f guard anchored to token boundaries; the old "git push*-f*" form
  # also denied legitimate pushes whose branch name merely contains "-f"
  # (e.g. feature/git-flow-*). See notes in opencode.jsonc.
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
  # Branch-deletion pushes are operator actions (git-flow) and would
  # otherwise match only the broad "git *" allow.
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
  # The guards above anchor on "git push", but "git *" allows the
  # "git -C <path> push ..." form too -- mirror the complete deny set,
  # or every protected-push rule is bypassable by prefixing "-C .".
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
  # gh: merging PRs and managing repo secrets/settings are operator actions
  # (Git Flow); last match wins, so these trail the broad "gh *" allow.
  - action: shell
    resource: "gh pr merge*"
    effect: deny
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
    resource: "gh workflow disable*"
    effect: deny
  - action: shell
    resource: "gh workflow delete*"
    effect: deny
  - action: shell
    resource: "gh release delete*"
    effect: deny
  - action: shell
    resource: "gh auth token*"
    effect: deny
  # Best-effort: glob-matching on flags is bypassable (case,
  # --method=X, no space) -- server-side branch protection is the
  # real backstop, same caveat as everywhere else in this file.
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
  # Close is fine (reversible via gh pr reopen); deleting the head branch
  # and printing the raw token are not (see notes in opencode.jsonc).
  - action: shell
    resource: "gh pr close*--delete-branch*"
    effect: deny
  - action: shell
    resource: "gh auth status*--show-token*"
    effect: deny
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

You are the coder subagent. Execute ONE narrow step delegated by orchestrator.

## Rules

- Read the target file(s) first, edit minimally.
- For unfamiliar packages/APIs, resolve questions via docs first (dart/serverpod/jaspr MCP doc tools, README/examples, pub.dev); read sources under ~/.pub-cache only as a last resort, surgically.
- Follow project AGENTS.md and dart analyze/format rules.
- Make the change, verify with dart analyze if relevant.
- Keep scope tight: one file or one function per call. Do not expand scope.
- Return what was changed and next step if blocked.
