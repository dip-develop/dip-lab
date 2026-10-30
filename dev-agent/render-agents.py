#!/usr/bin/env python3
"""Render per-tool agent files from one shared prompt body.

Sources (edit these, never the generated files):
  data/shared/agents/<n>.md             shared prompt body, no frontmatter
  agents/<tool>/<n>.frontmatter.yaml    tool-specific frontmatter, YAML between the --- lines

Outputs (generated, committed):
  data/config/agents/<n>.md             opencode: frontmatter + body, one file per agent
  data/pi/agents/<n>.md                 pi-subagents: child frontmatter + body
  data/pi/policy/agents/<n>.md          pi-permission-system: name + permission block + body
  data/pi/APPEND_SYSTEM.md              pi main session: the orchestrator body, tagged as the active agent

pi-subagents rejects a `permission:` block in an agent file, so the pi frontmatter is split at
the top-level `permission:` line. Everything above it goes to the agent file; the permission
block goes to the policy directory that PI_PERMISSION_SYSTEM_POLICY_AGENT_DIR points at.
The orchestrator is never a child: it has no agent file, only the policy file and APPEND_SYSTEM.md.

Placeholders in bodies ({{NAME}}) are replaced per tool. Run from anywhere:
  python3 dev-agent/render-agents.py
"""
import glob
import os
import re

ROOT = os.path.dirname(os.path.abspath(__file__))
MAIN_SESSION_AGENTS = {"orchestrator"}
PERMISSION_LINE = re.compile(r"^permission:", re.M)

TARGETS = {
    "opencode": {
        "vars": {
            "DELEGATE_TOOL": "subagent",
            "FILE_SEARCH": "glob",
            "READ_TOOLS": "read, glob, grep",
            "ID_NOTE": "This OpenCode version does not list\nthe IDs in the tool, so never guess.",
        },
    },
    "pi": {
        "vars": {
            "DELEGATE_TOOL": "subagent",
            "FILE_SEARCH": "find",
            "READ_TOOLS": "read, grep, find, ls, ffgrep, fffind, multi_grep, pilens_*, lens_*, source_check",
            "ID_NOTE": "The subagent tool's catalog lists the names\nwith their descriptions, so never guess.",
        },
    },
}


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def write(relpath, text):
    path = os.path.join(ROOT, relpath)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
    print(f"wrote {relpath}")


def fill(body, variables, name):
    for key, value in variables.items():
        body = body.replace("{{" + key + "}}", value)
    if "{{" in body:
        raise SystemExit(f"unresolved placeholder in {name}")
    return body


def render_opencode(name, frontmatter, body):
    write(f"data/config/agents/{name}.md", "---\n" + frontmatter + "---\n" + body)


def render_pi(name, frontmatter, body):
    match = PERMISSION_LINE.search(frontmatter)
    head = frontmatter[: match.start()] if match else frontmatter
    permission = frontmatter[match.start():] if match else ""

    if name in MAIN_SESSION_AGENTS:
        write(
            "data/pi/APPEND_SYSTEM.md",
            f'<active_agent name="{name}">\n' + body.strip() + "\n</active_agent>\n",
        )
    else:
        write(f"data/pi/agents/{name}.md", "---\n" + head + "---\n" + body)

    if permission:
        name_lines = [line for line in head.splitlines(keepends=True) if line.startswith("name:")]
        if not name_lines:
            raise SystemExit(f"{name}: pi frontmatter needs a name: line")
        write(
            f"data/pi/policy/agents/{name}.md",
            "---\n" + name_lines[0] + permission + "---\n" + body,
        )


def main():
    for tool, cfg in TARGETS.items():
        for fm_path in sorted(glob.glob(os.path.join(ROOT, f"agents/{tool}/*.frontmatter.yaml"))):
            name = os.path.basename(fm_path)[: -len(".frontmatter.yaml")]
            frontmatter = read(fm_path)
            body = fill(read(os.path.join(ROOT, "data/shared/agents", name + ".md")), cfg["vars"], name)
            if tool == "opencode":
                render_opencode(name, frontmatter, body)
            else:
                render_pi(name, frontmatter, body)


if __name__ == "__main__":
    main()
