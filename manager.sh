#!/bin/bash

set -e

SERVICES=(
    "proxy"
    "vaultwarden"
    "portainer"
    "database"
    "nextcloud"
    "paperless"
    "n8n"
    "immich"
    "llm"
    "openclaw"
    "mailcow"
)

readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly DOCKER_SOCKET="/var/run/docker.sock"
readonly SRV_DIR="/srv"

readonly UID_DOCKER=1000
readonly GID_DOCKER=1000

setup_nets() {
    echo "[*] Setting up networks..."
    docker network create web 2>/dev/null || echo "[+] Network 'web' already exists"
    docker network create internal 2>/dev/null || echo "[+] Network 'internal' already exists"
    docker network create database 2>/dev/null || echo "[+] Network 'database' already exists"
    docker network create paperless_internal 2>/dev/null || echo "[+] Network 'paperless_internal' already exists"
    docker network create nextcloud_internal 2>/dev/null || echo "[+] Network 'nextcloud_internal' already exists"
    echo "[*] Networks ready"
}

setup_directories() {
    echo "[*] Creating directory structure in ${SRV_DIR}..."
    
    mkdir -p "${SRV_DIR}"/{proxy,portainer,vaultwarden,nextcloud,paperless,n8n,immich,llm,openclaw,mailcow,database}
    mkdir -p "${SRV_DIR}/proxy"/{logs,dynamic,certs}
    mkdir -p "${SRV_DIR}/portainer"/{data,certs}
    mkdir -p "${SRV_DIR}/vaultwarden"/data
    mkdir -p "${SRV_DIR}/nextcloud"/{app,data,db,redis}
    mkdir -p "${SRV_DIR}/paperless"/{data,db,redis,export,consume}
    mkdir -p "${SRV_DIR}/n8n"/{data,db}
    mkdir -p "${SRV_DIR}/immich"/{db,redis,thumbs,profile,ml-cache}
    mkdir -p "${SRV_DIR}/llm"/models
    mkdir -p "${SRV_DIR}/openclaw"/{data,workspace}
    mkdir -p "${SRV_DIR}/mailcow"/{data,mail,postfix,dovecot,redis,filter,solr,mysql}
    mkdir -p "${SRV_DIR}/database"/{postgres,mysql,redis}
    
    chown -R "${UID_DOCKER}:${GID_DOCKER}" "${SRV_DIR}"
    chmod -R 755 "${SRV_DIR}"
    chmod -R 700 "${SRV_DIR}/vaultwarden" 2>/dev/null || true
    chmod -R 700 "${SRV_DIR}/mailcow" 2>/dev/null || true
    
    echo "[*] Directories created"
}

fix_permissions() {
    echo "[*] Fixing permissions..."
    
    find "${SCRIPT_DIR}" -type d -exec chmod 755 {} \;
    find "${SCRIPT_DIR}" -type f -exec chmod 644 {} \;
    
    chown -R "${UID_DOCKER}:${GID_DOCKER}" "${SCRIPT_DIR}"
    chmod 750 "${SCRIPT_DIR}/manager.sh"
    chmod 600 "${SCRIPT_DIR}"/*/.env 2>/dev/null || true
    
    find "${SCRIPT_DIR}/proxy" -type f -name "*.json" -exec chmod 600 {} \; 2>/dev/null || true
    
    echo "[*] Permissions fixed"
}

usage() {
    echo "Usage: $0 <command> [service]"
    echo ""
    echo "Commands:"
    echo "  start [svc]     - Start all or specific service"
    echo "  stop [svc]    - Stop all or specific service"
    echo "  restart [svc]  - Restart all or specific service"
    echo "  update [svc]  - Update (pull) all or specific service"
    echo "  logs [svc]    - Show logs for service"
    echo "  status        - Show status of all services"
    echo "  perm          - Set permissions and ownership"
    echo "  setup        - Setup networks and directories"
    echo "  clean        - Clean unused resources"
    echo ""
    echo "Services:"
    for svc in "${SERVICES[@]}"; do
        echo "  - $svc"
    done
    echo "  all           - all services"
    echo ""
    echo "Examples:"
    echo "  $0 start                # start all"
    echo "  $0 start proxy         # start proxy only"
    echo "  $0 logs immich --tail 100"
    echo "  $0 status"
}

run_all() {
    local cmd=$1
    shift
    for svc in "${SERVICES[@]}"; do
        if [ -f "$svc/docker-compose.yml" ]; then
            echo "[*] Running: $cmd on $svc"
            docker compose -f "$svc/docker-compose.yml" $cmd "$@"
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
        docker compose -f "$svc/docker-compose.yml" "$@"
    else
        echo "[!] Service '$svc' not found"
        echo "[!] Available: ${SERVICES[*]}"
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
        reversed=("${SERVICES[@]}")
        for svc in $(printf '%s\n' "${reversed[@]}" | tac); do
            if [ -f "$svc/docker-compose.yml" ]; then
                docker compose -f "$svc/docker-compose.yml" down 2>/dev/null || true
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
                docker compose -f "$svc/docker-compose.yml" ps 2>/dev/null || echo "not found"
            fi
        done
        ;;
    perm)
        fix_permissions
        ;;
    setup)
        setup_nets
        setup_directories
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