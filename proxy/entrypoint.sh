#!/bin/bash
set -e

if [ -n "${TRAEFIK_DASHBOARD_PASS}" ]; then
    htpasswd -bcBC 12 ./dynamic/.htpasswd "${TRAEFIK_DASHBOARD_USER:-admin}" "${TRAEFIK_DASHBOARD_PASS}"
    chmod 600 ./dynamic/.htpasswd
fi

exec /docker-entrypoint.sh "$@"