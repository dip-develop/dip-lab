# Developer Workstation: Agent Guide

Read by opencode and pi in every session. Role rules live in the agent prompts. Procedures live in skills: load the named skill before doing that work.

## Git

- Load the `git-flow` skill before any branch, commit, push, PR or back-merge. It tells you the base branch for each repo.
- The operator merges PRs, tags releases and deletes branches.

## Work tracking

- Work items are GitHub issues. There is no `TODO.md`: do not create, read or update one.
- Before filing an issue, run `gh issue list` and check for a near-duplicate.
- A multi-step plan gets one tracking issue before implementation. Its steps become the `- [ ]` checklist.
- Close an issue only after its implementing PR has merged: `gh issue close <n> --comment "Done in PR #<m>"`.
- PR body: `Refs #<n>`. Use `Closes #<n>` only when the PR targets the repo's default branch.

## Operations

- Never create a cron job or other recurring job. Propose it; the operator creates it.
