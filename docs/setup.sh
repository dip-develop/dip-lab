#!/bin/bash
set -e
BASE="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$BASE/data/docs/export" "$BASE/data/docs/consume" "$BASE/data/docs/media"
