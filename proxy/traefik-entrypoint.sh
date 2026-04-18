#!/bin/bash
set -e

if [ -n "$TRAEFIK_DASHBOARD_PASS" ]; then
    HASH=$(openssl passwd -apr1 "$TRAEFIK_DASHBOARD_PASS")
    sed "s/\$TRAEFIK_USER/$TRAEFIK_DASHBOARD_USER/g; s/\$TRAEFIK_HASH/$HASH/g" /etc/traefik/dynamic/auth.yml.tmpl > /etc/traefik/dynamic/auth.yml
fi

exec traefik "$@"