#!/bin/bash
# Substitute placeholder tokens in init.sql with real values from
# the environment (which postgres inherits via env_file: .env in
# compose). Postgres' /docker-entrypoint-initdb.d/ runs .sql files
# directly and does NOT do env substitution, so this wrapper does
# it before execing the real entrypoint. Runs once on first start
# when the data dir is empty.
set -e

INIT_DIR="/docker-entrypoint-initdb.d"
TEMPLATE="$INIT_DIR/init.sql"
RENDERED="/tmp/init.rendered.sql"

# Use sed here (not envsubst) because we need to handle quoted SQL
# tokens like '${TEST_POSTGRES_PASSWORD}' that envsubst may mis-parse
# in the middle of a SQL string. The set of expected vars is small
# and explicit.
render() {
    local out="$1"
    : > "$out"
    while IFS= read -r line; do
        # Substitute only the test-related tokens; everything else
        # stays literal so we don't accidentally rewrite the prod SQL.
        line=${line//\$\{TEST_POSTGRES_USER\}/${TEST_POSTGRES_USER:-}}
        line=${line//\$\{TEST_POSTGRES_PASSWORD\}/${TEST_POSTGRES_PASSWORD:-}}
        line=${line//\$\{TEST_POSTGRES_DB\}/${TEST_POSTGRES_DB:-}}
        printf '%s\n' "$line" >> "$out"
    done
}

if [ -f "$TEMPLATE" ]; then
    render "$RENDERED"
    chmod 600 "$RENDERED"
    mv "$RENDERED" "$TEMPLATE"
fi

exec /usr/local/bin/docker-entrypoint.sh "$@"
