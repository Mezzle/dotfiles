#!/bin/sh
# Clear the prompt's dotfiles-update icon, and any notice not yet shown, once
# the commit the daily check saw (see ~/.zshrc.d/99-dotfiles-update.zsh) is in
# the source repo. Runs after every apply, including `chezmoi update`; it only
# reads local git state.
dir="${XDG_CACHE_HOME:-${HOME}/.cache}/dotfiles-update"
flag="${dir}/available"
[ -s "$flag" ] || exit 0
if git -C "$CHEZMOI_SOURCE_DIR" merge-base --is-ancestor "$(cat "$flag")" HEAD 2>/dev/null; then
    rm -f "$flag" "${dir}/notice"
fi
