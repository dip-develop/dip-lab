#!/bin/bash

set -e

# ── Colors ──────────────────────────────────────────────────────────────────
readonly C_RESET='\033[0m'
readonly C_BLUE='\033[0;34m'
readonly C_GREEN='\033[0;32m'
readonly C_YELLOW='\033[1;33m'
readonly C_RED='\033[0;31m'

# ── Config ───────────────────────────────────────────────────────────────────
SERVICES_ALL=(
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

DRY_RUN=false
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Logging ──────────────────────────────────────────────────────────────────
log() {
    local level=$1 symbol color
    shift
    case $level in
        info) symbol="*" color=$C_BLUE   ;;
        ok)   symbol="+" color=$C_GREEN  ;;
        warn) symbol="!" color=$C_YELLOW ;;
        err)  symbol="!" color=$C_RED    ;;
        *)    symbol="*" color=$C_RESET  ;;
    esac
    printf "%s [%b%s%b] %s\n" "$(date '+%H:%M:%S')" "$color" "$symbol" "$C_RESET" "$*"
}

# ── Load disabled services ──────────────────────────────────────────────────
DISABLED_FILE="$SCRIPT_DIR/.disabled_services"

if [ -f "$DISABLED_FILE" ]; then
    mapfile -t DISABLED < <(grep -v '^\s*#' "$DISABLED_FILE" | tr -d ' \t\r' | grep -v '^$')
else
    DISABLED=()
fi

is_disabled() {
    local svc=$1
    for d in "${DISABLED[@]}"; do
        [ "$svc" = "$d" ] && return 0
    done
    return 1
}

SERVICES=()
for svc in "${SERVICES_ALL[@]}"; do
    is_disabled "$svc" || SERVICES+=("$svc")
done

# ── Networks ─────────────────────────────────────────────────────────────────
setup_nets() {
    log info "Setting up networks..."
    docker network create web      2>/dev/null || log ok "Network 'web' already exists"
    docker network create internal 2>/dev/null || log ok "Network 'internal' already exists"
    docker network create database 2>/dev/null || log ok "Network 'database' already exists"
    log ok "Networks ready"
}

# ── Wait for ready (containers up, not starting / unhealthy) ────────────────
wait_for_ready() {
    local svc=$1
    local timeout=${2:-90}
    local interval=3 elapsed=0

    [ -f "$SCRIPT_DIR/$svc/docker-compose.yml" ] || return 0

    log info "Waiting for $svc to be ready..."
    while [ $elapsed -lt $timeout ]; do
        local output
        output=$(cd "$SCRIPT_DIR/$svc" && docker compose ps 2>/dev/null) || {
            sleep "$interval"
            elapsed=$((elapsed + interval))
            continue
        }
        local body
        body=$(echo "$output" | tail -n +2)
        local lines
        lines=$(echo "$body" | grep -c . || true)

        if [ "$lines" -eq 0 ]; then
            sleep "$interval"
            elapsed=$((elapsed + interval))
            continue
        fi

        if echo "$body" | grep -q "starting"; then
            sleep "$interval"
            elapsed=$((elapsed + interval))
            continue
        fi

        if echo "$body" | grep -q "(unhealthy)"; then
            sleep "$interval"
            elapsed=$((elapsed + interval))
            continue
        fi

        local running
        running=$(echo "$body" | grep -c "Up" || true)
        if [ "$running" -ge "$lines" ]; then
            log ok "$svc is ready ($((elapsed + interval))s)"
            return 0
        fi
        sleep "$interval"
        elapsed=$((elapsed + interval))
    done
    log warn "$svc not ready within ${timeout}s"
    return 1
}

# ── Directories ──────────────────────────────────────────────────────────────
setup_directories() {
    log info "Creating data directories..."

    for svc in "${SERVICES_ALL[@]}"; do
        if [ -f "$SCRIPT_DIR/$svc/docker-compose.yml" ]; then
            mkdir -p "$SCRIPT_DIR/$svc/data"
        fi
        if [ -f "$SCRIPT_DIR/$svc/setup.sh" ]; then
            log info "Running $svc/setup.sh..."
            bash "$SCRIPT_DIR/$svc/setup.sh"
        fi
    done

    if [ -d /mnt/object-storage/data ] 2>/dev/null; then
        log info "Creating object storage directories..."
        timeout 3 mkdir -p /mnt/object-storage/data/gallery/{upload,thumbs,profile,backups,library,encoded-video} 2>/dev/null || true
        timeout 3 mkdir -p /mnt/object-storage/data/{docs,automation} 2>/dev/null || true
        for dir in upload thumbs backups library encoded-video; do
            timeout 3 touch "/mnt/object-storage/data/gallery/$dir/.immich" 2>/dev/null || true
        done
        log ok "Object storage directories ready"
    else
        log warn "Object storage not mounted at /mnt/object-storage/data"
    fi

    chmod -R 755 "$SCRIPT_DIR"/*/data 2>/dev/null || true
    log ok "Data directories created"
}

# ── Permissions ──────────────────────────────────────────────────────────────
fix_permissions() {
    log info "Fixing permissions..."

    chmod 755 "$SCRIPT_DIR"
    chmod 750 "$SCRIPT_DIR/manager.sh"
    chmod +x "$SCRIPT_DIR/proxy/entrypoint.sh" 2>/dev/null || true

    find "$SCRIPT_DIR" -name ".env" -exec chmod 600 {} \; 2>/dev/null || true
    find "$SCRIPT_DIR/proxy" -name "acme.json" -exec chmod 600 {} \; 2>/dev/null || true

    mkdir -p "$SCRIPT_DIR/automation/data/automation"
    chown -R 1000:1000 "$SCRIPT_DIR/automation/data/automation" 2>/dev/null || true

    mkdir -p "$SCRIPT_DIR/cloud/data/cloud"
    chown -R 1000:1000 "$SCRIPT_DIR/cloud/data" 2>/dev/null || true

    mkdir -p "$SCRIPT_DIR/databases/data"
    chown -R 999:999 "$SCRIPT_DIR/databases/data/postgres" 2>/dev/null || true
    chown -R 999:999 "$SCRIPT_DIR/databases/data/mysql" 2>/dev/null || true
    chown -R 6379:6379 "$SCRIPT_DIR/databases/data/redis" 2>/dev/null || true

    log ok "Permissions fixed"
}

# ── Parallel execution ───────────────────────────────────────────────────────
run_all_parallel() {
    local cmd=$1
    shift
    local pids=() failed=0

    for svc in "${SERVICES[@]}"; do
        [ -f "$SCRIPT_DIR/$svc/docker-compose.yml" ] || continue
        if [ "$DRY_RUN" = true ]; then
            log info "DRY-RUN: $svc: docker compose $cmd $*"
        else
            log info "$svc: docker compose $cmd $*"
            (cd "$SCRIPT_DIR/$svc" && docker compose "$cmd" "$@") &
            pids+=($!)
        fi
    done

    for pid in "${pids[@]}"; do
        wait "$pid" || failed=$((failed + 1))
    done
    [ $failed -gt 0 ] && log warn "$failed service(s) had issues"
    return 0
}

# ── Start all (databases → proxy → rest in parallel) ────────────────────────
start_all() {
    if [ "$DRY_RUN" = true ]; then
        log info "DRY-RUN: start all services"
        for svc in "${SERVICES[@]}"; do
            echo "         $svc: docker compose up -d"
        done
        return
    fi

    # 1. databases (blocking, wait for ready)
    if [[ " ${SERVICES[*]} " =~ " databases " ]] && [ -f "$SCRIPT_DIR/databases/docker-compose.yml" ]; then
        log info "databases: starting..."
        (cd "$SCRIPT_DIR/databases" && docker compose up -d)
        wait_for_ready "databases"
    fi

    # 2. proxy (wait for it)
    if [[ " ${SERVICES[*]} " =~ " proxy " ]] && [ -f "$SCRIPT_DIR/proxy/docker-compose.yml" ]; then
        log info "proxy: starting..."
        (cd "$SCRIPT_DIR/proxy" && docker compose up -d)
        wait_for_ready "proxy"
    fi

    # 3. everything else in parallel
    local pids=() failed=0
    for svc in "${SERVICES[@]}"; do
        [ "$svc" = "databases" ] || [ "$svc" = "proxy" ] && continue
        [ -f "$SCRIPT_DIR/$svc/docker-compose.yml" ] || continue
        log info "$svc: starting..."
        (cd "$SCRIPT_DIR/$svc" && docker compose up -d) &
        pids+=($!)
    done

    for pid in "${pids[@]}"; do
        wait "$pid" || failed=$((failed + 1))
    done

    if [ $failed -eq 0 ]; then log ok "All services started"
    else log warn "$failed service(s) had startup issues"; fi
}

# ── Stop all (reversed, databases last) ─────────────────────────────────────
stop_all() {
    if [ "$DRY_RUN" = true ]; then
        log info "DRY-RUN: stop all services"
        for svc in $(printf '%s\n' "${SERVICES[@]}" | tac); do
            echo "         $svc: docker compose down"
        done
        return
    fi

    local pids=() failed=0
    for svc in $(printf '%s\n' "${SERVICES[@]}" | tac); do
        [ "$svc" = "databases" ] && continue
        [ -f "$SCRIPT_DIR/$svc/docker-compose.yml" ] || continue
        log info "$svc: stopping..."
        (cd "$SCRIPT_DIR/$svc" && docker compose down 2>/dev/null) &
        pids+=($!)
    done

    for pid in "${pids[@]}"; do wait "$pid" || failed=$((failed + 1)); done

    if [[ " ${SERVICES[*]} " =~ " databases " ]] && [ -f "$SCRIPT_DIR/databases/docker-compose.yml" ]; then
        log info "databases: stopping..."
        (cd "$SCRIPT_DIR/databases" && docker compose down 2>/dev/null) || true
    fi

    log ok "All services stopped"
}

# ── Profiles ─────────────────────────────────────────────────────────────────
profile_cmd() {
    local action=$1
    shift

    case $action in
        list)
            log info "Available profiles:"
            if [ -d "$SCRIPT_DIR/.profiles" ]; then
                for f in "$SCRIPT_DIR/.profiles"/*; do
                    [ -f "$f" ] && echo "  - $(basename "$f")"
                done
            fi
            if [ -f "$DISABLED_FILE" ]; then
                log info "Active: custom (.disabled_services)"
            else
                log info "Active: full (all services enabled)"
            fi
            ;;
        show)
            if [ -f "$DISABLED_FILE" ]; then
                log info "Disabled services:"
                grep -v '^\s*#' "$DISABLED_FILE" | grep -v '^$' | sed 's/^/  /'
            else
                log info "No services disabled"
            fi
            ;;
        enable)
            local svc=$1
            [ -z "$svc" ] && { log err "Service name required"; return 1; }
            if [ -f "$DISABLED_FILE" ]; then
                grep -Fxv "$svc" "$DISABLED_FILE" > "${DISABLED_FILE}.tmp" 2>/dev/null || true
                mv "${DISABLED_FILE}.tmp" "$DISABLED_FILE"
                [ ! -s "$DISABLED_FILE" ] && rm -f "$DISABLED_FILE"
            fi
            log ok "$svc enabled"
            ;;
        disable)
            local svc=$1
            [ -z "$svc" ] && { log err "Service name required"; return 1; }
            echo "$svc" >> "$DISABLED_FILE"
            sort -u -o "$DISABLED_FILE" "$DISABLED_FILE"
            log ok "$svc disabled"
            ;;
        *)
            local profile=$action
            local profile_file="$SCRIPT_DIR/.profiles/$profile"
            if [ -f "$profile_file" ]; then
                cp "$profile_file" "$DISABLED_FILE"
                log ok "Switched to profile '$profile'"
            else
                log err "Profile '$profile' not found in .profiles/"
                return 1
            fi
            ;;
    esac
}

# ── Backup / Restore ─────────────────────────────────────────────────────────
backup_cmd() {
    local backup_dir="${1:-$SCRIPT_DIR/backups}"
    mkdir -p "$backup_dir"
    local date_str
    date_str=$(date '+%Y%m%d-%H%M%S')
    local backup_file="$backup_dir/dm-home-backup-$date_str.tar.gz"

    log info "Creating backup: $backup_file"
    local dirs=()
    for svc in "${SERVICES_ALL[@]}"; do
        [ -d "$SCRIPT_DIR/$svc/data" ] && dirs+=("$svc/data")
    done

    if [ ${#dirs[@]} -eq 0 ]; then
        log warn "No data directories to backup"
        return
    fi

    tar czf "$backup_file" -C "$SCRIPT_DIR" "${dirs[@]}" 2>/dev/null
    log ok "Backup: $backup_file ($(du -h "$backup_file" | cut -f1))"
}

restore_cmd() {
    local backup_file=$1
    if [ -z "$backup_file" ] || [ ! -f "$backup_file" ]; then
        log err "File not found: $backup_file"
        log info "Usage: $0 restore <backup-file>"
        return 1
    fi

    log warn "Restore from $backup_file will OVERWRITE existing data directories"
    log warn "Ensure services are stopped first"
    read -rp "Continue? [y/N] " confirm
    [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && { log info "Cancelled"; return; }

    log info "Restoring..."
    tar xzf "$backup_file" -C "$SCRIPT_DIR"
    log ok "Restored from $backup_file"
}

# ── Run one service ──────────────────────────────────────────────────────────
run_one() {
    local svc=$1
    shift

    if [ "$DRY_RUN" = true ]; then
        log info "DRY-RUN: $svc: docker compose $*"
        return
    fi

    if [ -d "$SCRIPT_DIR/$svc" ] && [ -f "$SCRIPT_DIR/$svc/docker-compose.yml" ]; then
        (cd "$SCRIPT_DIR/$svc" && docker compose "$@")
    else
        log err "Service '$svc' not found"
        exit 1
    fi
}

# ── Usage ────────────────────────────────────────────────────────────────────
usage() {
    cat <<EOF
Usage: $0 [options] <command> [args]

Commands:
  start [svc]       Start all or one service (databases → proxy → rest)
  stop [svc]        Stop all or one service (databases last)
  restart [svc]     Restart all or one service
  update [svc]      Pull images + recreate containers
  build <svc>       Build service image
  logs <svc>        Tail logs for a service
  status            Show container status (enabled services only)
  exec <svc> <cmd>  Run command in a service container
  setup             Create networks + data directories
  perm              Fix file permissions / ownership
  profile           Manage disabled-service profiles
    list            List available profiles
    show            Show current disabled services
    enable <svc>    Re-enable a service
    disable <svc>   Disable a service
    <name>          Switch to a predefined profile
  backup [dir]      Tar.gz data directories
  restore <file>    Restore data from backup archive
  clean             Prune unused Docker volumes / networks
  stop-all          Stop every running container
  full-cleanup      Nuke containers, images, volumes, networks

Options:
  -n, --dry-run     Print what would be done, don't execute

EOF
    echo "Services:"
    for svc in "${SERVICES_ALL[@]}"; do
        if is_disabled "$svc"; then
            echo -e "  ${C_YELLOW}- $svc (disabled)${C_RESET}"
        else
            echo "  - $svc"
        fi
    done
    echo ""
    echo "Examples:"
    echo "  $0 setup                          # init everything"
    echo "  $0 start                          # start enabled services"
    echo "  $0 -n start                       # dry-run"
    echo "  $0 start llm                      # start llm even if disabled"
    echo "  $0 profile minimal                # switch to minimal profile"
    echo "  $0 profile disable llm            # disable llm on the fly"
    echo "  $0 logs gallery --tail 50"
}

# ══════════════════════════════════════════════════════════════════════════════
#  MAIN
# ══════════════════════════════════════════════════════════════════════════════

# ── Parse global flags ───────────────────────────────────────────────────────
POSITIONAL=()
while [ $# -gt 0 ]; do
    case "$1" in
        -n|--dry-run) DRY_RUN=true; shift ;;
        *) POSITIONAL+=("$1"); shift ;;
    esac
done
set -- "${POSITIONAL[@]}"

ACTION=${1:-}
shift || true

case $ACTION in
    start)
        setup_nets
        if [ -z "${1:-}" ] || [ "$1" = "all" ]; then
            start_all
        else
            run_one "$1" up -d
        fi
        ;;
    stop)
        if [ -z "${1:-}" ] || [ "$1" = "all" ]; then
            stop_all
        else
            run_one "$1" down
        fi
        ;;
    restart)
        if [ -z "${1:-}" ] || [ "$1" = "all" ]; then
            run_all_parallel restart
        else
            run_one "$1" restart
        fi
        ;;
    update)
        if [ -z "${1:-}" ] || [ "$1" = "all" ]; then
            log info "Pulling images..."
            run_all_parallel pull
            log info "Recreating containers..."
            start_all
        else
            run_one "$1" pull
            run_one "$1" up -d
        fi
        ;;
    build)
        [ -z "${1:-}" ] && { log err "Service required: $0 build <svc>"; exit 1; }
        svc="$1"; shift
        run_one "$svc" build "$@"
        ;;
    logs)
        [ -z "${1:-}" ] && { log err "Service required: $0 logs <svc>"; exit 1; }
        svc="$1"; shift
        run_one "$svc" logs -f "$@"
        ;;
    exec)
        [ -z "${1:-}" ] || [ -z "${2:-}" ] && { log err "Usage: $0 exec <svc> <cmd>"; exit 1; }
        svc="$1"; shift
        run_one "$svc" exec "$@"
        ;;
    status)
        for svc in "${SERVICES[@]}"; do
            if [ -f "$SCRIPT_DIR/$svc/docker-compose.yml" ]; then
                echo "=== $svc ==="
                (cd "$SCRIPT_DIR/$svc" && docker compose ps 2>/dev/null) || echo "  (not running)"
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
    profile)
        profile_cmd "$@"
        ;;
    backup)
        backup_cmd "$1"
        ;;
    restore)
        restore_cmd "$1"
        ;;
    clean)
        log info "Cleaning unused Docker resources..."
        docker volume prune -f
        docker network prune -f
        log ok "Clean complete"
        ;;
    stop-all)
        log info "Stopping all running containers..."
        docker stop $(docker ps -q) 2>/dev/null || true
        log ok "All containers stopped"
        ;;
    full-cleanup)
        log warn "Full Docker cleanup..."
        docker stop $(docker ps -q) 2>/dev/null || true
        docker rm $(docker ps -aq) 2>/dev/null || true
        docker rmi $(docker images -q) 2>/dev/null || true
        docker volume prune -f
        docker network prune -f
        docker builder prune -af
        log ok "Full cleanup done"
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        usage
        ;;
esac
