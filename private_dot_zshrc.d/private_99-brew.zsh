    alias brewup='brew update; brew upgrade; brew upgrade --cask; brew cleanup; brew doctor'
    export HOMEBREW_NO_ENV_HINTS=true
    export PATH=$(brew --prefix)/sbin:$(brew --prefix)/bin:$PATH
