# Shell execution policy: keep commands flat

The permission checker matches shell commands fragment by fragment
against the allow/ask/deny rules in `opencode.jsonc` and each agent's
own `permissions:` block. This has one consequence every agent needs
to know, not just the one that happens to spell it out in its own
prompt:

- **Compound commands always fall back to `ask`, in full**, even when
  every individual piece is already allow-listed. Every sub-command in
  a `&&` / `;` / `||` chain must be individually allow-listed AND the
  checker must recognize the line as decomposable — in practice, a
  line starting with a shell keyword (`for`, `while`, `if`) can never
  match anything and always asks.
- Practical effect: `cd myproject && git status` asks for approval
  even though `cd *` and `git status*` are both allowed on their own.
  Prefer separate calls (`cd myproject`, then `git status`) over
  chaining when you want to stay inside the allow-listed path.
- Poll for a slow result (CI, a long build) with repeated simple calls
  — `sleep 45`, then `gh pr view ...` — never a shell loop. A loop
  both falls back to `ask` and won't do what you expect even once
  approved, since each iteration is a fresh, unrelated permission
  check.
- Never put bare `|`, `||`, or `&&` characters inside a quoted regex
  in a shell line the splitter sees (e.g. `grep 'a|b'`). Use separate
  `-e` patterns, or the dedicated grep tool, instead — the splitter
  can't tell a literal pipe inside quotes from a real one.

Keeping commands flat and single-purpose isn't just a style
preference: it's the difference between routine work running
autonomously within the allow-list and every other step stalling on
an avoidable approval round-trip.
