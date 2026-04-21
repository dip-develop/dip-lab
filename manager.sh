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
    echo "  setup         - Setup networks"
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
        ;;
    *)
        usage
        ;;
esac