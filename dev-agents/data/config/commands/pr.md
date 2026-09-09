---
description: Push the current branch and open a PR (Git Flow)
---
Open a pull request for the current work:

1. Inspect `git status`, `git diff`, `git log --oneline -10` first; stage
   only intended files. Never commit secrets or `.env` files.
2. Commit style: match the repo's existing messages (scope: lowercase
   summary). Split into small logical commits if needed.
3. `git push -u origin <branch>`.
4. Base branch (`--base`): `develop` for `feature/*` and `bugfix/*`;
   `main` for `hotfix/*` and `release/*` - see the Git Flow table in
   `instructions/git-flow.md`. Note that `gh pr create` alone defaults
   to the repo's default branch, which is usually wrong for Git Flow.
   Hotfix and release branches need two PRs: into `main` AND `develop`.
5. `gh pr create` with a title matching the main change and a body that
   summarizes what/why and lists a test plan.

Stop after creating the PR and report its URL. Do not merge.

Optional extra PR description notes: $ARGUMENTS
