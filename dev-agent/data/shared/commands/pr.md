---
description: Push the current branch and open a PR (Git Flow)
agent: coder
subagent: true
---
If you are the orchestrator, hand the whole job below to one `coder` subagent call instead of running it yourself.

Open a pull request for the current work:

1. Inspect `git status`, `git diff`, `git log --oneline -10` first; stage
   only intended files. Never commit secrets or `.env` files.
2. Commit style: match the repo's existing messages (scope: lowercase
   summary). Split into small logical commits if needed.
3. `git push -u origin <branch>`.
4. Pick the base branch with the `git-flow` skill, section 1: run `git ls-remote --heads origin develop`. A line of output means the repo has `develop`: `feature/*`, `bugfix/*` and `chore/*` target `develop`; `hotfix/*` and `release/*` target `main`, and then need a second PR into `develop` (flow table, section 2). No output means the repo is main-only: use `--base main` for every branch type. Never create `develop` to satisfy the table.
5. `gh pr create --base <base from step 4>` with a title matching the main
   change and a body that summarizes what/why and lists a test plan.

Stop after creating the PR and report its URL. Do not merge.

Optional extra PR description notes: $ARGUMENTS
