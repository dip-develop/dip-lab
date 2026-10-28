#!/usr/bin/env python3
"""Checks that agent descriptions share one format and match across tools.

Format: "<Role>. <Permissions>. Use <when>." One line, at most 170 characters.
Agents that exist for both opencode and pi must have the same description.
Run from the repo root: python3 dev-agent/tests/check_agent_descriptions.py
"""
import glob
import json
import os
import re
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
PATTERN = re.compile(r"^[A-Z][^.]+\. .+\. Use .+\.$")


def description(path):
    text = open(path, encoding="utf-8").read()
    m = re.search(r"(?m)^description: (.*)$", text)
    return json.loads(m.group(1)) if m and m.group(1).startswith('"') else (m.group(1) if m else None)


def main():
    failures = 0
    sources = {}
    for tool in ("opencode", "pi"):
        for path in sorted(glob.glob(os.path.join(ROOT, "agents", tool, "*.frontmatter.yaml"))):
            name = os.path.basename(path).split(".")[0]
            desc = description(path)
            sources.setdefault(name, {})[tool] = desc
            if desc is None:
                failures += 1; print(f"FAIL {tool}/{name}: no description"); continue
            if len(desc) > 170:
                failures += 1; print(f"FAIL {tool}/{name}: {len(desc)} chars > 170")
            if not PATTERN.match(desc):
                failures += 1; print(f"FAIL {tool}/{name}: not '<Role>. <Permissions>. Use <when>.': {desc!r}")
    for name, by_tool in sources.items():
        if len(set(by_tool.values())) > 1:
            failures += 1; print(f"FAIL {name}: opencode and pi descriptions differ")
    total = sum(len(v) for v in sources.values())
    print(f"{total - failures}/{total} description checks passed")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
