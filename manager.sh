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
    "containers"
    "cloud"
    "docs"
    "automation"
    "gallery"
    "ai-agent"
    "dev-agents"
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
    find "$SCRIPT_DIR" -name entrypoint.sh -exec chmod +x {} \; 2>/dev/null || true

    find "$SCRIPT_DIR" -name ".env" -exec chmod 600 {} \; 2>/dev/null || true
    find "$SCRIPT_DIR/proxy" -name "acme.json" -exec chmod 600 {} \; 2>/dev/null || true

    mkdir -p "$SCRIPT_DIR/automation/data/automation"
    chown -R 1000:1000 "$SCRIPT_DIR/automation/data/automation" 2>/dev/null || true

    mkdir -p "$SCRIPT_DIR/cloud/data/cloud"
    # seafile-mc v13 (NON_ROOT) runs as uid 8000
    chown -R 8000:8000 "$SCRIPT_DIR/cloud/data" 2>/dev/null || true
    # Production data lives on object storage, not in repo
    if [ -d /mnt/object-storage/data/cloud ]; then
        timeout 10 chown -R 8000:8000 /mnt/object-storage/data/cloud 2>/dev/null || log warn "Could not chown /mnt/object-storage/data/cloud (need root?)"
    fi

    mkdir -p "$SCRIPT_DIR/databases/data"
    chown -R 999:999 "$SCRIPT_DIR/databases/data/postgres" 2>/dev/null || true
    chown -R 999:999 "$SCRIPT_DIR/databases/data/mysql" 2>/dev/null || true
    chown -R 6379:6379 "$SCRIPT_DIR/databases/data/redis" 2>/dev/null || true

    # dev-agents: ownership must match the container user. UID/GID are
    # configurable via dev-agents/.env (DEVELOP_UID/DEVELOP_GID,
    # defaults 1000:1000) and are baked into the image at build time.
    local da_uid=1000 da_gid=1000
    if [ -f "$SCRIPT_DIR/dev-agents/.env" ]; then
        da_uid=$(grep -E '^DEVELOP_UID=' "$SCRIPT_DIR/dev-agents/.env" | cut -d= -f2 | tr -d '[:space:]')
        da_gid=$(grep -E '^DEVELOP_GID=' "$SCRIPT_DIR/dev-agents/.env" | cut -d= -f2 | tr -d '[:space:]')
    fi
    da_uid=${da_uid:-1000}
    da_gid=${da_gid:-1000}
    mkdir -p "$SCRIPT_DIR/dev-agents/data/projects" "$SCRIPT_DIR/dev-agents/data/config"
    chown -R "$da_uid:$da_gid" "$SCRIPT_DIR/dev-agents/data/projects" "$SCRIPT_DIR/dev-agents/data/config" 2>/dev/null || true

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

# ── Pull one service's images, capture local image IDs before & after.
# Writes two files to a temp dir: $TMP_DIR/$svc.before / $svc.after
# Each is a sorted list of "repo:tag <sha256>" lines (one per image).
# If the service is locally built (no pulled images), the lists may be
# empty - caller treats that as "no remote update possible".
pull_one_capture() {
    local svc=$1 tmp=$2
    if [ ! -f "$SCRIPT_DIR/$svc/docker-compose.yml" ]; then
        return 1
    fi
    local log_file="$tmp/$svc.log"
    local status_file="$tmp/$svc.status"

    # Snapshot images currently referenced by this compose project.
    (cd "$SCRIPT_DIR/$svc" && \
        docker compose config --images 2>/dev/null \
            | sort -u > "$tmp/$svc.images") || true

    # Capture current local digests for those images.
    : > "$tmp/$svc.before"
    while IFS= read -r img; do
        [ -z "$img" ] && continue
        # `docker image inspect` returns RepoDigests for pulled images.
        local dig
        dig=$(docker image inspect --format '{{range .RepoDigests}}{{.}}{{"\n"}}{{end}}' "$img" 2>/dev/null | sort -u | tr '\n' '|')
        printf '%s %s\n' "$img" "${dig%|}" >> "$tmp/$svc.before"
    done < "$tmp/$svc.images"
    # Pull.
    if [ "$DRY_RUN" = true ]; then
        log info "DRY-RUN: $svc: docker compose pull"
        echo "DRYRUN" > "$status_file"
        return 0
    fi

    if (cd "$SCRIPT_DIR/$svc" && docker compose pull) >"$log_file" 2>&1; then
        # Re-snapshot digests.
        : > "$tmp/$svc.after"
        while IFS= read -r img; do
            [ -z "$img" ] && continue
            local dig
            dig=$(docker image inspect --format '{{range .RepoDigests}}{{.}}{{"\n"}}{{end}}' "$img" 2>/dev/null | sort -u | tr '\n' '|')
            printf '%s %s\n' "$img" "${dig%|}" >> "$tmp/$svc.after"
        done < "$tmp/$svc.images"

        if diff -q "$tmp/$svc.before" "$tmp/$svc.after" >/dev/null 2>&1; then
            echo "uptodate" > "$status_file"
        else
            echo "updated" > "$status_file"
        fi
        return 0
    else
        echo "failed" > "$status_file"
        return 1
    fi
}

# ── update-all: smart, per-service pull + recreate with status output.
#
# Honors boot order (databases -> proxy -> rest), pulls every service in
# parallel, only recreates containers whose image actually changed, prints
# a per-service summary table at the end.
#
# Flags:
#   --filter <pattern>   only update services whose name matches the
#                        extended-regex pattern (matches whole service
#                        name, case-insensitive)
#   --no-recreate       pull only, do not recreate containers even if
#                        an image changed
#   --prune             after the run, remove dangling images
#                        (`docker image prune -f`)
#   --no-backup         skip the pre-flight data-dir backup prompt
#
# Combine with `-n` for a dry run that prints the would-be status table.
update_all() {
    local filter="" recreate=true prune=false do_backup=true
    while [ $# -gt 0 ]; do
        case "$1" in
            --filter) filter=${2:-}; shift 2 ;;
            --no-recreate) recreate=false; shift ;;
            --prune) prune=true; shift ;;
            --no-backup) do_backup=false; shift ;;
            *) log err "Unknown update-all flag: $1"; return 1 ;;
        esac
    done

    # Build the list of services to update, honoring the disabled list
    # and the --filter pattern.
    local targets=()
    for svc in "${SERVICES_ALL[@]}"; do
        is_disabled "$svc" && continue
        if [ -n "$filter" ]; then
            if ! [[ "$svc" =~ $filter ]]; then
                continue
            fi
        fi
        [ -f "$SCRIPT_DIR/$svc/docker-compose.yml" ] || continue
        targets+=("$svc")
    done

    if [ ${#targets[@]} -eq 0 ]; then
        log warn "No services match (filter='$filter', enabled set is empty?)"
        return 0
    fi

    log info "update-all: ${#targets[@]} service(s)${filter:+ (filter: $filter)}"
    for s in "${targets[@]}"; do
        log info "  - $s"
    done

    if [ "$DRY_RUN" = true ]; then
        log info "DRY-RUN: skipping pull, status table, recreate, backup, prune"
        return 0
    fi

    # Pre-flight backup (skippable).
    if [ "$do_backup" = true ]; then
        log info "Pre-flight data-dir backup..."
        backup_cmd "$SCRIPT_DIR/backups" || log warn "Pre-flight backup failed; continuing"
    fi

    # Pull in parallel. Each service writes its status to $TMP.
    local tmp
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' RETURN

    local pids=() failed_pulls=0
    for svc in "${targets[@]}"; do
        log info "$svc: pulling..."
        pull_one_capture "$svc" "$tmp" &
        pids+=($!)
    done
    for pid in "${pids[@]}"; do
        wait "$pid" || failed_pulls=$((failed_pulls + 1))
    done

    # Build status table.
    local updated=() uptodate=() failed=() noup=()
    for svc in "${targets[@]}"; do
        local s="unknown"
        [ -f "$tmp/$svc.status" ] && s=$(cat "$tmp/$svc.status")
        case "$s" in
            updated)   updated+=("$svc") ;;
            uptodate)  uptodate+=("$svc") ;;
            failed)    failed+=("$svc") ;;
            *)         noup+=("$svc") ;;
        esac
    done

    log ok "Pull phase complete"
    log info "  updated    : ${#updated[@]}"
    log info "  up-to-date : ${#uptodate[@]}"
    [ ${#failed[@]} -gt 0 ]   && log warn "  failed     : ${#failed[@]} (${failed[*]})"
    [ ${#noup[@]} -gt 0 ]     && log info "  no-remote  : ${#noup[@]} (locally built, see ${tmp})"

    # Decide which to recreate.
    local to_recreate=()
    if [ "$recreate" = true ]; then
        to_recreate=("${updated[@]}")
    fi

    if [ ${#to_recreate[@]} -eq 0 ]; then
        log ok "Nothing to recreate"
    else
        log info "Recreating ${#to_recreate[@]} service(s): ${to_recreate[*]}"

        # Honor boot order: databases first (blocking), then proxy, then rest.
        local boot_first=() boot_mid=() boot_rest=()
        for s in "${to_recreate[@]}"; do
            case "$s" in
                databases) boot_first+=("$s") ;;
                proxy)     boot_mid+=("$s") ;;
                *)         boot_rest+=("$s") ;;
            esac
        done

        for s in "${boot_first[@]}"; do
            log info "$s: up -d (blocking)"
            (cd "$SCRIPT_DIR/$s" && docker compose up -d) || log warn "$s: up -d failed"
            wait_for_ready "$s" 180 || log warn "$s: not ready within timeout"
        done
        for s in "${boot_mid[@]}"; do
            log info "$s: up -d (blocking)"
            (cd "$SCRIPT_DIR/$s" && docker compose up -d) || log warn "$s: up -d failed"
            wait_for_ready "$s" 120 || log warn "$s: not ready within timeout"
        done
        if [ ${#boot_rest[@]} -gt 0 ]; then
            local rpids=() rfails=0
            for s in "${boot_rest[@]}"; do
                log info "$s: up -d"
                (cd "$SCRIPT_DIR/$s" && docker compose up -d) &
                rpids+=($!)
            done
            for pid in "${rpids[@]}"; do
                wait "$pid" || rfails=$((rfails + 1))
            done
            [ $rfails -gt 0 ] && log warn "$rfails service(s) failed to recreate"
        fi
    fi

    # Final per-service status table.
    echo
    log info "Per-service status:"
    printf "  %-15s %-12s %s\n" "SERVICE" "IMAGE" "STATUS"
    printf "  %-15s %-12s %s\n" "-------" "-----" "------"
    for svc in "${targets[@]}"; do
        local s="unknown"
        [ -f "$tmp/$svc.status" ] && s=$(cat "$tmp/$svc.status")
        local img="-"
        if [ -f "$tmp/$svc.images" ]; then
            local count
            count=$(wc -l < "$tmp/$svc.images" 2>/dev/null || echo 0)
            img="${count} image(s)"
        fi
        case "$s" in
            updated)   printf "  %-15s %-12s %b%s%b\n" "$svc" "$img" "$C_GREEN" "updated"   "$C_RESET" ;;
            uptodate)  printf "  %-15s %-12s %b%s%b\n" "$svc" "$img" "$C_BLUE"  "up-to-date" "$C_RESET" ;;
            failed)    printf "  %-15s %-12s %b%s%b\n" "$svc" "$img" "$C_RED"   "FAILED"     "$C_RESET" ;;
            *)         printf "  %-15s %-12s %s\n"   "$svc" "$img" "$s" ;;
        esac
    done
    echo

    if [ "$prune" = true ]; then
        log info "Pruning dangling images..."
        docker image prune -f || log warn "image prune failed"
    fi

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
    local backup_file="$backup_dir/diplab-backup-$date_str.tar.gz"

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
  update-all [opts] Smart pull + recreate with per-service status table.
                   Honors boot order. Flags:
                     --filter <regex>   only services matching regex
                     --no-recreate     pull only, do not recreate
                     --no-backup       skip the pre-flight data-dir backup
                     --prune           also run "docker image prune -f"
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
    echo "  $0 start dev-agents               # start the developer workstation"
    echo "  $0 update-all --filter '^auto|cloud$'  # update only automation + cloud"
    echo "  $0 update-all --no-backup         # update everything, skip pre-flight backup"
    echo "  $0 profile core                   # switch to core profile"
    echo "  $0 profile dev                    # switch to dev profile (default + automation)"
    echo "  $0 profile disable dev-agents     # disable dev-agents on the fly"
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
            local svc="$1"
            # Check if service has a local build (build: section in compose)
            if [ -f "$SCRIPT_DIR/$svc/docker-compose.yml" ] && grep -q '^\s*build:' "$SCRIPT_DIR/$svc/docker-compose.yml"; then
                log info "$svc is locally built — skipping pull, rebuilding instead"
                run_one "$svc" build
            else
                run_one "$svc" pull
            fi
            run_one "$svc" up -d
        fi
        ;;
    update-all)
        update_all "$@"
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
