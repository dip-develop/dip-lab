# Roadmap & TODO policy: track state outside the chat

Chat history is not durable. Any state worth keeping outlives the
session:

## Roadmap (long-lived) → GitHub issues

- Larger planned work, known bugs, and improvement ideas go to GitHub
  issues via `gh issue create --repo <owner/repo>`.
- One issue per topic, descriptive title, body with context and
  acceptance criteria. Label with a milestone if the repo uses them.
- Do not reopen a near-duplicate: check `gh issue list` first.
- Orchestrator may file issues; the operator still decides order and
  assignment.

## Working TODO (current) → `TODO.md` in the project root

- `TODO.md` is the short-lived working list for active work.
- Format: one item per line, `- [ ]` unchecked / `- [x]` done, newest
  items at the top. Keep at most ~20 items — archive or move finished
  topics to issues.
- The planner reads `TODO.md` before planning; the orchestrator
  updates it (check off, add follow-ups) as steps complete.
- `TODO.md` changes ride in the feature branch — they land via the
  normal PR, never directly on `develop`.

## Planned work → issue at planning time

- When the planner returns a multi-step plan, the orchestrator
  proposes creating a GitHub issue for it before dispatching coders
  (default: one issue for the plan, steps as `- [ ]` checkboxes in
  the body; per-step issues when they are independently actionable).
  The operator decides whether to file; one-shot drive-by fixes need
  no issue.
- Every PR body for that work references the issue: `Refs #<n>` —
  or `Closes #<n>` ONLY when the PR's base is the repo's default
  branch: GitHub's auto-close keyword is inert for merges into
  non-default branches, so Git Flow (develop-based) repos must close
  explicitly.
- After the operator merges, the orchestrator closes the linked
  issue with a pointer:
  `gh issue close <n> --comment "Done in PR #<m> (<sha>)"`.

## Never

- Never keep progress lists only in chat ("I'll remember it").
- Never duplicate the same task in both an issue and `TODO.md`
  without a pointer to the other.
- Never close an issue whose implementing PR has not merged yet
  (`Closes #N` in a develop-based PR does NOT auto-close).
