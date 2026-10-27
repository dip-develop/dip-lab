#!/usr/bin/env python3
"""Checks the orchestrator's opencode permissions against the rules in the repo.

It applies OpenCode V2 rule semantics as documented: global rules first, then
the agent's rules; the last matching rule wins; a pattern ending in " *" also
matches the bare command; no matching rule means "ask".

This simulates the rules, it does not run opencode. Run from the repo root:
  python3 dev-agent/tests/check_orchestrator_shell.py
Exit code 1 if any expectation fails.
"""
import fnmatch
import json
import os
import re
import sys

import yaml

HERE = os.path.dirname(os.path.abspath(__file__))
DEV_AGENT = os.path.dirname(HERE)


def load_global_rules():
    raw = open(os.path.join(DEV_AGENT, "data/config/opencode.jsonc"), encoding="utf-8").read()
    raw = re.sub(r"(?m)^\s*//.*$", "", raw)
    return json.loads(raw)["permissions"]


def load_agent_rules():
    path = os.path.join(DEV_AGENT, "agents/opencode/orchestrator.frontmatter.yaml")
    return yaml.safe_load(open(path, encoding="utf-8"))["permissions"]


def matches(pattern, value):
    if fnmatch.fnmatchcase(value, pattern):
        return True
    return pattern.endswith(" *") and value == pattern[:-2]


def decide(action, resource, rules):
    effect = "ask"
    for rule in rules:
        if rule["action"] == action and matches(rule["resource"], resource):
            effect = rule["effect"]
    return effect


EXPECT = {
    # reading file contents must not be allowed
    ("shell", "cat main.dart"): "deny",
    ("shell", "head -n 5 main.dart"): "deny",
    ("shell", "tail main.dart"): "deny",
    ("shell", "sed -n 1,5p main.dart"): "deny",
    ("shell", "awk 1 main.dart"): "deny",
    ("shell", "grep foo main.dart"): "deny",
    ("shell", "rg foo main.dart"): "deny",
    ("shell", "find . -name *.dart"): "deny",
    ("shell", "sort main.dart"): "deny",
    ("shell", "uniq main.dart"): "deny",
    ("shell", "cut -c1-5 main.dart"): "deny",
    ("shell", "tr a b < main.dart"): "deny",
    ("shell", "jq . pubspec.json"): "deny",
    ("shell", "od -c main.dart"): "deny",
    ("shell", "diff /dev/null main.dart"): "deny",
    ("shell", "nl main.dart"): "deny",
    ("shell", "tac main.dart"): "deny",
    ("shell", "xxd main.dart"): "deny",
    ("shell", "strings main.dart"): "deny",
    ("shell", "less main.dart"): "deny",
    ("shell", "git show HEAD:main.dart"): "deny",
    ("shell", "git log -p"): "deny",
    # interpreters can read any file
    ("shell", "python3 -c print(1)"): "deny",
    ("shell", "python3 main.py"): "deny",
    ("shell", "python main.py"): "deny",
    ("shell", "perl -e 1"): "deny",
    ("shell", "node -e 1"): "deny",
    ("shell", "ruby -e 1"): "deny",
    ("shell", "bash -c cat"): "deny",
    ("shell", "sh -c cat"): "deny",
    # smuggling a read past an allowed command
    ("shell", "echo $(cat main.dart)"): "deny",
    ("shell", "echo `cat main.dart`"): "deny",
    # direct file reads
    ("read", "main.dart"): "deny",
    ("read", ".env"): "deny",
    # metadata commands stay allowed
    ("shell", "ls"): "allow",
    ("shell", "ls lib"): "allow",
    ("shell", "pwd"): "allow",
    ("shell", "date"): "allow",
    ("shell", "git status"): "allow",
    ("shell", "git status --short"): "allow",
    ("shell", "git branch --show-current"): "allow",
    ("shell", "gh pr view 12"): "allow",
    ("shell", "gh pr list"): "allow",
    ("shell", "gh pr checks 12"): "allow",
    ("shell", "gh issue list"): "allow",
    # delegation: explore and the work agents, nothing else
    ("subagent", "explore"): "allow",
    ("subagent", "planner"): "allow",
    ("subagent", "coder"): "allow",
    ("subagent", "tester"): "allow",
    ("subagent", "reviewer"): "allow",
    ("subagent", "architect"): "allow",
    ("subagent", "build"): "deny",
}


def main():
    rules = load_global_rules() + load_agent_rules()
    failures = 0
    for (action, resource), want in EXPECT.items():
        got = decide(action, resource, rules)
        if got != want:
            failures += 1
            print(f"FAIL {action} {resource!r}: expected {want}, got {got}")
    print(f"{len(EXPECT) - failures}/{len(EXPECT)} checks passed")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
