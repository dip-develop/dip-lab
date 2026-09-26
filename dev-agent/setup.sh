#!/bin/bash
set -e
BASE="$(cd "$(dirname "$0")" && pwd)"
# No data/config/instructions/ on purpose: opencode V2 accepts the
# "instructions" config key but does not load its entries, so a policy
# file placed there is silently never seen by any agent. Global policy
# lives in data/config/AGENTS.md, which V2 does load.
mkdir -p "$BASE/data/config/agents"
