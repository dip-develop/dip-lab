#!/bin/bash
set -e
BASE="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$BASE/config/prompts" "$BASE/config/skills"
