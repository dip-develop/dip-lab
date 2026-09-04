#!/bin/bash
set -e
BASE="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$BASE/data/config/agents"
mkdir -p "$BASE/data/config/instructions"
