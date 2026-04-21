#!/bin/bash

SERVICES=(
    "proxy"
    "vaultwarden"
    "portainer"
    "nextcloud"
    "paperless"
    "n8n"
    "immich"
    "llm"
    "openclaw"
)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ACTION=$1
shift

PERMISSIONS=(
    "proxy:1000:1000"
    "portainer:1000:1000"
    "vaultwarden:1000:1000"
    "paperless:1000:1000"
    "nextcloud:1000:1000"
    "n8n:1000:1000"
    "immich:1000:1000"
    "llm:1000:1000"
    "openclaw:1000:1000"
    "proxy/traefik.yml:600:1000"
    "proxy/acme.json:600:1000"
    "proxy/dynamic:755:1000"
)

setup_nets() {
    docker network create web 2>/dev/null || true
    docker network create internal 2>/dev/null || true
}

setup_env() {
    set -a
    source "$SCRIPT_DIR/.env"
    set +a

    for svc in "${SERVICES[@]}"; do
        local env_file="$SCRIPT_DIR/$svc/.env"
        if [ ! -f "$env_file" ] || [ ! -s "$env_file" ]; then
            case $svc in
                proxy)
                    cat > "$env_file" << EOF
DOMAIN=${DOMAIN}
TZ=${TZ}
TRAEFIK_DASHBOARD_USER=admin
TRAEFIK_DASHBOARD_PASS=${TRAEFIK_DASHBOARD_PASS:-}
EOF
                    ;;
                vaultwarden)
                    cat > "$env_file" << EOF
DOMAIN=${DOMAIN}
VAULTWARDEN_SIGNUPS_ALLOWED=${VAULTWARDEN_SIGNUPS_ALLOWED:-false}
VAULTWARDEN_ADMIN_TOKEN=${VAULTWARDEN_ADMIN_TOKEN:-}
EOF
                    ;;
                portainer)
                    cat > "$env_file" << EOF
PORTAINER_ADMIN_PASSWORD=${PORTAINER_ADMIN_PASSWORD:-}
EOF
                    ;;
                nextcloud)
                    cat > "$env_file" << EOF
NEXTCLOUD_DB_PASSWORD=${NEXTCLOUD_DB_PASSWORD:-}
NEXTCLOUD_REDIS_PASSWORD=${NEXTCLOUD_REDIS_PASSWORD:-}
TZ=${TZ}
EOF
                    ;;
                paperless)
                    cat > "$env_file" << EOF
PAPERLESS_DB_PASSWORD=${PAPERLESS_DB_PASSWORD:-}
PAPERLESS_SECRET_KEY=${PAPERLESS_SECRET_KEY:-}
TZ=${TZ}
EOF
                    ;;
                n8n)
                    cat > "$env_file" << EOF
DOMAIN=${DOMAIN}
N8N_DB_PASSWORD=${N8N_DB_PASSWORD:-}
N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY:-}
TZ=${TZ}
EOF
                    ;;
                immich)
                    cat > "$env_file" << EOF
IMMICH_DB_PASSWORD=${IMMICH_DB_PASSWORD:-}
TZ=${TZ}
EOF
                    ;;
                llm)
                    touch "$env_file"
                    ;;
                openclaw)
                    cat > "$env_file" << EOF
OPENCLAW_ALLOWED_ORIGINS=${OPENCLAW_ALLOWED_ORIGINS:-*}
EOF
                    ;;
            esac
            echo "Created $env_file"
        fi
    done

    # Generate Traefik basic auth from .env
    if [ -f "$SCRIPT_DIR/proxy/.env" ]; then
        set -a
        source "$SCRIPT_DIR/proxy/.env"
        set +a
        if [ -n "$TRAEFIK_DASHBOARD_PASS" ]; then
            local hash=$(openssl passwd -apr1 "$TRAEFIK_DASHBOARD_PASS")
            cat > "$SCRIPT_DIR/proxy/dynamic/auth.yml" << AUTHEOF
http:
  routers:
    dashboard:
      rule: "Host(\`traefik.dm-home.de\`)"
      service: api@internal
      entryPoints:
        - websecure
      middlewares:
        - auth_basic
        - security-headers
      tls:
        certresolver: letsencrypt

  middlewares:
    auth_basic:
      basicAuth:
        users:
          - "${TRAEFIK_DASHBOARD_USER}:${hash}"
AUTHEOF
            echo "Generated proxy/dynamic/auth.yml"
        fi
    fi
}

usage() {
    echo "Usage: $0 <command> [service]"
    echo ""
    echo "Commands:"
    echo "  start [svc]     - Start all or specific service"
    echo "  stop [svc]     - Stop all or specific service"
    echo "  restart [svc]  - Restart all or specific service"
    echo "  update [svc]  - Update (pull) all or specific service"
    echo "  logs [svc]    - Show logs for service"
    echo "  status        - Show status of all services"
    echo "  perm          - Set permissions and ownership"
    echo "  setup         - Setup networks and .env files"
    echo ""
    echo "Services:"
    echo "  ${SERVICES[*]}"
    echo "  all           - all services"
    echo ""
    echo "Examples:"
    echo "  $0 start                # start all"
    echo "  $0 start proxy         # start proxy only"
    echo "  $0 start nextcloud    # start nextcloud only"
    echo "  $0 restart all        # restart all"
    echo "  $0 logs immich         # follow logs"
}

run_all() {
    local cmd=$1
    for svc in "${SERVICES[@]}"; do
        docker compose -f "$svc/docker-compose.yml" $cmd
    done
}

run_one() {
    local svc=$1
    local cmd=$2
    if [ "$svc" = "docs" ]; then
        svc="paperless"
    fi
    if [ -d "$svc" ] && [ -f "$svc/docker-compose.yml" ]; then
        docker compose -f "$svc/docker-compose.yml" $cmd
    else
        echo "Service '$svc' not found"
        exit 1
    fi
}

case $ACTION in
    start)
        setup_nets
        setup_env
        if [ -z "$1" ]; then
            run_all "up -d"
        else
            run_one "$1" "up -d"
        fi
        ;;
    stop)
        reversed=("${SERVICES[@]}")
        for svc in $(printf '%s\n' "${reversed[@]}" | tac); do
            docker compose -f "$svc/docker-compose.yml" down 2>/dev/null || true
        done
        ;;
    restart)
        if [ -z "$1" ]; then
            for svc in "${SERVICES[@]}"; do
                docker compose -f "$svc/docker-compose.yml" restart
            done
        else
            run_one "$1" "restart"
        fi
        ;;
    update)
        if [ -z "$1" ]; then
            for svc in "${SERVICES[@]}"; do
                docker compose -f "$svc/docker-compose.yml" pull
                docker compose -f "$svc/docker-compose.yml" up -d
            done
        else
            run_one "$1" "pull"
            run_one "$1" "up -d"
        fi
        ;;
    logs)
        if [ -z "$1" ]; then
            echo "Service required: $0 logs <service>"
            exit 1
        fi
        run_one "$1" "logs -f"
        ;;
    status)
        for svc in "${SERVICES[@]}"; do
            echo "=== $svc ==="
            docker compose -f "$svc/docker-compose.yml" ps 2>/dev/null || echo "not found"
            echo ""
        done
        ;;
    perm)
        for entry in "${PERMISSIONS[@]}"; do
            IFS=':' read -r path uid gid <<< "$entry"
            if [ -e "$path" ]; then
                chown "$uid:$gid" "$path"
                chmod "$gid" "$path"
                echo "Set $path -> $uid:$gid $gid"
            fi
        done
        ;;
    setup)
        setup_nets
        setup_env
        ;;
    *)
        usage
        ;;
esac