#!/bin/bash
set -e

if [ -n "${TRAEFIK_DASHBOARD_PASS}" ]; then
    htpasswd -bcBC 12 /srv/proxy/dynamic/.htpasswd "${TRAEFIK_DASHBOARD_USER:-admin}" "${TRAEFIK_DASHBOARD_PASS}"
    chmod 600 /srv/proxy/dynamic/.htpasswd
fi

exec /docker-entrypoint.sh "$@"