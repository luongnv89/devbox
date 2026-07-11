FROM ubuntu:26.04

# Author / Maintainer: luongnv89
LABEL maintainer="luongnv89"

ENV DEBIAN_FRONTEND=noninteractive

# Update and install baseline CLI/dev tooling
RUN set -eux; \
    echo "[Base] Updating apt cache and installing CLI tools"; \
    apt-get update; \
    apt-get install -y \
        git vim wget curl zsh \
        ca-certificates gnupg lsb-release \
        software-properties-common \
        build-essential \
        locales \
        unzip \
        fontconfig \
        # Monitoring and utilities
        btop ripgrep bat \
        # Extra build tooling for editor/plugins
        ninja-build gettext cmake unzip curl; \
    # bat is installed as batcat in Ubuntu - create symlink for compatibility
    ln -sf /usr/bin/batcat /usr/bin/bat; \
    echo "[Base] Cleaning apt metadata"; \
    rm -rf /var/lib/apt/lists/*

# Configure UTF-8 locale for consistent tooling behavior
RUN set -eux; \
    echo "[Locale] Generating en_US.UTF-8 locale"; \
    locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Install Node.js (LTS)
RUN set -eux; \
    echo "[Node] Preparing NodeSource repository"; \
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -; \
    echo "[Node] Installing Node.js and npm"; \
    apt-get update; \
    apt-get install -y nodejs

# Install Python 3 (default in Ubuntu 26.04) and pip
RUN set -eux; \
    echo "[Python] Installing Python 3 and pip"; \
    apt-get update; \
    apt-get install -y python3 python3-venv python3-dev python3-pip

# Install Oh My Zsh for a richer shell experience
RUN set -eux; \
    echo "[Zsh] Installing Oh My Zsh"; \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install Oh My Zsh plugins
RUN set -eux; \
    echo "[Zsh] Fetching zsh plugins"; \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting; \
    git clone https://github.com/zsh-users/zsh-autosuggestions.git /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions; \
    git clone https://github.com/zsh-users/zsh-completions.git /root/.oh-my-zsh/custom/plugins/zsh-completions

# Install Starship prompt
RUN set -eux; \
    echo "[Starship] Installing Starship prompt"; \
    curl -sS https://starship.rs/install.sh | sh -s -- -y; \
    mkdir -p /root/.config

# Copy Starship configuration
COPY u2604dev/starship.toml /root/.config/starship.toml

# Configure Vim with useful plugins
COPY u2604dev/.vimrc /root/.vimrc
RUN set -eux; \
    echo "[Vim] Installing vim-plug and plugins"; \
    curl -fLo /root/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim; \
    TERM=xterm-256color vim +'PlugInstall --sync' +qa

# Install JetBrains Mono Nerd Font for improved terminal typography
RUN set -eux; \
    echo "[Fonts] Installing JetBrainsMono Nerd Font"; \
    mkdir -p /usr/share/fonts/nerd-fonts; \
    wget -O /tmp/JetBrainsMono.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip; \
    unzip /tmp/JetBrainsMono.zip -d /usr/share/fonts/nerd-fonts/; \
    fc-cache -fv; \
    rm /tmp/JetBrainsMono.zip

# Set up zsh as default shell
RUN set -eux; \
    echo "[Shell] Setting default shell to zsh"; \
    chsh -s $(which zsh)

# Configure Oh My Zsh plugins (disable default theme for Starship)
RUN sed -i 's/^ZSH_THEME=".*"/ZSH_THEME=""/' /root/.zshrc; \
    sed -i 's/plugins=(git)/plugins=(git zsh-syntax-highlighting zsh-autosuggestions zsh-completions docker kubectl npm pip python)/' /root/.zshrc

# Configure Starship and development-friendly terminal settings
RUN cat <<'EOF' >> /root/.zshrc

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

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'

# Docker aliases
alias d='docker'
alias dc='docker compose'
alias dps='docker ps'
alias di='docker images'

# Python virtual environment helpers
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
echo "Welcome to the u2604dev container (coding-ready)!"
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
echo "$NODE_VER"
echo "$NPM_VER"
echo ""

EOF

# Coding-agent CLIs and pi-extensions (luongnv89/pi-extensions)
COPY common/install-ai-tools.sh /tmp/install-ai-tools.sh
RUN chmod +x /tmp/install-ai-tools.sh && bash /tmp/install-ai-tools.sh

COPY common/entrypoint-dev.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["zsh"]
