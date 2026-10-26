#!/usr/bin/env python3
"""Render per-tool agent files from one shared prompt body.

Sources (edit these, never the generated files):
  data/shared/agents/<name>.md             shared prompt body, no frontmatter
  agents/<tool>/<name>.frontmatter.yaml    tool-specific frontmatter, YAML between the --- lines

Outputs (generated, committed):
  data/config/agents/<name>.md             opencode
  data/pi/agents/<name>.md                 pi (pi-agent-router + pi-permission-system)

Placeholders in bodies ({{NAME}}) are replaced per tool. Run from anywhere:
  python3 dev-agent/render-agents.py
"""
import glob
import os

ROOT = os.path.dirname(os.path.abspath(__file__))

TARGETS = {
    "opencode": {
        "out": "data/config/agents",
        "vars": {
            "DELEGATE_TOOL": "subagent",
            "FILE_SEARCH": "glob",
            "ID_NOTE": "This OpenCode version does not list\nthe IDs in the tool, so never guess.",
        },
    },
    "pi": {
        "out": "data/pi/agents",
        "vars": {
            "DELEGATE_TOOL": "task",
            "FILE_SEARCH": "find",
            "ID_NOTE": "The task tool does not list\nthe IDs, so never guess.",
        },
    },
}


def main():
    os.chdir(ROOT)
    for tool, cfg in TARGETS.items():
        os.makedirs(cfg["out"], exist_ok=True)
        for fm_path in sorted(glob.glob(f"agents/{tool}/*.frontmatter.yaml")):
            name = os.path.basename(fm_path)[: -len(".frontmatter.yaml")]
            with open(fm_path, encoding="utf-8") as f:
                frontmatter = f.read()
            with open(f"data/shared/agents/{name}.md", encoding="utf-8") as f:
                body = f.read()
            for key, value in cfg["vars"].items():
                body = body.replace("{{" + key + "}}", value)
            if "{{" in body:
                raise SystemExit(f"unresolved placeholder in {name} for {tool}")
            out = "---\n" + frontmatter + "---\n" + body
            with open(os.path.join(cfg["out"], name + ".md"), "w", encoding="utf-8") as f:
                f.write(out)
            print(f"{tool}: {name}")


if __name__ == "__main__":
    main()
