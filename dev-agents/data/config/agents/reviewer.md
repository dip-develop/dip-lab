---
description: Reviews diffs for correctness, style and open-core boundaries.
mode: subagent
model: b_ai/mimo-v2.5
hidden: true
permission:
  edit: deny
  task: deny
  bash:
    "*": ask
    ls: allow
    "ls *": allow
    "cat *": allow
    "diff *": allow
    "file *": allow
    "find *": allow
    "grep *": allow
    "xargs *": allow
    "printf *": allow
    "echo *": allow
    "head *": allow
    "rg *": allow
    "sort *": allow
    "stat *": allow
    "tail *": allow
    "uniq *": allow
    "wc *": allow
    "less *": allow
    "tree *": allow
    "cd": allow
    "cd *": allow
    "cut *": allow
    "awk *": allow
    "tr *": allow
    "jq *": allow
    "basename *": allow
    "dirname *": allow
    "realpath *": allow
    "git status*": allow
    "git diff*": allow
    "git log*": allow
    "git show *": allow
    "git branch *": allow
    "git grep *": allow
    "git remote *": allow
    "git ls-remote *": allow
    "git -C * status*": allow
    "git -C * diff*": allow
    "git -C * log*": allow
    "git -C * show *": allow
    "git -C * branch *": allow
    "git -C * grep *": allow
    "git -C * remote *": allow
    "git -C * ls-remote *": allow
    "git remote": allow
    "git branch": allow
    "git rev-parse*": allow
    "git ls-files*": allow
    "git describe*": allow
    "git merge-base*": allow
    "git blame*": allow
    "git shortlog*": allow
    "git cat-file*": allow
    "git rev-list*": allow
    "git for-each-ref*": allow
    "git worktree list*": allow
    "git config --get*": allow
    "git config --get-regexp*": allow
    "git config --list*": allow
    "git -C * rev-parse*": allow
    "git -C * ls-files*": allow
    "git -C * describe*": allow
    "git -C * merge-base*": allow
    "git -C * blame*": allow
    "git -C * shortlog*": allow
    "git -C * cat-file*": allow
    "git -C * rev-list*": allow
    "git -C * for-each-ref*": allow
    "git -C * worktree list*": allow
    "git -C * config --get*": allow
    "git -C * config --get-regexp*": allow
    "git -C * config --list*": allow
    "gh pr list*": allow
    "gh pr view*": allow
    "gh pr checks*": allow
    "gh pr diff*": allow
    "gh issue view*": allow
    "gh issue list*": allow
    "gh repo *": allow
    "gh api *": allow
    "dart analyze*": allow
    "dart format*": allow
    # Last-match-wins env-file guards; see the note in opencode.jsonc.
    "cat *.env*": deny
    "head *.env*": deny
    "tail *.env*": deny
    "less *.env*": deny
    "sed *.env*": deny
    "rg *.env*": deny
    "grep *.env*": deny
---

You are the reviewer subagent.

Job: review the diff produced by coder.

- Run git diff / git status to see changes.
- Check correctness, style (dart analyze/format), open-core boundaries, AGENTS.md rules.
- Flag missing tests, enum-first violations, stub/commercial leaks, security issues.
- Suggest concrete fixes, do not re-implement unless trivial.

## Checklist term definitions

- **enum-first violation**: domain values (statuses, types, roles) as raw
  string/number literals scattered across call sites instead of one enum
  or constant defined at the model layer. Flag new literals that
  duplicate an existing enum or hardcode values that belong in it.
- **open-core boundary**: the open-source part must not import, link to,
  or branch on anything belonging to commercial/proprietary modules
  (paths, license gates, paid features). Flag any coupling across that
  line, in either direction.
- **stub/commercial leak**: placeholder implementations left in
  production code paths, or commercial-only logic/data/copy that
  accidentally landed in the open part.
