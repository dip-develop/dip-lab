#!/bin/bash

set -e

SERVICES=(
    "databases"
    "proxy"
    "monitoring"
    "passwords"
    "dockerui"
    "cloud"
    "docs"
    "automation"
    "gallery"
    "llm"
    "aiagent"
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
    
    # Automation specific: container expects /home/node/.n8n
    mkdir -p automation/data/automation
    
    # Docs (Paperless) specific: subdirectories for bind mounts
    mkdir -p docs/data/docs/{export,consume,media}

    # Cloud specific: parent dir for bind mount (docker auto-creates seafile-data on start)
    mkdir -p cloud/data/cloud
    
    # Gallery (Immich) specific: requires subdirectories with .immich markers
    mkdir -p gallery/data/gallery/{upload,thumbs,profile,backups,library,encoded-video}
    for dir in upload thumbs profile backups library encoded-video; do
        touch "gallery/data/gallery/$dir/.immich"
    done
    
    mkdir -p proxy/dynamic proxy/logs
    mkdir -p databases/data/{postgres,mysql,redis}
    mkdir -p monitoring/data
    mkdir -p aiagent/data
    
    # Object Storage directories (S3-compatible storage mount)
    # Only create if /mnt/object-storage/data is accessible
    if mountpoint -q /mnt/object-storage/data 2>/dev/null || [ -d /mnt/object-storage/data ]; then
        echo "[*] Creating object storage directories..."
        mkdir -p /mnt/object-storage/data/gallery/upload
        mkdir -p /mnt/object-storage/data/gallery/thumbs
        mkdir -p /mnt/object-storage/data/gallery/profile
        mkdir -p /mnt/object-storage/data/gallery/backups
        mkdir -p /mnt/object-storage/data/gallery/library
        mkdir -p /mnt/object-storage/data/gallery/encoded-video
        # Cloud uses local storage (Seafile's native S3 backend for object storage)
        mkdir -p /mnt/object-storage/data/docs
        mkdir -p /mnt/object-storage/data/automation
        # Create .immich markers for gallery folders
        for dir in upload thumbs backups library encoded-video; do
            touch "/mnt/object-storage/data/gallery/$dir/.immich" 2>/dev/null || true
        done
        chmod -R 755 /mnt/object-storage/data/* 2>/dev/null || true
        echo "[+] Object storage directories ready"
    else
        echo "[!] Object storage not mounted at /mnt/object-storage/data"
        echo "[!] Services requiring object storage will use local NVMe"
    fi
    
    chmod -R 755 */data 2>/dev/null || true
    
    # Automation runs as node (UID 1000)
    chown -R 1000:1000 automation/data/automation 2>/dev/null || true
    
    # Cloud runs as root
    chown -R 0:0 cloud/data 2>/dev/null || true
    
    echo "[*] Data directories created"
}

fix_permissions() {
    echo "[*] Fixing permissions..."
    
    # Fix script permissions
    chmod 755 "${SCRIPT_DIR}"
    chmod 750 "${SCRIPT_DIR}/manager.sh"
    chmod +x "${SCRIPT_DIR}/proxy/entrypoint.sh" 2>/dev/null || true
    
    # Fix .env files permissions (sensitive data)
    find "${SCRIPT_DIR}" -name ".env" -exec chmod 600 {} \; 2>/dev/null || true
    find "${SCRIPT_DIR}/proxy" -name "acme.json" -exec chmod 600 {} \; 2>/dev/null || true
    
    # Automation runs as node (UID 1000) - needs write access to its data
    mkdir -p "${SCRIPT_DIR}/automation/data/automation"
    chown -R 1000:1000 "${SCRIPT_DIR}/automation/data/automation" 2>/dev/null || true
    
    # Cloud runs as root
    mkdir -p "${SCRIPT_DIR}/cloud/data/cloud"
    chown -R 0:0 "${SCRIPT_DIR}/cloud/data" 2>/dev/null || true
    
    # Databases: PostgreSQL (999), MySQL (999), Redis (6379)
    mkdir -p "${SCRIPT_DIR}/databases/data"
    chown -R 999:999 "${SCRIPT_DIR}/databases/data/postgres" 2>/dev/null || true
    chown -R 999:999 "${SCRIPT_DIR}/databases/data/mysql" 2>/dev/null || true
    chown -R 6379:6379 "${SCRIPT_DIR}/databases/data/redis" 2>/dev/null || true
    
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
    echo "  stop-all        - Stop all running Docker containers"
    echo "  full-cleanup    - Stop all containers, remove all containers/images/volumes/networks"
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
    echo "  $0 logs gallery --tail 100"
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
        all)
            run_all up -d "$@"
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
        if [ -z "${1:-}" ]; then
            echo "[!] IMPORTANT: databases must start first"
        fi
        setup_nets
        if [ -z "${1:-}" ]; then
            run_all up -d
        else
            run_one "$1" up -d
        fi
        ;;
    stop)
        if [ -z "${1:-}" ]; then
            for svc in $(printf '%s\n' "${SERVICES[@]}" | tac); do
                if [ -f "$svc/docker-compose.yml" ]; then
                    (cd "$svc" && docker compose down 2>/dev/null) || true
                fi
            done
        else
            svc="$1"
            if [ -d "$svc" ] && [ -f "$svc/docker-compose.yml" ]; then
                (cd "$svc" && docker compose down)
            else
                echo "[!] Service '$svc' not found"
                exit 1
            fi
        fi
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
    build)
        if [ -z "${1:-}" ]; then
            echo "[!] Service required: $0 build <service>"
            exit 1
        fi
        svc="$1"
        echo "[*] Building service: $svc"
        (cd "$svc" && docker compose build "$@")
        ;;
    logs)
        if [ -z "${1:-}" ]; then
            echo "[!] Service required: $0 logs <service>"
            exit 1
        fi
        svc="$1"
        shift
        if [ -d "$svc" ] && [ -f "$svc/docker-compose.yml" ]; then
            (cd "$svc" && docker compose logs -f "$@")
        else
            echo "[!] Service '$svc' not found"
            exit 1
        fi
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
    stop-all)
        echo "[*] Stopping all running Docker containers..."
        docker stop $(docker ps -q) 2>/dev/null || true
        echo "[+] All containers stopped"
        ;;
    full-cleanup)
        echo "[*] Full Docker cleanup..."
        docker stop $(docker ps -q) 2>/dev/null || true
        docker rm $(docker ps -aq) 2>/dev/null || true
        docker rmi $(docker images -q) 2>/dev/null || true
        docker volume prune -f
        docker network prune -f
        docker builder prune -af
        echo "[+] Full cleanup done"
        ;;
    *)
        usage
        ;;
esac