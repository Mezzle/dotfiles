# Check at most once a day whether the dotfiles repo has new commits. When it
# has, the next shell started after the check says so once, and the prompt shows
# an icon (starship's env_var.DOTFILES_UPDATE) until `chezmoi update` brings them
# in. The check runs in the background, so shell start-up never waits on the
# network; the foreground cost is a file stat. The stamp is touched before the
# check starts, so concurrent shells don't each run one and an offline check
# still waits a day to retry.
() {
    [[ -o interactive && -t 1 && -z "${CLAUDECODE:-}" ]] || return 0
    (( ${+commands[chezmoi]} )) || return 0

    local dir="${XDG_CACHE_HOME:-${HOME}/.cache}/dotfiles-update"
    local stamp="${dir}/checked" notice="${dir}/notice"
    # Holds the remote commit; run_after_99-clear-dotfiles-update.sh removes it
    # once a chezmoi apply brings that commit in.
    typeset -g _dotfiles_update_available="${dir}/available"

    # Exported for starship, which reads it when drawing each prompt. A stat
    # per prompt, so the icon goes as soon as the file does.
    _dotfiles_update_prompt() {
        if [[ -s "$_dotfiles_update_available" ]]; then
            export DOTFILES_UPDATE=1
        else
            unset DOTFILES_UPDATE
        fi
    }
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd _dotfiles_update_prompt

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
        if git merge-base --is-ancestor "$remote_sha" HEAD; then
            rm -f -- "$_dotfiles_update_available"
            exit
        fi
        print -r -- "$remote_sha" >| "$_dotfiles_update_available"
        print -r -- "dotfiles: updates available; run 'chezmoi update'" >| "$notice"
    ) </dev/null >/dev/null 2>&1 &!
}
