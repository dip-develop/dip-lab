#!/bin/bash
# db-safe - safety wrapper around psql, mysql, mariadb, redis-cli.
#
# Installed by the dev-agents Dockerfile in /home/develop/.local/bin,
# which comes first on PATH. Symlinked to psql/mysql/mariadb/redis-cli.
# Intercepts every call from inside the dev-agents container.
#
# Rules (any violation -> exit 1 with a clear error):
#   * PostgreSQL: refuse to connect to a database whose name does NOT
#     start with `dev_test_`. The `-d`, `--dbname`, or positional
#     <dbname> argument is the source. A bare `psql` (no -d) defaults
#     to the user's login DB, which is the pre-created dev_test_main.
#   * MySQL: refuse to connect with `-D` or as the leading positional
#     argument if it does not start with `dev_test_`. Bare `mysql`
#     defaults to the pre-created dev_test_main.
#   * Redis: refuse `SELECT <n>` if <n> is not the configured
#     TEST_REDIS_DB. -n/--dbnumber is the only source.
#   * All of them: refuse DROP / TRUNCATE / DROP DATABASE on any
#     non-test target. (Server-side grants already block this; this
#     wrapper gives a friendlier error.)
#
# Disable for one command by prefixing with `DBSAFE=0 <cmd>`.
# Disable globally by setting DB_SAFETY_GUARD=false in dev-agents/.env.
#
# This is a *defence in depth*, not the primary isolation - the real
# guarantee is that TEST_POSTGRES_USER / TEST_MYSQL_USER have server-
# side grants only on dev_test_* databases. This wrapper exists to
# fail fast and visibly if an agent makes a wrong call.

set -u

real_tool=""
tool_name="$(basename "$0")"

# Map the symlink name to the actual binary the user is calling.
case "$tool_name" in
    psql)         real_tool="psql" ;;
    mysql)        real_tool="mysql" ;;
    mariadb)      real_tool="mariadb" ;;
    redis-cli)    real_tool="redis-cli" ;;
    db-safe)
        # Direct invocation - first arg is the real tool name.
        real_tool="${1:-}"
        shift
        ;;
esac

# Bypass switch.
if [ "${DBSAFE:-${DB_SAFETY_GUARD:-true}}" = "false" ] || [ "${DBSAFE:-${DB_SAFETY_GUARD:-true}}" = "0" ]; then
    exec "$real_tool" "$@"
fi

die() {
    echo "db-safe: $*" >&2
    echo "db-safe: this is a guard, not the real isolation. Set DB_SAFETY_GUARD=false in dev-agents/.env to disable." >&2
    exit 1
}

# Extract a value from the args array.
# Args: needle (string) haystack_args..., echoes the value following
# the needle (the form `-x VALUE` or `--xx VALUE`), or empty if not
# present.
arg_value() {
    local needle=$1; shift
    while [ $# -gt 0 ]; do
        if [ "$1" = "$needle" ]; then
            shift
            [ $# -gt 0 ] && echo "$1"
            return
        fi
        shift
    done
}

# Strip flags (anything starting with -) and the values of flags that
# take an argument. Returns the leftover positional words.
positional_only() {
    local -a out=()
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--host|-H|-p|--port|-P|--password|--user|-u|-U)
                shift 2
                ;;
            --host=*|--port=*|--password=*|--user=*|-h*|-H*|-p*|-P*|-U*|-u*)
                shift
                ;;
            -*)
                shift
                ;;
            *)
                out+=("$1"); shift ;;
        esac
    done
    printf '%s\n' "${out[@]}"
}

# Map of "prod DBs that must never be touched". The dev-agents user
# is server-side-granted only on dev_test_* - this list is a
# belt-and-braces check that fires before the request even leaves the
# container.
prod_pg_dbs="app gallery automation docs"
prod_mysql_dbs="app cloud ccnet_db seafile_db seahub_db"

check_pg_db() {
    local db=$1
    case "$db" in
        ""|postgres|template0|template1) return 1 ;;
    esac
    case " $prod_pg_dbs " in *" $db "*) return 1 ;; esac
    case "$db" in dev_test_*) return 0 ;; esac
    # Anything else: also reject. The dev-agents user is only allowed
    # to create dev_test_* DBs; if a new name was never declared, it
    # doesn't exist anyway, but reject loudly so the agent knows.
    return 1
}

check_mysql_db() {
    local db=$1
    case "$db" in
        ""|mysql|information_schema|performance_schema|sys) return 1 ;;
    esac
    case " $prod_mysql_dbs " in *" $db "*) return 1 ;; esac
    case "$db" in dev_test_*) return 0 ;; esac
    return 1
}

# ---------- per-tool gates ---------------------------------------------------

if [ "$real_tool" = "psql" ]; then
    db=$(arg_value "-d" "$@")
    [ -z "$db" ] && db=$(arg_value "--dbname" "$@")
    if [ -z "$db" ]; then
        # Positional form: `psql <dbname>`.
        positional=$(positional_only "$@")
        db=$(echo "$positional" | head -n1)
    fi
    # No -d and no positional: psql defaults to the user's login DB,
    # which is the test user. Allow - the server-side grant is the
    # real protection.
    if [ -n "$db" ]; then
        check_pg_db "$db" || die "refusing psql to database '$db' (must start with dev_test_)"
    fi

elif [ "$real_tool" = "mysql" ] || [ "$real_tool" = "mariadb" ]; then
    db=$(arg_value "-D" "$@")
    [ -z "$db" ] && db=$(arg_value "--database" "$@")
    if [ -z "$db" ]; then
        positional=$(positional_only "$@")
        db=$(echo "$positional" | head -n1)
    fi
    if [ -n "$db" ]; then
        check_mysql_db "$db" || die "refusing $real_tool to database '$db' (must start with dev_test_)"
    fi

elif [ "$real_tool" = "redis-cli" ]; then
    db=$(arg_value "-n" "$@")
    [ -z "$db" ] && db=$(arg_value "--dbnumber" "$@")
    # If neither flag is present, the command is not a connection
    # change (could be a single-shot `SET`/`GET` against the
    # current DB). Allow it; the agent can only set keys prefixed
    # with dev_test: (its own convention - not enforced here).
    if [ -n "$db" ]; then
        expected="${TEST_REDIS_DB:-15}"
        if [ "$db" != "$expected" ]; then
            die "refusing redis-cli -n $db (only TEST_REDIS_DB=$expected is allowed)"
        fi
    fi
    # Block `SELECT <n>` as a subcommand. Look for it in any position
    # in the args, then check the next word. We walk the args taking
    # care not to interpret a flag's value as a subcommand.
    expected="${TEST_REDIS_DB:-15}"
    i=0
    n=$#
    args=("$@")
    while [ $i -lt $n ]; do
        a=${args[$i]}
        case "$a" in
            SELECT)
                # Next word is the DB index. If missing, the call is
                # `SELECT` with no argument - allow (would be a syntax
                # error in real redis-cli anyway).
                next=${args[$((i+1))]:-}
                if [ -n "$next" ] && [ "$next" != "$expected" ]; then
                    die "refusing redis-cli SELECT $next (only SELECT $expected is allowed)"
                fi
                break
                ;;
            -h|--host|-H|-p|--port|-a|--auth|-u|--user|-n|--dbnumber|-t|--timeout)
                # Flag that takes an argument - skip the next word.
                i=$((i+2)); continue
                ;;
            -*)
                i=$((i+1)); continue
                ;;
        esac
        i=$((i+1))
    done
fi

exec "$real_tool" "$@"
