# Minimal interactive shell setup for devbox.
export PATH="/usr/local/bin:/usr/local/sbin:${HOME}/.local/bin:${PATH}"
export HISTFILE="${HOME}/.zsh_history"
export HISTSIZE=10000
export SAVEHIST=10000

setopt HIST_IGNORE_ALL_DUPS
setopt SHARE_HISTORY
setopt AUTO_CD

alias ll='ls -lah'
alias la='ls -A'
alias gs='git status'
alias gd='git diff'

PROMPT='%n@%m:%~%# '
