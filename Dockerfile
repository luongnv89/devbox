FROM ubuntu:26.04

LABEL maintainer="luongnv89"
LABEL description="devbox — single Ubuntu 26.04 dev image (replaces u2604dev), runs root + zsh at /workspace"

ENV DEBIAN_FRONTEND=noninteractive
ENV DEV_IMAGE_NAME=devbox
ENV UBUNTU_VERSION=26.04
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV TZ=Etc/UTC
ENV SHELL=/usr/bin/zsh

# ---------- Base: apt, CLI tools, locale, Node, Corepack, uv, Oh My Zsh, Starship, Vim, fonts ----------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git git-lfs openssh-client vim wget curl zsh \
        ca-certificates gnupg lsb-release software-properties-common \
        build-essential locales unzip fontconfig btop ripgrep bat \
        jq tzdata fzf fd-find ninja-build gettext cmake curl \
        python3 python3-venv python3-dev python3-pip \
        sudo gosu && \
    # fd / bat symlinks (Ubuntu 26.04 names)
    if [ -x /usr/bin/fdfind ] && [ ! -e /usr/bin/fd ]; then ln -sf /usr/bin/fdfind /usr/bin/fd; fi && \
    ln -sf /usr/bin/batcat /usr/bin/bat 2>/dev/null || true && \
    git lfs install && \
    locale-gen en_US.UTF-8 && \
    # Node.js LTS + Corepack
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get update && apt-get install -y nodejs && \
    if command -v corepack >/dev/null 2>&1; then corepack enable; fi && \
    rm -rf /var/lib/apt/lists/*

# GitHub CLI
RUN install -d -m 0755 /etc/apt/keyrings && \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && apt-get install -y gh && rm -rf /var/lib/apt/lists/*

# Docker CLI (client only, host daemon via socket mount)
RUN apt-get update && apt-get install -y --no-install-recommends docker.io && \
    if apt-cache show docker-compose-v2 >/dev/null 2>&1; then apt-get install -y --no-install-recommends docker-compose-v2 || true; fi && \
    rm -rf /var/lib/apt/lists/* && docker --version

# uv
RUN curl -fsSL https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin UV_NO_MODIFY_PATH=1 sh && uv --version

# Oh My Zsh + plugins + Starship + vim-plug + fonts — matching host setup (wedisagree, plugins: git, docker, zsh-syntax-highlighting, zsh-autosuggestions, zsh-completions)
# Starship config and .vimrc are inlined via heredoc so the Dockerfile has no COPY dependency on legacy dirs.
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && \
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting && \
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions && \
    git clone --depth=1 https://github.com/zsh-users/zsh-completions.git /root/.oh-my-zsh/custom/plugins/zsh-completions && \
    mkdir -p /root/.config && \
    cat > /root/.config/starship.toml <<'STARSHIP_EOF'
# ===============================================
# STARSHIP - Clean Dev Prompt (Node, Python, Docker, LLM, CTF)
# ===============================================
add_newline = true
command_timeout = 1200
format = """
$hostname\
$directory\
$git_branch$git_status\
$nodejs$python\
$docker_context\
$custom_llm$custom_ctf\
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
[docker_context]
symbol = " "
format = "[$symbol$context]($style) "
style = "bold blue"
only_with_files = true
detect_files = ["Dockerfile", "docker-compose.yml", "compose.yaml"]
disabled = false
[custom.llm]
command = "echo 'LLM'"
when = "test -f .llm"
format = "[ $output]($style) "
style = "bold magenta"
shell = ["bash", "-c"]
[custom.ctf]
command = "echo 'CTF'"
when = "test -f .ctf"
format = "[ $output]($style) "
style = "bold red"
shell = ["bash", "-c"]
[time]
disabled = true
[hostname]
ssh_only = true
format = "[$hostname]($style) "
style = "dimmed"
[env_var.GIT_AUTHOR_EMAIL]
format = " [$env_value]($style) "
style = "blue"
disabled = true
[battery]
disabled = true
STARSHIP_EOF
    curl -sS https://starship.rs/install.sh | sh -s -- -y && \
    cat > /root/.vimrc <<'VIMRC_EOF'
" Basic Vim configuration with helpful defaults and plugins
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
    curl -fLo /root/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim && \
    TERM=xterm-256color vim +'PlugInstall --sync' +qa || true && \
    mkdir -p /usr/share/fonts/nerd-fonts && \
    wget -O /tmp/JetBrainsMono.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip && \
    unzip -qo /tmp/JetBrainsMono.zip -d /usr/share/fonts/nerd-fonts/ && fc-cache -fv && rm -f /tmp/JetBrainsMono.zip && \
    chsh -s "$(which zsh)" && \
    sed -i 's/^ZSH_THEME=".*"/ZSH_THEME=""/' /root/.zshrc && \
    sed -i 's/plugins=(git)/plugins=(git docker zsh-syntax-highlighting zsh-autosuggestions zsh-completions npm pip python)/' /root/.zshrc && \
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

# jq, fzf, fd, gh helpers
source /root/.shell-cli-extras.zsh

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'

# Python virtual environment helpers (stdlib venv or uv)
alias venv='python3 -m venv venv'
alias activate='source venv/bin/activate'

# Better history settings
export HISTFILE=~/.zsh_history
export HISTSIZE=10000
export SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY

# Auto-correction and completion settings
setopt CORRECT
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS

# Display a friendly welcome message on login
echo ""
echo "Welcome to the devbox container (coding-ready)!"
if command -v python3 >/dev/null 2>&1; then
  PY_VER="$(python3 --version 2>/dev/null)"
else
  PY_VER="Python: not installed"
fi
if command -v node >/dev/null 2>&1; then
  NODE_VER="Node.js $(node --version 2>/dev/null)"
else
  NODE_VER="Node.js: not installed"
fi
if command -v npm >/dev/null 2>&1; then
  NPM_VER="npm $(npm --version 2>/dev/null)"
else
  NPM_VER="npm: not installed"
fi
echo "Shell: Zsh + Starship + Oh My Zsh plugins"
echo "Editor: Vim with plugins"
if command -v opencode >/dev/null 2>&1; then echo "AI: opencode $(opencode --version 2>/dev/null | head -1)"; fi
if command -v pi >/dev/null 2>&1; then echo "AI: pi $(pi --version 2>/dev/null | head -1)"; fi
echo "$PY_VER"
if command -v uv >/dev/null 2>&1; then
  echo "uv $(uv --version 2>/dev/null | head -1) — try: uv venv && source .venv/bin/activate"
fi
echo "$NODE_VER"
echo "$NPM_VER"
if command -v corepack >/dev/null 2>&1; then
  echo "Package managers: corepack enable — pnpm install / yarn install (global npm AI CLIs unchanged)"
fi
echo ""

ZSHRC_EOF
    mkdir -p /workspace && echo "root" > /etc/docker-dev-run-as

# ---------- AI tools: preserve u2604dev's AI setup (opencode-ai at latest, pi, asm, herdr) ----------
# This layer is intentionally separate so bumps to npm@latest do not invalidate the base layer.
# Issue #49 will replace opencode-ai with @opencode-ai/cli@beta (opencode2) in a focused follow-up.
ARG DEV_IMAGE_PROFILE=ai-full
ARG AI_VERIFY_MODE=lenient
ARG AI_TOOLS_CACHEBUST=0
RUN echo "AI_TOOLS_CACHEBUST=${AI_TOOLS_CACHEBUST}" && \
    export HOME=/root && export PATH="${PATH}:/usr/local/bin" && \
    echo "[AI] Build profile: ${DEV_IMAGE_PROFILE} (verify: ${AI_VERIFY_MODE})" && \
    # Install updater script inline (no COPY from common)
    mkdir -p /usr/local/bin && \
    cat > /usr/local/bin/update-ai-tools <<'UPDATER_EOF'
#!/usr/bin/env bash
# Upgrade baked-in AI CLIs, personal tools, and skill repos to latest.
set -euo pipefail
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then exec sudo -E "$0" "$@"; fi
    echo "Error: update-ai-tools must run as root (or with sudo)" >&2; exit 1
fi
PROFILE="${DEV_IMAGE_PROFILE:-}"
if [ -z "$PROFILE" ] && [ -f /etc/docker-dev-ai-profile ]; then PROFILE="$(tr -d '[:space:]' </etc/docker-dev-ai-profile)"; fi
PROFILE="${PROFILE:-ai-full}"
case "$PROFILE" in minimal|standard|ai-full) ;; *) echo "[AI] Invalid profile '${PROFILE}'" >&2; exit 1;; esac
echo "[AI] Updating tooling (profile: ${PROFILE})"
if [ "$PROFILE" = "minimal" ]; then echo "[AI] minimal profile — no global AI npm CLIs to update."; exit 0; fi
if ! command -v npm >/dev/null 2>&1; then echo "Error: npm is not on PATH." >&2; exit 1; fi
export PATH="${PATH}:/usr/local/bin"
HOME="${HOME:-/root}"; export HOME
AI_ASM_REPOS=(github:luongnv89/idd github:luongnv89/skills)
npm_latest() { local specs=(); local pkg; for pkg in "$@"; do specs+=("${pkg}@latest"); done; echo "[AI] npm install -g ${specs[*]}"; npm install -g "${specs[@]}"; }
link_pi_skills() { local src="${HOME}/.agents/skills" dest="${HOME}/.pi/skills"; if [ ! -d "$src" ]; then return 0; fi; mkdir -p "$dest"; local skill; for skill in "$src"/*; do [ -d "$skill" ] || continue; ln -sfn "$skill" "${dest}/$(basename "$skill")"; done; echo "[AI] Linked skills into ${dest}"; }
install_asm_skills() { if ! command -v asm >/dev/null 2>&1; then echo "[AI] Warning: asm not on PATH — skipping skill update" >&2; return 0; fi
    local repo; for repo in "${AI_ASM_REPOS[@]}"; do echo "[AI] asm install ${repo} --all -p agents -s global"; asm install "$repo" --all -p agents -s global -y --force || echo "[AI] Warning: asm install ${repo} failed (non-fatal)" >&2; done
    if [ ! -d "${HOME}/.agents/skills" ]; then return 0; fi
    local tool; for tool in "$@"; do if [ "$tool" = pi ]; then link_pi_skills; continue; fi; echo "[AI] asm link ${HOME}/.agents/skills → ${tool}"; asm link "${HOME}/.agents/skills" -p "$tool" -f || echo "[AI] Warning: asm link to ${tool} failed (non-fatal)" >&2; done; }
if [ "$PROFILE" = "standard" ]; then npm_latest opencode-ai @mariozechner/pi-coding-agent agent-skill-manager; if command -v pi >/dev/null 2>&1; then pi install npm:opencode-pi npm:statusline-pi || echo "[AI] Warning: pi install npm extensions failed (non-fatal)" >&2; fi; install_asm_skills opencode pi; elif [ "$PROFILE" = "ai-full" ]; then npm_latest @anthropic-ai/claude-code @openai/codex opencode-ai @mariozechner/pi-coding-agent agent-skill-manager; if command -v pi >/dev/null 2>&1; then pi install npm:opencode-pi npm:statusline-pi || echo "[AI] Warning: pi install npm extensions failed (non-fatal)" >&2; fi; echo "[AI] Installing luongnv89/pi-extensions..."; curl -fsSL https://raw.githubusercontent.com/luongnv89/pi-extensions/main/install.sh | bash -s -- --auto || true; echo "[AI] Installing herdr..."; curl -fsSL https://herdr.dev/install.sh | HERDR_INSTALL_DIR=/usr/local/bin bash || echo "[AI] Warning: herdr install failed (non-fatal)" >&2; install_asm_skills claude opencode pi codex; fi
for tool in opencode pi asm; do if ! command -v "$tool" >/dev/null 2>&1; then echo "[AI] Missing expected command: $tool" >&2; exit 1; fi; done
for optional_cmd in claude codex; do if ! command -v "$optional_cmd" >/dev/null 2>&1; then msg="[AI] ${optional_cmd} CLI not on PATH after global npm install"; if [ "$AI_VERIFY_MODE" = "strict" ] || [ "$PROFILE" = "ai-full" ] && [ "$AI_VERIFY_MODE" = "strict" ]; then echo "${msg} (strict verify — failing build)" >&2; exit 1; fi; echo "[AI] Note: ${optional_cmd} CLI not on PATH (lenient — mount ~/.${optional_cmd} at runtime or use npx)"; fi; done
echo "[AI] Tooling install complete (${PROFILE})."
UPDATER_EOF
    chmod 0755 /usr/local/bin/update-ai-tools && \
    printf '%s\n' "${DEV_IMAGE_PROFILE}" > /etc/docker-dev-ai-profile && \
    # npm latest installs for parity with u2604dev (preserved opencode-ai; Issue #49 replaces with beta)
    if [ "${DEV_IMAGE_PROFILE}" = "minimal" ]; then \
        echo "[AI] minimal profile — skipping global AI npm CLIs"; \
    elif [ "${DEV_IMAGE_PROFILE}" = "standard" ]; then \
        echo "[AI] npm install -g opencode-ai @mariozechner/pi-coding-agent agent-skill-manager@latest" && \
        npm install -g opencode-ai@latest @mariozechner/pi-coding-agent@latest agent-skill-manager@latest && \
        if command -v pi >/dev/null 2>&1; then pi install npm:opencode-pi npm:statusline-pi || echo "[AI] Warning: pi install npm extensions failed (non-fatal)" >&2; fi && \
        if command -v asm >/dev/null 2>&1; then \
            for repo in github:luongnv89/idd github:luongnv89/skills; do asm install "$repo" --all -p agents -s global -y --force || echo "[AI] Warning: asm install $repo failed (non-fatal)" >&2; done; \
            if [ -d /root/.agents/skills ]; then \
                for tool in opencode pi; do \
                    if [ "$tool" = pi ]; then mkdir -p /root/.pi/skills; for s in /root/.agents/skills/*; do [ -d "$s" ] || continue; ln -sfn "$s" "/root/.pi/skills/$(basename "$s")"; done; echo "[AI] Linked skills into /root/.pi/skills"; continue; fi; \
                    asm link /root/.agents/skills -p "$tool" -f || echo "[AI] Warning: asm link to $tool failed (non-fatal)" >&2; \
                done; \
            fi; \
        fi && \
        for cmd in git vim zsh starship node npm python3 opencode pi asm; do if ! command -v "$cmd" >/dev/null 2>&1; then echo "[AI] Missing expected command: $cmd" >&2; exit 1; fi; done; \
    else \
        echo "[AI] npm install -g @anthropic-ai/claude-code @openai/codex opencode-ai @mariozechner/pi-coding-agent agent-skill-manager@latest" && \
        npm install -g @anthropic-ai/claude-code@latest @openai/codex@latest opencode-ai@latest @mariozechner/pi-coding-agent@latest agent-skill-manager@latest && \
        if command -v pi >/dev/null 2>&1; then pi install npm:opencode-pi npm:statusline-pi || echo "[AI] Warning: pi install npm extensions failed (non-fatal)" >&2; fi && \
        echo "[AI] Installing luongnv89/pi-extensions..."; curl -fsSL https://raw.githubusercontent.com/luongnv89/pi-extensions/main/install.sh | bash -s -- --auto || true && \
        echo "[AI] Installing herdr..."; curl -fsSL https://herdr.dev/install.sh | HERDR_INSTALL_DIR=/usr/local/bin bash || echo "[AI] Warning: herdr install failed (non-fatal)" >&2 && \
        if command -v asm >/dev/null 2>&1; then \
            for repo in github:luongnv89/idd github:luongnv89/skills; do asm install "$repo" --all -p agents -s global -y --force || echo "[AI] Warning: asm install $repo failed (non-fatal)" >&2; done; \
            if [ -d /root/.agents/skills ]; then \
                for tool in claude opencode pi codex; do \
                    if [ "$tool" = pi ]; then mkdir -p /root/.pi/skills; for s in /root/.agents/skills/*; do [ -d "$s" ] || continue; ln -sfn "$s" "/root/.pi/skills/$(basename "$s")"; done; echo "[AI] Linked skills into /root/.pi/skills"; continue; fi; \
                    asm link /root/.agents/skills -p "$tool" -f || echo "[AI] Warning: asm link to $tool failed (non-fatal)" >&2; \
                done; \
            fi; \
        fi && \
        for cmd in git vim zsh starship node npm python3 opencode pi asm; do if ! command -v "$cmd" >/dev/null 2>&1; then echo "[AI] Missing expected command: $cmd" >&2; exit 1; fi; done; \
        for optional_cmd in claude codex; do if ! command -v "$optional_cmd" >/dev/null 2>&1; then msg="[AI] ${optional_cmd} CLI not on PATH after global npm install"; if [ "${AI_VERIFY_MODE}" = "strict" ]; then echo "${msg} (strict verify — failing build)" >&2; exit 1; fi; echo "[AI] Note: ${optional_cmd} CLI not on PATH (lenient — mount ~/.${optional_cmd} at runtime or use npx)"; fi; done; \
    fi && \
    echo "[AI] Tooling install complete (${DEV_IMAGE_PROFILE})."

# ---------- Entrypoint (no COPY) ----------
RUN cat > /entrypoint.sh <<'ENTRYPOINT_EOF'
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
    "${HOME_DIR}/.codex:Codex config" \
    "${HOME_DIR}/.claude:Claude Code config" \
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
    echo "[dev] AI CLIs: run update-ai-tools to upgrade OpenCode/Claude/Codex/Pi to latest (stops in-app update nags)."
fi
if [ "$(id -u)" -eq 0 ] && [ "$RUN_AS" = "dev" ] && id -u dev >/dev/null 2>&1; then
    exec gosu dev "$@"
fi
exec "$@"
ENTRYPOINT_EOF
    chmod +x /entrypoint.sh

WORKDIR /workspace
ENTRYPOINT ["/entrypoint.sh"]
CMD ["zsh"]
