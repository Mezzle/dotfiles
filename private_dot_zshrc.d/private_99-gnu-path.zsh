{{ if eq .chezmoi.os "darwin" -}}
export BREW_PREFIX=$(brew --prefix)
export PATH="${BREW_PREFIX}/opt/grep/libexec/gnubin:${PATH}"
export PATH="${BREW_PREFIX}/opt/gnu-which/libexec/gnubin:${PATH}"
export PATH="${BREW_PREFIX}/opt/coreutils/libexec/gnubin:${PATH}"
export MANPATH="${BREW_PREFIX}/opt/coreutils/libexec/gnuman:${MANPATH}"

alias ls="gls --color=always"
{{ end -}}
