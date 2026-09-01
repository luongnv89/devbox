# syntax=docker/dockerfile:1
FROM ubuntu:26.04

LABEL maintainer="luongnv89"
LABEL description="devbox — single dev container for Node.js, Python and AI coding agents"

ENV DEBIAN_FRONTEND=noninteractive
ENV DEV_IMAGE_NAME=devbox
ENV UBUNTU_VERSION=26.04
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV TZ=Etc/UTC
ENV SHELL=/usr/bin/zsh
ENV PATH="/root/.local/bin:/usr/local/bin:${PATH}"

# ---------- Base: apt, CLI tools, locale, Node, Corepack, uv ----------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git git-lfs openssh-client vim wget curl zsh \
        ca-certificates gnupg lsb-release software-properties-common \
        build-essential locales unzip fontconfig btop ripgrep bat \
        jq tzdata fzf fd-find \
        python3 python3-venv python3-dev python3-pip \
        sudo gosu && \
    # fd / bat symlinks (Ubuntu names)
    if [ -x /usr/bin/fdfind ] && [ ! -e /usr/bin/fd ]; then ln -sf /usr/bin/fdfind /usr/bin/fd; fi && \
    ln -sf /usr/bin/batcat /usr/bin/bat 2>/dev/null || true && \
    git lfs install && \
    locale-gen en_US.UTF-8 && \
    # Node.js LTS + Corepack
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get update && apt-get install -y --no-install-recommends nodejs && \
    if command -v corepack >/dev/null 2>&1; then corepack enable; fi && \
    # Clean apt cache
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# GitHub CLI
RUN install -d -m 0755 /etc/apt/keyrings && \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && apt-get install -y --no-install-recommends gh && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# uv (Fast Python Package Manager)
RUN curl -fsSL https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin UV_NO_MODIFY_PATH=1 sh && uv --version

# Oh My Zsh + plugins + Starship + vim-plug + fonts
RUN <<'EOF'
set -e
# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Plugins
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone --depth=1 https://github.com/zsh-users/zsh-completions.git /root/.oh-my-zsh/custom/plugins/zsh-completions

# Starship Prompt
mkdir -p /root/.config
cat > /root/.config/starship.toml <<'STARSHIP_EOF'
add_newline = true
command_timeout = 1200
format = """
$hostname\
$directory\
$git_branch$git_status\
$nodejs$python\
$custom_llm\
$cmd_duration\
$line_break\
$character
"""
[directory]
style = "bold blue"
truncation_length = 3
truncate_to_repo = true
fish_style_pwd_dir_length = 1
read_only = " "
format = "[$path]($style) "
disabled = false
[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
vimcmd_symbol = "[❮](bold yellow)"
format = "$symbol "
[cmd_duration]
min_time = 2000
show_milliseconds = false
format = "⏱ [$duration]($style) "
style = "yellow"
[git_branch]
symbol = " "
format = "[$symbol$branch]($style) "
style = "bold purple"
[git_status]
format = '([$all_status$ahead_behind]($style)) '
style = "cyan"
conflicted = "⚔ "
ahead = "⇡${count} "
behind = "⇣${count} "
diverged = "⇕ "
untracked = "? "
modified = "✎ "
staged = "+ "
renamed = "» "
deleted = "✘ "
[nodejs]
symbol = " "
format = "[$symbol($version)](bold green) "
detect_extensions = ["js", "jsx", "ts", "tsx", "mjs", "cjs"]
detect_files = ["package.json", "vite.config.ts", "next.config.js"]
detect_folders = ["node_modules"]
[python]
symbol = " "
format = '[$symbol(${version} )(\($virtualenv\))]($style) '
style = "bold yellow"
python_binary = "python3"
[custom.llm]
command = "echo 'LLM'"
when = "test -f .llm"
format = "[ $output]($style) "
style = "bold magenta"
shell = ["bash", "-c"]
[time]
disabled = true
[hostname]
ssh_only = true
format = "[$hostname]($style) "
style = "dimmed"
[battery]
disabled = true
STARSHIP_EOF

curl -sS https://starship.rs/install.sh | sh -s -- -y

# Vim Configuration + Plugins
cat > /root/.vimrc <<'VIMRC_EOF'
set nocompatible
filetype off
call plug#begin('~/.vim/plugged')
Plug 'preservim/nerdtree'
Plug 'airblade/vim-gitgutter'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'tpope/vim-surround'
Plug 'jiangmiao/auto-pairs'
call plug#end()
filetype plugin indent on
syntax on
set background=dark
set number
set relativenumber
set cursorline
set tabstop=4
set shiftwidth=4
set expandtab
set smartindent
set clipboard=unnamedplus
set wildmenu
set ignorecase
set smartcase
set incsearch
set hlsearch
nnoremap <silent> <C-n> :NERDTreeToggle<CR>
nnoremap <silent> <leader>f :Files<CR>
let g:gitgutter_enabled = 1
VIMRC_EOF

curl -fLo /root/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
TERM=xterm-256color vim +'PlugInstall --sync' +qa || true

# JetBrainsMono Nerd Font (extract only essential regular and bold fonts to save ~100MB)
mkdir -p /usr/share/fonts/nerd-fonts
wget -O /tmp/JetBrainsMono.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
unzip -qo /tmp/JetBrainsMono.zip "*Regular.ttf" "*Bold.ttf" -d /usr/share/fonts/nerd-fonts/ || unzip -qo /tmp/JetBrainsMono.zip -d /usr/share/fonts/nerd-fonts/
fc-cache -fv && rm -f /tmp/JetBrainsMono.zip

# Default Shell setup
chsh -s "$(which zsh)"
sed -i 's/^ZSH_THEME=".*"/ZSH_THEME=""/' /root/.zshrc
sed -i 's/plugins=(git)/plugins=(git zsh-syntax-highlighting zsh-autosuggestions zsh-completions npm pip python)/' /root/.zshrc

cat > /root/.shell-cli-extras.zsh <<'EXTRAS_EOF'
# Core sandbox CLI utilities (jq, fzf, fd, gh)
if [ -f /usr/share/fzf/shell/key-bindings.zsh ]; then
  source /usr/share/fzf/shell/key-bindings.zsh
  source /usr/share/fzf/shell/completion.zsh
fi
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git 2>/dev/null'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git 2>/dev/null'
alias ff='fzf'
alias jj='jq'
EXTRAS_EOF

cat >>/root/.zshrc <<'ZSHRC_EOF'

# Initialize Starship prompt
eval "$(starship init zsh)"

# Development-friendly aliases
alias ls='ls --color=auto'
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias cat='bat --paging=never'
alias catp='bat'
alias top='btop'

# Helpers
source /root/.shell-cli-extras.zsh

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'

# Python virtual environment helpers
alias venv='python3 -m venv venv'
alias activate='source venv/bin/activate'

# History settings
export HISTFILE=~/.zsh_history
export HISTSIZE=10000
export SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY

# Autocomplete & directory navigation
setopt CORRECT
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS

# Welcome message
echo ""
echo "🚀 Welcome to devbox!"
if command -v python3 >/dev/null 2>&1; then echo "🐍 $(python3 --version)"; fi
if command -v node >/dev/null 2>&1; then echo "🟢 Node.js $(node --version)"; fi
if command -v uv >/dev/null 2>&1; then echo "⚡ uv $(uv --version 2>/dev/null | head -1)"; fi
if command -v opencode2 >/dev/null 2>&1; then echo "🤖 opencode2 $(opencode2 --version 2>/dev/null | head -1)"; fi
if command -v pi >/dev/null 2>&1; then echo "🥧 pi $(pi --version 2>/dev/null | head -1)"; fi
if command -v herdr >/dev/null 2>&1; then echo "🐑 herdr $(herdr --version 2>/dev/null | head -1)"; fi
echo ""
ZSHRC_EOF

# Strip .git folders from cloned plugin repos to save space
find /root/.oh-my-zsh /root/.vim/plugged -name ".git" -type d -prune -exec rm -rf {} +

mkdir -p /workspace && echo "root" > /etc/docker-dev-run-as
EOF

# ---------- AI Tools: opencode2, pi (+ extensions), herdr ----------
ARG AI_VERIFY_MODE=strict
ARG AI_TOOLS_CACHEBUST=0

RUN <<'EOF'
set -e
export HOME=/root
export PATH="/root/.local/bin:/usr/local/bin:${PATH}"

echo "[AI] Installing AI tools (opencode2, pi, herdr)..."

# 1. opencode2
npm install -g @opencode-ai/cli@beta

# 2. herdr
curl -fsSL https://herdr.dev/install.sh | HERDR_INSTALL_DIR=/usr/local/bin bash || echo "[AI] Warning: herdr install failed (non-fatal)" >&2

# 3. pi via official installer
curl -fsSL https://pi.dev/install.sh | sh
if [ -f /root/.local/bin/pi ] && [ ! -f /usr/local/bin/pi ]; then
    ln -sf /root/.local/bin/pi /usr/local/bin/pi
fi

# 4. pi extensions
if command -v pi >/dev/null 2>&1; then
    echo "[AI] Installing pi extensions..."
    pi install npm:opencode-pi || echo "[AI] Warning: pi opencode-pi failed (non-fatal)" >&2
    pi install npm:statusline-pi || echo "[AI] Warning: pi statusline-pi failed (non-fatal)" >&2
    pi install npm:timestamp-pi || echo "[AI] Warning: pi timestamp-pi failed (non-fatal)" >&2
    pi install npm:pi-subagents || echo "[AI] Warning: pi pi-subagents failed (non-fatal)" >&2
fi

# Verification
if [ "${AI_VERIFY_MODE}" = "strict" ]; then
    for cmd in opencode2 pi; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "[AI] Error: Missing required command '$cmd'" >&2
            exit 1
        fi
    done
fi

# Updater script
mkdir -p /usr/local/bin
cat > /usr/local/bin/update-ai-tools <<'UPDATER_EOF'
#!/usr/bin/env bash
set -euo pipefail
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then exec sudo -E "$0" "$@"; fi
    echo "Error: update-ai-tools must run as root (or with sudo)" >&2; exit 1
fi
export PATH="/root/.local/bin:/usr/local/bin:${PATH}"
echo "[AI] Updating opencode2..."
npm install -g @opencode-ai/cli@beta
echo "[AI] Updating herdr..."
curl -fsSL https://herdr.dev/install.sh | HERDR_INSTALL_DIR=/usr/local/bin bash || true
echo "[AI] Updating pi..."
curl -fsSL https://pi.dev/install.sh | sh || true
if command -v pi >/dev/null 2>&1; then
    pi install npm:opencode-pi npm:statusline-pi npm:timestamp-pi npm:pi-subagents || true
fi
echo "[AI] All AI tools updated."
UPDATER_EOF
chmod 0755 /usr/local/bin/update-ai-tools

# Clean npm cache and temporary files to keep layer lean
npm cache clean --force 2>/dev/null || true
rm -rf /root/.npm /root/.cache /tmp/* /var/tmp/*

echo "[AI] Tooling install complete."
EOF

# ---------- Entrypoint (no COPY dependency) ----------
COPY <<'ENTRYPOINT_EOF' /entrypoint.sh
#!/usr/bin/env bash
set -euo pipefail
if [ -n "${TZ:-}" ] && [ -f /usr/share/zoneinfo/"${TZ}" ]; then
    ln -snf /usr/share/zoneinfo/"${TZ}" /etc/localtime 2>/dev/null || true
fi
RUN_AS="root"
if [ -f /etc/docker-dev-run-as ]; then
    RUN_AS="$(tr -d '[:space:]' </etc/docker-dev-run-as)"
fi
home_for_run_as() {
    case "$1" in
    root) printf '%s' "/root" ;;
    dev)
        if getent passwd dev >/dev/null 2>&1; then
            getent passwd dev | cut -d: -f6
        else
            printf '%s' "/home/dev"
        fi
        ;;
    *) printf '%s' "/root" ;;
    esac
}
HOME_DIR="$(home_for_run_as "$RUN_AS")"
if [ -d "${HOME_DIR}/.ssh" ] && [ "$(ls -A "${HOME_DIR}/.ssh" 2>/dev/null)" ]; then
    chmod 700 "${HOME_DIR}/.ssh" 2>/dev/null || true
    chmod 600 "${HOME_DIR}/.ssh"/id_* 2>/dev/null || true
    chmod 644 "${HOME_DIR}/.ssh"/*.pub 2>/dev/null || true
fi
for mount_label in \
    "${HOME_DIR}/.ssh:SSH config" \
    "${HOME_DIR}/.config/opencode:OpenCode config" \
    "${HOME_DIR}/.pi:Pi agent config" \
    "${HOME_DIR}/.agents:Agent skills" \
    "/workspace:Workspace"; do
    path="${mount_label%%:*}"
    label="${mount_label#*:}"
    if [ -d "$path" ] && [ "$(ls -A "$path" 2>/dev/null | head -1)" != "" ]; then
        echo "[dev] Mounted ${label} → ${path}"
    fi
done
if command -v update-ai-tools >/dev/null 2>&1; then
    echo "[dev] AI CLIs: run update-ai-tools to upgrade opencode2/pi/herdr to latest."
fi
if [ "$(id -u)" -eq 0 ] && [ "$RUN_AS" = "dev" ] && id -u dev >/dev/null 2>&1; then
    exec gosu dev "$@"
fi
exec "$@"
ENTRYPOINT_EOF

RUN chmod +x /entrypoint.sh

WORKDIR /workspace
ENTRYPOINT ["/entrypoint.sh"]
CMD ["zsh"]
