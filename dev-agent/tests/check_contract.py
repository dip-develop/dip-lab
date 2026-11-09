#!/usr/bin/env python3
"""Checks that the prompts and the permission layer say the same thing.

AGENTS.md keeps only rules the permission layer cannot express. Everything it used to repeat
(secrets, .env, docker, services, external paths) is enforced by the permission files, and the
orchestrator's read prohibition is backed by denies for every code-reading tool.

The GitHub MCP server is also pinned here: denied for every agent by default, re-enabled only for
the write-capable coder and supper, with its write/merge tools denied again after that allow, and
configured with an environment placeholder rather than a literal token.

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

# GitHub MCP: denied by default, re-enabled only for the write-capable roles,
# with the destructive tools denied again after the allow (last match wins).
check('{ "action": "github_*", "resource": "*", "effect": "deny" }' in oc,
      "opencode: github_* denied by default")

GITHUB_DESTRUCTIVE = (
    "merge_pull_request",
    "push_files",
    "create_or_update_file",
    "delete_file",
    "create_repository",
    "fork_repository",
)


def opencode_github_rule(fm, tool, effect, start=0):
    return re.compile(
        r'- action:\s*"github_' + tool + r'"\s*\n\s*resource:\s*"\*"\s*\n\s*effect:\s*' + effect
    ).search(fm, start)


github_allow = re.compile(
    r'- action:\s*"github_\*"\s*\n\s*resource:\s*"\*"\s*\n\s*effect:\s*allow'
)
for agent in ("coder", "supper"):
    fm = text(f"agents/opencode/{agent}.frontmatter.yaml")
    allow = github_allow.search(fm)
    sp = fm.find('action: "serverpod_*"')
    check(allow is not None, f"opencode {agent}: github_* re-enabled")
    check(allow is not None and sp != -1 and allow.start() > sp,
          f"opencode {agent}: github_* allow follows the serverpod_* allow")
    for tool in GITHUB_DESTRUCTIVE:
        denied = opencode_github_rule(fm, tool, "deny", allow.end()) if allow else None
        check(denied is not None,
              f"opencode {agent}: github_{tool} denied after the allow")
for agent in ("architect", "planner", "orchestrator", "reviewer", "tester", "writer", "marketing"):
    check("github_*" not in text(f"agents/opencode/{agent}.frontmatter.yaml"),
          f"opencode {agent}: no github_* tools")

# pi policy render: the star allow must precede each destructive deny
for agent in ("coder", "supper"):
    pol_agent = text(f"data/pi/policy/agents/{agent}.md")
    allow = pol_agent.find('"mcp__github__*": allow')
    check(allow != -1, f"pi {agent}: github_* re-enabled")
    for tool in GITHUB_DESTRUCTIVE:
        denied = pol_agent.find(f'"mcp__github__{tool}": deny')
        check(allow != -1 and denied > allow,
              f"pi {agent}: github_{tool} denied after the allow")
for agent in ("architect", "planner", "explore", "orchestrator", "reviewer", "tester", "writer", "marketing"):
    check("mcp:github" not in text(f"agents/pi/{agent}.frontmatter.yaml"),
          f"pi {agent}: github MCP not enabled")
    check("mcp__github__" not in text(f"data/pi/policy/agents/{agent}.md"),
          f"pi {agent}: no github tools")

# GitHub MCP config: the token comes from the environment in both CLIs
raw_oc = text("data/shared/mcp/opencode.jsonc")
raw_pi = text("data/shared/mcp/pi.json")
gh_oc = strip_jsonc_lines(raw_oc)["mcp"]["servers"]["github"]
gh_pi = json.loads(raw_pi)["mcpServers"]["github"]
for name, gh, auth in (
    ("opencode", gh_oc, "Bearer {env:GH_TOKEN}"),
    ("pi", gh_pi, "Bearer ${GH_TOKEN}"),
):
    check(gh["url"] == "https://api.githubcopilot.com/mcp/",
          f"{name} MCP: github server url is pinned")
    check(gh["headers"]["Authorization"] == auth,
          f"{name} MCP: github server reads GH_TOKEN from the environment")
    check(gh["headers"]["X-MCP-Toolsets"] == "context,repos,issues,pull_requests",
          f"{name} MCP: github toolsets pinned")
for name, raw in (("opencode", raw_oc), ("pi", raw_pi)):
    prefixes = ("ghp_", "github_pat_", "gho_", "ghu_", "ghs_")
    check(not any(prefix in raw for prefix in prefixes), f"{name} MCP: no literal GitHub token")

passed = sum(results)
print(f"{passed}/{len(results)} checks passed" if all(results)
      else f"{passed}/{len(results)} checks passed, {len(results) - passed} failed")
sys.exit(0 if all(results) else 1)
