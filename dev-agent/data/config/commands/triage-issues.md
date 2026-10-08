---
description: Check open GitHub issues and confirm closing the already-fixed ones
---
Triage this repo's open issues and close only the verifiably fixed ones:

1. Scope: derive `owner/repo` from the current git remote (`git remote
   get-url origin`) and pass it as `--repo` everywhere. `$ARGUMENTS`
   overrides it with a specific repo, or narrows to one issue number.
2. List what is open with `gh issue list --repo <owner/repo>`. If `gh` is
   missing or unauthenticated, report that and stop — do not fail hard.
   Work issue by issue with flat, single-purpose commands: a line starting with
   `for`/`while`/`if` asks in full (see "Shell execution policy: how permissions
   match a command" in `AGENTS.md`).
3. Establish whether each issue is actually fixed:
   - fixing commit: `git log --all --grep <n>`; repeated `--grep` patterns
     are OR'd by git, use separate ones, never a `|` inside a quoted pattern.
   - referencing PR: `gh pr list --repo <owner/repo> --state merged
     --search #<n> in:body` plus `gh issue view <n> --repo <owner/repo>`.
   - confirm that PR really merged into its base branch and that the fix is
     reachable from the branch that PR actually merged into — determine that from
     the PR, not from assumption: `gh pr view <n> --repo <owner/repo> --json
     baseRefName`. Then check it against the remote: run `git branch -a`
     (remote-only `origin/develop` / `origin/main` count; a fresh clone has no
     local branches), `git fetch` (refs may be stale), then `git merge-base
     --is-ancestor <sha> origin/<base>` where `<base>` is that PR's base branch —
     the repo's flow base (`develop` where it exists, `main` where it does not)
     for feature/bugfix/chore PRs, and `main` for a hotfix or release PR, which
     is why both bases can matter in one repo. A squash-merged PR head sha is not
     an ancestor (safe false negative); merge commits are the policy anyway.
4. The governing rule, and it MUST hold (see "Roadmap & TODO" in
   `AGENTS.md`): never close an issue whose implementing PR has not merged.
   GitHub's `Closes #N` is inert for merges into non-default branches, so a
   develop-based PR neither auto-closes its issue nor puts the fix on `main`.
   Count an issue as fixed only when the fix is verifiably reachable from
   that base branch; ambiguous status means NOT fixed.
5. Before touching anything, show an evidence table: issue number, title,
   fixing commit sha, merged PR number and the branch it merged into, and a
   one-line confidence verdict.
6. Then ask the operator to approve each close, one issue at a time. Only on
   an explicit approval for that specific issue, run
   `gh issue close <n> --repo <owner/repo> --comment "Done in PR #<m> (<sha>)"`.
   Never close silently, never bulk-close, never close on a guess. Report
   the unfixed and ambiguous issues as left open.

Optional repo or issue number: $ARGUMENTS
