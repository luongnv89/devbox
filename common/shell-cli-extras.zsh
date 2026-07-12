# shellcheck shell=bash
# Core sandbox CLI utilities (jq, fzf, fd, gh)
if [ -f /usr/share/fzf/shell/key-bindings.zsh ]; then
  # shellcheck disable=SC1091
  source /usr/share/fzf/shell/key-bindings.zsh
  # shellcheck disable=SC1091
  source /usr/share/fzf/shell/completion.zsh
fi

export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git 2>/dev/null'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git 2>/dev/null'

alias ff='fzf'
alias jj='jq'
