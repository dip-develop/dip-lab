#!/bin/bash
# Substitute placeholder tokens in mysql-init.sql with real values from
# the environment (which mysql inherits via env_file: .env in compose).
# MySQL's /docker-entrypoint-initdb.d/ runs .sql files directly and does
# NOT do env substitution, so this wrapper does it before execing the
# real entrypoint. Runs once on first start when the data dir is empty.
set -e

INIT_DIR="/docker-entrypoint-initdb.d"
TEMPLATE="$INIT_DIR/mysql-init.sql"
RENDERED="/tmp/mysql-init.rendered.sql"

# Required env: MYSQL_CLOUD_PASSWORD, MYSQL_ROOT_PASSWORD.
# Test creds are optional - if TEST_MYSQL_USER is empty the test-related
# lines in mysql-init.sql become no-ops after substitution.
: "${MYSQL_CLOUD_PASSWORD:?MYSQL_CLOUD_PASSWORD must be set in databases/.env}"
: "${MYSQL_ROOT_PASSWORD:?MYSQL_ROOT_PASSWORD must be set in databases/.env}"

# Use sed (not envsubst) because MySQL has `__TEST_MYSQL_USER__` tokens
# with underscores that envsubst handles fine, but the surrounding
# `__MYSQL_CLOUD_PASSWORD__` (with literal underscores) is more
# readable than ${VAR} style. Keep the explicit list here.
render() {
    local out="$1"
    sed \
        -e "s|__MYSQL_CLOUD_PASSWORD__|${MYSQL_CLOUD_PASSWORD}|g" \
        -e "s|__MYSQL_ROOT_PASSWORD__|${MYSQL_ROOT_PASSWORD}|g" \
        -e "s|__TEST_MYSQL_USER__|${TEST_MYSQL_USER:-}|g" \
        -e "s|__TEST_MYSQL_PASSWORD__|${TEST_MYSQL_PASSWORD:-}|g" \
        -e "s|__TEST_MYSQL_DB__|${TEST_MYSQL_DB:-}|g" \
        "$TEMPLATE" > "$out"
}

if [ -f "$TEMPLATE" ]; then
    render "$RENDERED"
    chmod 600 "$RENDERED"
    mv "$RENDERED" "$TEMPLATE"
fi

exec /usr/local/bin/docker-entrypoint.sh "$@"
