# syntax=docker/dockerfile:1
FROM ubuntu:26.04

LABEL maintainer="luongnv89"
LABEL description="devbox — single dev container for Node.js, Python and AI coding agents"

# Build-time only: does not leak into the running container's environment.
ARG DEBIAN_FRONTEND=noninteractive

ENV DEV_IMAGE_NAME=devbox \
    UBUNTU_VERSION=26.04 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    TZ=Etc/UTC \
    SHELL=/usr/bin/zsh \
    PIP_BREAK_SYSTEM_PACKAGES=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PATH="/root/.local/bin:/usr/local/bin:${PATH}"

# ---------- Base: apt, CLI tools, locale, Node, Corepack, GitHub CLI ----------
# Single layer: one apt index fetch for the distro packages, NodeSource and gh.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git git-lfs openssh-client vim wget curl zsh \
        ca-certificates gnupg \
        build-essential locales unzip btop ripgrep bat \
        jq tzdata fzf fd-find \
        python3 python3-venv python3-dev python3-pip \
        sudo gosu && \
    # fd / bat symlinks (Ubuntu renames both binaries)
    if [ -x /usr/bin/fdfind ] && [ ! -e /usr/bin/fd ]; then ln -sf /usr/bin/fdfind /usr/bin/fd; fi && \
    ln -sf /usr/bin/batcat /usr/bin/bat 2>/dev/null || true && \
    git lfs install && \
    # Bind-mounted repos are owned by the host UID; without this every git
    # command in /workspace fails with "detected dubious ownership".
    git config --global --add safe.directory '*' && \
    locale-gen en_US.UTF-8 && \
    # Node.js LTS + Corepack (pnpm/yarn)
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    # GitHub CLI apt repository
    install -d -m 0755 /etc/apt/keyrings && \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends nodejs gh && \
    if command -v corepack >/dev/null 2>&1; then corepack enable; fi && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# uv (fast Python package manager)
RUN curl -fsSL https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin UV_NO_MODIFY_PATH=1 sh && uv --version

# ---------- Shell: Oh My Zsh + plugins, vim + vim-plug ----------
RUN <<'EOF'
set -e
# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Plugins
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone --depth=1 https://github.com/zsh-users/zsh-completions.git /root/.oh-my-zsh/custom/plugins/zsh-completions

# Vim Configuration + Plugins
cat > /root/.vimrc <<'VIMRC_EOF'
set nocompatible
filetype off
call plug#begin('~/.vim/plugged')
Plug 'preservim/nerdtree'
Plug 'airblade/vim-gitgutter'
Plug 'junegunn/fzf'
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
# Fail the build if plugin installation produced nothing usable.
[ -d /root/.vim/plugged/nerdtree ] || { echo "[shell] Error: vim plugin install failed" >&2; exit 1; }

# Default shell setup. zsh-syntax-highlighting must be sourced LAST (upstream
# requirement) or it silently fails to highlight.
chsh -s "$(which zsh)"
sed -i 's/plugins=(git)/plugins=(git npm pip python zsh-autosuggestions zsh-completions zsh-syntax-highlighting)/' /root/.zshrc

cat > /root/.shell-cli-extras.zsh <<'EXTRAS_EOF'
# Core sandbox CLI utilities (jq, fzf, fd, gh)
# fzf >= 0.48 ships its own shell integration; Debian/Ubuntu keeps the legacy
# snippets under /usr/share/doc/fzf/examples (NOT /usr/share/fzf/shell).
if command -v fzf >/dev/null 2>&1 && fzf --zsh >/dev/null 2>&1; then
  eval "$(fzf --zsh)"
elif [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
  source /usr/share/doc/fzf/examples/key-bindings.zsh
  [ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh
fi
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git 2>/dev/null'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git 2>/dev/null'
EXTRAS_EOF

cat >>/root/.zshrc <<'ZSHRC_EOF'

# fzf / fd / jq integration
source /root/.shell-cli-extras.zsh

# History settings
export HISTFILE=~/.zsh_history
export HISTSIZE=10000
export SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY

# Autocomplete & directory navigation
setopt CORRECT
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS

# Welcome message (versions are baked at build time — see devbox-genmotd).
# Only on a real terminal: `docker exec my-dev zsh -ic "cat file"` must not get
# a banner prepended to its stdout.
if [ -t 1 ] && [ -f /etc/devbox-motd ]; then
    cat /etc/devbox-motd
fi
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

echo "[AI] Installing AI tools (cachebust=${AI_TOOLS_CACHEBUST})..."

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

mkdir -p /usr/local/bin

# MOTD generator: resolves tool versions ONCE at build time so interactive
# shells do not pay ~550ms of subprocess spawns on every startup.
cat > /usr/local/bin/devbox-genmotd <<'MOTD_EOF'
#!/usr/bin/env bash
# Regenerate /etc/devbox-motd with the currently installed tool versions.
export PATH="/root/.local/bin:/usr/local/bin:${PATH}"
{
    echo ""
    echo "🚀 Welcome to devbox!"
    command -v python3   >/dev/null 2>&1 && echo "🐍 $(python3 --version)"
    command -v node      >/dev/null 2>&1 && echo "🟢 Node.js $(node --version)"
    # These three already print their own name, so do not prefix it again.
    command -v uv        >/dev/null 2>&1 && echo "⚡ $(uv --version 2>/dev/null | head -1)"
    command -v opencode2 >/dev/null 2>&1 && echo "🤖 $(opencode2 --version 2>/dev/null | head -1)"
    command -v herdr     >/dev/null 2>&1 && echo "🐑 $(herdr --version 2>/dev/null | head -1)"
    command -v pi        >/dev/null 2>&1 && echo "🥧 pi $(pi --version 2>/dev/null | head -1)"
    echo ""
} > /etc/devbox-motd
MOTD_EOF
chmod 0755 /usr/local/bin/devbox-genmotd
/usr/local/bin/devbox-genmotd

# Updater script
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
# Keep the login banner in sync with the freshly installed versions.
command -v devbox-genmotd >/dev/null 2>&1 && devbox-genmotd
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
# Diagnostics go to stderr and only when attached to a terminal, so that
# `docker run devbox cat file > out` and piped `docker exec` stay clean.
if [ -t 1 ] || [ -t 2 ]; then
    for mount_label in \
        "${HOME_DIR}/.ssh:SSH config" \
        "${HOME_DIR}/.config/opencode:OpenCode config" \
        "${HOME_DIR}/.pi:Pi agent config" \
        "${HOME_DIR}/.agents:Agent skills" \
        "/workspace:Workspace"; do
        path="${mount_label%%:*}"
        label="${mount_label#*:}"
        if [ -d "$path" ] && [ "$(ls -A "$path" 2>/dev/null | head -1)" != "" ]; then
            echo "[dev] Mounted ${label} → ${path}" >&2
        fi
    done
    if command -v update-ai-tools >/dev/null 2>&1; then
        echo "[dev] AI CLIs: run update-ai-tools to upgrade opencode2/pi/herdr to latest." >&2
    fi
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
