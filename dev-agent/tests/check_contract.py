#!/usr/bin/env python3
"""Checks that the prompts and the permission layer say the same thing.

AGENTS.md keeps only rules the permission layer cannot express. Everything it used to repeat
(secrets, .env, docker, services, external paths) is enforced by the permission files, and the
orchestrator's read prohibition is backed by denies for every code-reading tool.

Run from the repo root: python3 dev-agent/tests/check_contract.py
Exit code 1 if any check fails.
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DEV = os.path.dirname(HERE)
results = []


def check(ok, label):
    results.append(bool(ok))
    if not ok:
        print("FAIL", label)


def text(rel):
    return open(os.path.join(DEV, rel), encoding="utf-8").read()


def strip_jsonc_lines(raw):
    return json.loads(re.sub(r"(?m)^\s*//.*$", "", raw))


# AGENTS.md: only the sections the permission layer cannot express
headings = re.findall(r"(?m)^## (.+)$", text("data/shared/AGENTS.md"))
check(headings == ["Git", "Work tracking", "Operations"], f"AGENTS.md sections are Git, Work tracking, Operations (found {headings})")

# Orchestrator prompt: the read prohibition comes first, with the tools that are really denied
first_line = next(line for line in text("data/shared/agents/orchestrator.md").splitlines() if line.strip())
check("CANNOT READ" in first_line, "orchestrator prompt opens with the read prohibition")
check("read, glob, grep" in text("data/config/agents/orchestrator.md"), "opencode orchestrator names read, glob and grep")
app = text("data/pi/APPEND_SYSTEM.md")
check("pilens_*" in app and "source_check" in app, "pi orchestrator names its code-analysis tools")

# opencode: .env edits denied; git merge asks, --ff-only stays allowed after it (last match wins)
oc = text("data/config/opencode.jsonc")
check('{ "action": "edit", "resource": "*.env", "effect": "deny" }' in oc, "opencode: .env edits denied")
ask = oc.find('{ "action": "shell", "resource": "git merge *", "effect": "ask" }')
ff = oc.find('{ "action": "shell", "resource": "git merge --ff-only*", "effect": "allow" }')
check(ask != -1 and ff > ask, "opencode: git merge asks, --ff-only is allowed after it")

# pi global policy: same rules
pol = strip_jsonc_lines(text("data/pi/policy/pi-permissions.jsonc"))
check(pol["tools"].get("edit:**/*.env") == "deny" and pol["tools"].get("write:**/*.env") == "deny",
      "pi global: .env edits and writes denied")
keys = list(pol["bash"].keys())
check(pol["bash"].get("git merge *") == "ask" and pol["bash"].get("git merge --ff-only*") == "allow"
      and keys.index("git merge --ff-only*") > keys.index("git merge *"),
      "pi global: git merge asks, --ff-only allowed after it")

# pi orchestrator: every code-reading tool is denied, not only read/grep/find/ls
orch = text("data/pi/policy/agents/orchestrator.md")
for tool in ("pilens_*", "lens_*", "source_check", "read", "grep", "find", "ls", "ffgrep", "fffind", "multi_grep"):
    check(f'"{tool}": deny' in orch, f"pi orchestrator denies {tool}")

# pi children that can edit: never .env, and the .env denies come after their allow
for agent in ("coder", "supper"):
    pol_agent = text(f"data/pi/policy/agents/{agent}.md")
    check(pol_agent.index('"edit:**/*.env": deny') > pol_agent.index('"edit": allow'),
          f"{agent}: .env edits denied after the edit allow")
    check(pol_agent.index('"write:**/*.env": deny') > pol_agent.index('"write": allow'),
          f"{agent}: .env writes denied after the write allow")

passed = sum(results)
print(f"{passed}/{len(results)} checks passed" if all(results)
      else f"{passed}/{len(results)} checks passed, {len(results) - passed} failed")
sys.exit(0 if all(results) else 1)
