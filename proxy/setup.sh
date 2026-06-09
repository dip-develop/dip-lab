#!/bin/bash
set -e
BASE="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$BASE/dynamic" "$BASE/logs"
touch "$BASE/dynamic/.gitkeep" "$BASE/logs/.gitkeep" 2>/dev/null || true
