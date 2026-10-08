---
description: Report develop-vs-main drift across repos and propose back-merges (read-only)
---
Check every git repo inside the current chat project for missed
back-merges (`main` must stay a subset of `develop`'s history — see the
Back-merge section of `AGENTS.md`). Propose only; never mutate.

Resolve the scope first. The default scope is the current chat project itself:
the project root the chat was opened in, derived at runtime; never assume a
literal path. Repos inside that scope are the project root (when it has a
`.git` entry) plus each subdirectory with a `.git` entry (nested subprojects).
Never climb above the project directory — sibling projects, other repos in the
home folder or anywhere else on disk are out of scope by default, even when
they sit next to the current project.

`$ARGUMENTS`, when given, overrides the default: it is the directory holding
the repos to check — use it and skip discovery. Verify it contains at least one
subdirectory with a `.git` entry (or is itself a git repo); if not, stop and
ask the operator for the correct directory rather than guessing or defaulting
to any fixed path. The same applies to an empty `$ARGUMENTS` when the project
root is not a git repo and has no git subdirectories: ask, never walk to a
parent directory looking for repos.

When `$ARGUMENTS` points outside the current project's working directory, the
first access to it raises one `external_directory` approval prompt — that is
what the permission guards. Surface it to the operator instead of treating it
as an error — approving it "always" covers the rest of the session, so the
sweep does not re-prompt. With the default in-project scope no such prompt
appears at all, so a normal run needs no external approval.

1. Enumerate the repos: list the scope directory (the project root, or
   `$ARGUMENTS` when given) and treat it plus each of its subdirectories with a
   `.git` entry as a repo. Skip anything without `.git` (including
   `*.worktrees` stores). Do not hardcode a repo list, and do not list anything
   above the scope directory.
2. Per repo, in scope only if it has BOTH branches — check with
   `git branch -a`: remote-only `origin/develop` / `origin/main` count too (a
   fresh clone has no local branches). Missing either (e.g. a
   single-branch repo): report as out of scope and touch nothing.
3. Measure drift per in-scope repo, two separate calls in order (keep commands
   flat — no `&&` chains, no `for`/`while`/`if` loops): `git fetch`, then
   `git rev-list --count origin/develop..origin/main` — remote refs, so a
   missing local branch cannot hide drift; keep `develop..origin/main` as a
   fallback when both local branches exist.
4. Interpret: `0` → healthy, report OK. Above `0` → `develop` is missing
   commits that landed on `main`; a back-merge is owed.
5. If `git fetch` fails or the repo has no remote (`git remote get-url origin`
   errors), report it and skip that repo — do not fail the whole run. Same if
   `gh` is not authenticated (`gh auth status`); skip PR checks in step 6 and
   report the repo as drift-only.
6. When drift is non-zero, check for an open back-merge PR first, before
   proposing: `gh pr list --repo <owner/repo> --base develop --state open`,
   then look in the head-branch column for a branch starting with `backmerge/`
   — a back-merge PR runs `backmerge/<version>` into `develop`, so it matches
   `base:`, never `head:`. Pass `--repo` explicitly — without it `gh` infers
   the repo from the current directory, which is wrong in a multi-repo sweep.
   Found → report the PR number and do nothing further for that repo.
7. When drift is non-zero and no back-merge PR exists, get the version from
   the most recent tag: `git describe --tags --abbrev=0`. No tag → ask the
   operator instead of inventing one. Then propose, and STOP for the operator
   to decide:
   - branch: `backmerge/<version>` cut from `origin/main`
   - base: `develop` (`--base develop`; never `--head main`)
   - title: `chore: back-merge main into develop (<version>)`
   This command does NOT create a branch, push, or open a PR — use `/pr` for
   that once the operator approves.
8. Remind the operator: merges into `main` (release/hotfix PRs) must use merge
   commits, never squash — squashing rewrites `main`'s history and turns every
   later back-merge into a conflict to resolve by hand.
9. Report a table: repo | drift | status (OK / out of scope / back-merge PR
   already open / back-merge proposed / skipped).

Optional scope directory override (defaults to the current chat project): $ARGUMENTS
