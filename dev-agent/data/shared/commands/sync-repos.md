---
description: Switch the current project's repos to their flow base and fast-forward them
---

**Dirty tree is a hard stop.** Before switching any repo's branch, run `git status
--porcelain` there. If the output is non-empty, do NOT switch: leave the repo on its
current branch and report it as dirty/skipped. Never stash, never discard, never force
a checkout - no `git checkout -f`, no `git switch --force`.

Sync every git repo in the resolved scope to its flow base: `develop` where that
branch exists, `main` where it does not - never create `develop`. Note that in a
single-branch repo `main` is the release branch, so the fallback checks out and
fast-forwards it; never push, and report rather than switch when the operator has
it checked out.

Resolve the scope first. The default scope is the current chat project itself:
the project root the chat was opened in, derived at runtime; never assume a
literal path. Repos inside that scope are the project root (when it has a
`.git` entry) plus each subdirectory with a `.git` entry (nested subprojects).
Never climb above the project directory - sibling projects, other repos in the
home folder or anywhere else on disk are out of scope by default, even when
they sit next to the current project.

`$ARGUMENTS`, when given, overrides the default: it is the directory holding
the repos to sync - use it and skip discovery. Verify the directory contains at
least one subdirectory with a `.git` entry (or is itself a git repo). If it does
not, stop and ask the operator for the correct directory - do not guess or
default to any fixed path. The same applies to an empty `$ARGUMENTS` when the
project root is not a git repo and has no git subdirectories: ask, never walk
to a parent directory looking for repos.

1. Enumerate the scope: check the scope directory itself (the project root, or
   `$ARGUMENTS` when given) and each of its subdirectories for a `.git` entry.
   Discover the repos this way - the set changes over time, so do not work from
   a hardcoded list. Do not list anything above the scope directory.
2. Run `git branch -a` in each repo and pick the flow base from that output:
   remote-only `origin/develop` / `origin/main` count, since a fresh clone has no
   local branches. A repo is in scope when EITHER branch exists.
3. `develop` present (local or `origin/develop`) -> the sync base is `develop`, as
   in step 4. No `develop` anywhere -> the repo is single-branch: fall back to
   `main` and run the same steps against `main` / `origin/main`. Do NOT create
   `develop` in any repo, and do not touch a repo that has neither branch: skip
   it and report it as skipped.
4. From here on `<base>` is whatever step 3 resolved: `develop` or `main`.
   In-scope repo: `git fetch`, confirm the working tree is clean (see the guard
   above), then `git checkout <base>`. If `<base>` exists only as `origin/<base>`,
   a plain `git checkout <base>` creates the local branch tracking the remote.
5. Fast-forward with `git merge --ff-only origin/<base>`. If `--ff-only` fails the
   history has diverged: report it and do NOT force, rebase, or reset.
6. Measure drift with `git rev-list --left-right --count <base>...origin/<base>`.
   The left number is commits only in local `<base>` (ahead / unpushed), the right
   is commits only in `origin/<base>` (behind). After a successful `--ff-only` both
   are normally `0 0`; the left number is the signal that there is unpushed work.
7. No remote: if `git remote get-url origin` errors, or `git fetch` fails, report
   the repo as no remote and skip the sync for it - still honour the dirty-tree
   guard and never fail the whole run.

Keep every stage allow-listed (see "Shell execution policy: how permissions match
a command" in `AGENTS.md`): enumerate the folder once, then issue separate
per-repo commands rather than writing a loop - a line starting with `for` / `while`
/ `if` asks in full, because there is no first command to match.

End with a per-repo table: repo name, resulting branch, whether it moved, how many
commits ahead/behind of the remote, and status (OK / dirty-skipped / skipped (no flow base) / no remote / diverged).

Optional scope directory override (defaults to the current chat project): $ARGUMENTS
