#!/usr/bin/env python3
"""Checks the pi layout that pi-subagents and pi-permission-system depend on.

pi-subagents rejects a `permission:` block in an agent file, so permission rules live in the
policy directory (PI_PERMISSION_SYSTEM_POLICY_AGENT_DIR). Children get a strict `tools:` allowlist
and never the `subagent` tool, so nesting stays off. The orchestrator is the main session: it has
no agent file, only a policy file and the APPEND_SYSTEM.md prompt tagged as the active agent.

Run from the repo root: python3 dev-agent/tests/check_pi_agents.py
Exit code 1 if any check fails.
"""
import json
import os
import re
import sys

import yaml

HERE = os.path.dirname(os.path.abspath(__file__))
DEV = os.path.dirname(HERE)
PI_EXT = "/home/develop/.pi/agent/extensions"
results = []


def check(ok, label):
    results.append(ok)
    if not ok:
        print("FAIL", label)


def text(rel):
    return open(os.path.join(DEV, rel), encoding="utf-8").read()


def frontmatter(rel):
    body = text(rel)
    assert body.startswith("---\n"), rel
    end = body.index("\n---\n", 4)
    return yaml.safe_load(body[4:end + 1])


def strip_jsonc(raw):
    return json.loads(re.sub(r"(?m)^\s*//.*$", "", raw))


src_dir = os.path.join(DEV, "agents/pi")
children = []
for name in sorted(os.listdir(src_dir)):
    agent = name[: -len(".frontmatter.yaml")]
    src = yaml.safe_load(text(f"agents/pi/{name}"))
    check(src.get("name") == agent, f"{agent}: name matches file name")

    if agent == "orchestrator":
        perm = src.get("permission", {}).get("tools", {})
        check(perm.get("subagent") == "allow", "orchestrator: subagent allowed")
        check(perm.get("read") == "deny", "orchestrator: read denied")
        check("tools" not in src, "orchestrator: no child tools allowlist (main session)")
        check(os.path.exists(os.path.join(DEV, "data/pi/policy/agents/orchestrator.md")),
              "orchestrator: policy file generated")
        check(not os.path.exists(os.path.join(DEV, "data/pi/agents/orchestrator.md")),
              "orchestrator: not offered as a child agent")
        append = text("data/pi/APPEND_SYSTEM.md")
        check('<active_agent name="orchestrator">' in append and "</active_agent>" in append,
              "APPEND_SYSTEM.md tags the orchestrator as the active agent")
        continue

    children.append(agent)
    tools = [t.strip() for t in str(src.get("tools", "")).split(",") if t.strip()]
    check(bool(tools), f"{agent}: declares a tools allowlist")
    check("subagent" not in tools and "task" not in tools, f"{agent}: cannot nest delegation")
    check("extensions" in src, f"{agent}: declares its extensions (empty means none)")
    check(src.get("defaultContext") == "fresh", f"{agent}: fresh context by default")
    exts = [e.strip() for e in str(src.get("extensions") or "").split(",") if e.strip()]
    if any(t == "bash" for t in tools):
        check(f"{PI_EXT}/pi-permission-system/index.ts" in exts,
              f"{agent}: bash requires the permission system in the child")
    gen = frontmatter(f"data/pi/agents/{agent}.md")
    check(gen.get("name") == agent and gen.get("tools") == src.get("tools"),
          f"{agent}: generated agent file keeps the allowlist")
    check(not re.search(r"(?m)^permission:", text(f"data/pi/agents/{agent}.md").split("\n---\n")[0]),
          f"{agent}: generated agent file has no permission block (pi-subagents rejects it)")
    if "permission" in src:
        check(os.path.exists(os.path.join(DEV, f"data/pi/policy/agents/{agent}.md")),
              f"{agent}: policy file generated")

shared_cfg = strip_jsonc(text("data/pi/policy/pi-permissions.jsonc"))
check(shared_cfg["tools"].get("subagent") == "deny", "global policy: subagent denied by default")
check("task" not in shared_cfg["tools"], "global policy: no leftover task rule")
check(json.loads(text("data/pi/subagent-config.json")).get("toolActivation") == "eager",
      "subagent config: toolActivation eager (no loader step)")
check(json.loads(text("data/pi/settings.json")).get("subagents", {}).get("disableBuiltins") is True,
      "settings: builtin subagents disabled")
compose = text("docker-compose.yml")
check("PI_PERMISSION_SYSTEM_POLICY_AGENT_DIR=/home/develop/.pi/policy" in compose,
      "compose: policy directory variable set")
check("./data/pi/policy:/home/develop/.pi/policy" in compose, "compose: policy directory mounted")
check("router" not in compose.lower(), "compose: no pi-agent-router left")
installer = text("pi-extensions.sh")
check("install_one pi-subagents 0.84.0 subagent" in installer, "installer: pi-subagents pinned")
check("pi-agent-router" not in installer, "installer: pi-agent-router removed")


# Regression checks: .env reads stay denied whatever the layer order, and MCP tools are allowed by name.
for agent in children:
    pol = text(f"data/pi/policy/agents/{agent}.md")
    if '"read": allow' in pol:
        check(pol.index('"read:**/*.env": deny') > pol.index('"read": allow'),
              f"{agent}: .env read deny follows its read allow")
    if '"grep": allow' in pol:
        check(pol.index('"grep:**/*.env": deny') > pol.index('"grep": allow'),
              f"{agent}: .env grep deny follows its grep allow")
    src_text = text(f"agents/pi/{agent}.frontmatter.yaml")
    for server in re.findall(r"mcp:([A-Za-z0-9_-]+)", src_text):
        check(f'"mcp__{server}__*": allow' in pol, f"{agent}: policy allows mcp__{server}__* tools")
check(shared_cfg["tools"].get("grep:**/*.env") == "deny", "global policy: .env grep denied")
check("install_shared_peer" not in installer, "installer: no leftover shared-peer helper")

print(f"{sum(results)}/{len(results)} checks passed" if all(results) else
      f"{sum(results)}/{len(results)} checks passed, {len(results) - sum(results)} failed")
sys.exit(0 if all(results) else 1)
