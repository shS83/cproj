# CPROJ Bash integration. Source this from ~/.bashrc (do not execute it).
# The executable prints a directory; this function changes the calling shell.
cproj() {
    case ${1:-} in
        --help|-h|--version|-V|--list|--refresh|--add|--config)
            command cproj "$@"
            return $?
            ;;
    esac

    local destination
    destination=$(command cproj "$@") || return $?
    [[ -n $destination && -d $destination ]] || {
        printf 'CPROJ: Selected directory is unavailable.\n' >&2
        return 1
    }
    builtin cd -- "$destination" || return $?
    # History is written only if cd succeeds. Do not break navigation if
    # the state directory is temporarily unwritable.
    command cproj --record "$PWD" >/dev/null 2>&1 || true
}
