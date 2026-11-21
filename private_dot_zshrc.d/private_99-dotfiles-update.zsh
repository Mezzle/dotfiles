# Check at most once a day whether the dotfiles repo has new commits, and say so
# once, in the next shell started after the check. The check runs in the
# background, so shell start-up never waits on the network; the foreground cost
# is a file stat. The stamp is touched before the check starts, so concurrent
# shells don't each run one and an offline check still waits a day to retry.
() {
    [[ -o interactive && -t 1 && -z "${CLAUDECODE:-}" ]] || return 0
    (( ${+commands[chezmoi]} )) || return 0

    local dir="${XDG_CACHE_HOME:-${HOME}/.cache}/dotfiles-update"
    local stamp="${dir}/checked" notice="${dir}/notice"

    if [[ -s "$notice" ]]; then
        print -r -- "$(<"$notice")"
        : >| "$notice"
    fi

    local fresh=( "$stamp"(N.mh-24) )
    (( ${#fresh} )) && return 0
    [[ -d "$dir" ]] || mkdir -p "$dir" || return 0
    : >| "$stamp"

    (
        cd -q "$(chezmoi source-path)" || exit
        local upstream url remote_sha
        upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}')" || exit
        url="$(git remote get-url "${upstream%%/*}")" || exit
        # Ask over anonymous HTTPS. SSH could prompt the 1Password agent from a
        # background job, so the global config (whose insteadOf rules rewrite
        # GitHub URLs to SSH) is skipped too.
        case "$url" in
            https://*) ;;
            ssh://git@*) url="https://${url#ssh://git@}" ;;
            git@*:*) url="https://${${url#git@}/://}" ;;
            *) exit ;;
        esac
        remote_sha="$(GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 \
            git -C / -c http.lowSpeedLimit=1 -c http.lowSpeedTime=15 \
            ls-remote "$url" "refs/heads/${upstream#*/}")"
        remote_sha="${remote_sha%%[[:space:]]*}"
        # No answer (offline, GitHub down): say nothing.
        [[ -n "$remote_sha" ]] || exit
        # Up to date, or the remote tip is already in local history.
        git merge-base --is-ancestor "$remote_sha" HEAD && exit
        print -r -- "dotfiles: updates available; run 'chezmoi update'" >| "$notice"
    ) </dev/null >/dev/null 2>&1 &!
}
