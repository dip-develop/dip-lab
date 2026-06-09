#!/bin/bash
set -e
BASE="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$BASE/data/postgres" "$BASE/data/mysql" "$BASE/data/redis"
