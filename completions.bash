# Bash completion for manager.sh
# Usage:  source completions.bash
# Or copy to /etc/bash_completion.d/diplab

_manager_completions() {
    local cur prev
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    local commands="start stop restart update update-all build logs exec status setup perm profile backup restore clean stop-all full-cleanup help"
    local services="databases proxy monitoring passwords containers cloud docs automation gallery ai-agent dev-agents"

    # Dynamically list profile names from .profiles/ directory
    local profiles
    profiles=""
    if [ -d "$PWD/.profiles" ]; then
        profiles=$(cd "$PWD/.profiles" && echo *)
        profiles="${profiles//\// }"
    fi

    # Also complete -n / --dry-run at the start
    if [ "${#COMP_WORDS[@]}" -eq 1 ]; then
        COMPREPLY=($(compgen -W "${commands} -n --dry-run" -- "$cur"))
        return
    fi

    if [ "${#COMP_WORDS[@]}" -eq 2 ]; then
        COMPREPLY=($(compgen -W "${commands}" -- "$cur"))
        return
    fi

    if [ "${#COMP_WORDS[@]}" -eq 3 ]; then
        case "$prev" in
            start|stop|restart|update|logs|exec|build)
                COMPREPLY=($(compgen -W "${services} all" -- "$cur"))
                ;;
            update-all)
                COMPREPLY=($(compgen -W "--filter --no-recreate --no-backup --prune" -- "$cur"))
                ;;
            profile)
                COMPREPLY=($(compgen -W "list show enable disable ${profiles}" -- "$cur"))
                ;;
            restore)
                COMPREPLY=($(compgen -f -- "$cur"))
                ;;
            backup)
                COMPREPLY=($(compgen -d -- "$cur"))
                ;;
        esac
        return
    fi

    if [ "${#COMP_WORDS[@]}" -eq 4 ]; then
        if [ "${COMP_WORDS[1]}" = "update-all" ] && [ "${COMP_WORDS[2]}" = "--filter" ]; then
            COMPREPLY=($(compgen -W "${services}" -- "$cur"))
            return
        fi
        if [ "${COMP_WORDS[1]}" = "profile" ]; then
            case "$prev" in
                enable|disable)
                    COMPREPLY=($(compgen -W "${services}" -- "$cur"))
                    ;;
            esac
            return
        fi
    fi
}

complete -F _manager_completions manager.sh
