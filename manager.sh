#!/bin/bash

set -e

SERVICES=(
    "databases"
    "proxy"
    "monitoring"
    "vaultwarden"
    "portainer"
    "nextcloud"
    "paperless"
    "n8n"
    "immich"
    "llm"
    "openclaw"
    "mailcow"
)

readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly UID_DOCKER=1000
readonly GID_DOCKER=1000

setup_nets() {
    echo "[*] Setting up networks..."
    docker network create web 2>/dev/null || echo "[+] Network 'web' already exists"
    docker network create internal 2>/dev/null || echo "[+] Network 'internal' already exists"
    docker network create database 2>/dev/null || echo "[+] Network 'database' already exists"
    echo "[*] Networks ready"
}

setup_directories() {
    echo "[*] Creating data directories..."
    
    for svc in "${SERVICES[@]}"; do
        if [ -f "$svc/docker-compose.yml" ]; then
            mkdir -p "$svc/data"
        fi
    done
    
    mkdir -p proxy/dynamic proxy/logs proxy/certs
    mkdir -p databases/data
    mkdir -p monitoring/data
    
    chmod -R 755 */data 2>/dev/null || true
    
    echo "[*] Data directories created"
}

fix_permissions() {
    echo "[*] Fixing permissions..."
    
    find "${SCRIPT_DIR}" -type d -exec chmod 755 {} \;
    find "${SCRIPT_DIR}" -type f -exec chmod 644 {} \;
    
    chown -R "${UID_DOCKER}:${GID_DOCKER}" "${SCRIPT_DIR}"
    chmod 750 "${SCRIPT_DIR}/manager.sh"
    
    find "${SCRIPT_DIR}" -path "*/.env" -exec chmod 600 {} \; 2>/dev/null || true
    find "${SCRIPT_DIR}/proxy" -type f -name "*.json" -exec chmod 600 {} \; 2>/dev/null || true
    
    echo "[*] Permissions fixed"
}

usage() {
    echo "Usage: $0 <command> [service]"
    echo ""
    echo "Commands:"
    echo "  start [svc]     - Start all or specific service"
    echo "  stop [svc]      - Stop all or specific service"
    echo "  restart [svc]   - Restart all or specific service"
    echo "  update [svc]    - Update (pull) all or specific service"
    echo "  logs [svc]      - Show logs for service"
    echo "  status          - Show status of all services"
    echo "  setup           - Setup networks and directories"
    echo "  perm            - Set permissions and ownership"
    echo "  clean           - Clean unused resources"
    echo ""
    echo "Services:"
    for svc in "${SERVICES[@]}"; do
        echo "  - $svc"
    done
    echo "  all             - all services"
    echo ""
    echo "Examples:"
    echo "  $0 setup              # setup networks and dirs"
    echo "  $0 start              # start all"
    echo "  $0 start proxy        # start proxy only"
    echo "  $0 logs immich --tail 100"
}

run_all() {
    local cmd=$1
    shift
    for svc in "${SERVICES[@]}"; do
        if [ -f "$svc/docker-compose.yml" ]; then
            echo "[*] Running: $cmd on $svc"
            (cd "$svc" && docker compose $cmd "$@")
        fi
    done
}

run_one() {
    local svc=$1
    shift
    
    case "$svc" in
        docs) svc="paperless" ;;
        all)
            run_all "up -d" "$@"
            return
            ;;
    esac
    
    if [ -d "$svc" ] && [ -f "$svc/docker-compose.yml" ]; then
        (cd "$svc" && docker compose "$@")
    else
        echo "[!] Service '$svc' not found"
        exit 1
    fi
}

ACTION=${1:-}
shift || true

case $ACTION in
    start)
        setup_nets
        if [ -z "${1:-}" ]; then
            run_all "up -d"
        else
            run_one "$1" "up -d"
        fi
        ;;
    stop)
        for svc in $(printf '%s\n' "${SERVICES[@]}" | tac); do
            if [ -f "$svc/docker-compose.yml" ]; then
                (cd "$svc" && docker compose down 2>/dev/null) || true
            fi
        done
        ;;
    restart)
        if [ -z "${1:-}" ]; then
            run_all "restart"
        else
            run_one "$1" "restart"
        fi
        ;;
    update)
        if [ -z "${1:-}" ]; then
            run_all "pull"
            run_all "up -d"
        else
            run_one "$1" "pull"
            run_one "$1" "up -d"
        fi
        ;;
    logs)
        svc=${1:-}
        shift
        if [ -z "$svc" ]; then
            echo "[!] Service required: $0 logs <service>"
            exit 1
        fi
        run_one "$svc" "logs -f $@"
        ;;
    status)
        for svc in "${SERVICES[@]}"; do
            if [ -f "$svc/docker-compose.yml" ]; then
                echo "=== $svc ==="
                (cd "$svc" && docker compose ps 2>/dev/null) || echo "not found"
            fi
        done
        ;;
    setup)
        setup_nets
        setup_directories
        ;;
    perm)
        fix_permissions
        ;;
    clean)
        echo "[*] Cleaning unused Docker resources..."
        docker volume prune -f
        docker network prune -f
        ;;
    *)
        usage
        ;;
esac