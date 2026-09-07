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

## Never

- Never keep progress lists only in chat ("I'll remember it").
- Never duplicate the same task in both an issue and `TODO.md`
  without a pointer to the other.
