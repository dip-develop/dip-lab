---
description: Switch the current project's repos to develop and fast-forward them
---

**Dirty tree is a hard stop.** Before switching any repo's branch, run `git status
--porcelain` there. If the output is non-empty, do NOT switch: leave the repo on its
current branch and report it as dirty/skipped. Never stash, never discard, never force
a checkout - no `git checkout -f`, no `git switch --force`.

Sync every git repo in the resolved scope to its `develop` branch.

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

When `$ARGUMENTS` points outside the current project's working directory, the
first access to it raises one `external_directory` approval prompt - that is
what the permission guards. Surface it to the operator instead of treating it
as an error - approving it "always" covers the rest of the session, so the
sweep does not re-prompt. With the default in-project scope no such prompt
appears at all, so a normal run needs no external approval.

1. Enumerate the scope: check the scope directory itself (the project root, or
   `$ARGUMENTS` when given) and each of its subdirectories for a `.git` entry.
   Discover the repos this way - the set changes over time, so do not work from
   a hardcoded list. Do not list anything above the scope directory.
2. Run `git branch -a` in each repo. A repo is in scope only if `develop` exists,
   locally or as `origin/develop`.
3. No `develop` branch means out of scope: skip the repo and report it as skipped.
   Do NOT fall back to `main`, do NOT create `develop`, do not switch or pull
   such a repo at all - leave it entirely alone.
4. In-scope repo: `git fetch`, confirm the working tree is clean (see the guard
   above), then `git checkout develop`. If `develop` exists only as `origin/develop`,
   a plain `git checkout develop` creates the local branch tracking the remote.
5. Fast-forward with `git merge --ff-only origin/develop`. If `--ff-only` fails the
   history has diverged: report it and do NOT force, rebase, or reset.
6. Measure drift with `git rev-list --left-right --count develop...origin/develop`.
   The left number is commits only in local `develop` (ahead / unpushed), the right
   is commits only in `origin/develop` (behind). After a successful `--ff-only` both
   are normally `0 0`; the left number is the signal that there is unpushed work.
7. No remote: if `git remote get-url origin` errors, or `git fetch` fails, report
   the repo as no remote and skip the sync for it - still honour the dirty-tree
   guard and never fail the whole run.

Keep commands flat and single-purpose: no `&&` / `;` / `||` chains, no `for` /
`while` / `if` constructs - the permission checker falls back to `ask` on compound
commands (see "Shell execution policy: keep commands flat" in `AGENTS.md`). Here
that means enumerate the folder once, then issue separate per-repo commands rather
than writing a loop.

End with a per-repo table: repo name, resulting branch, whether it moved, how many
commits ahead/behind of the remote, and status (OK / dirty-skipped / skipped /
no remote / diverged).

Optional scope directory override (defaults to the current chat project): $ARGUMENTS
