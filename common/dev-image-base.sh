#!/usr/bin/env bash
# Shared dev-image build steps for u2204dev, u2404dev, u2604dev.
# Expects: DEV_IMAGE_NAME, UBUNTU_VERSION; starship.toml and .vimrc already in place.
set -euo pipefail

DEV_IMAGE_NAME="${DEV_IMAGE_NAME:-}"
UBUNTU_VERSION="${UBUNTU_VERSION:-}"

if [[ -z "${DEV_IMAGE_NAME}" || -z "${UBUNTU_VERSION}" ]]; then
  echo "DEV_IMAGE_NAME and UBUNTU_VERSION must be set" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[Base] Updating apt cache and installing CLI tools"
apt-get update
apt-get install -y \
  git git-lfs openssh-client vim wget curl zsh \
  ca-certificates gnupg lsb-release \
  software-properties-common \
  build-essential \
  locales \
  unzip \
  fontconfig \
  btop ripgrep bat \
  jq tzdata fzf fd-find \
  ninja-build gettext cmake unzip curl

case "${UBUNTU_VERSION}" in
  22.04)
    if [[ -x /usr/bin/fdfind ]] && [[ ! -e /usr/bin/fd ]]; then
      ln -sf /usr/bin/fdfind /usr/bin/fd
    fi
    ;;
  24.04)
    ln -sf /usr/bin/batcat /usr/bin/bat
    ln -sf /usr/bin/rg /usr/bin/ripgrep
    if [[ -x /usr/bin/fdfind ]] && [[ ! -e /usr/bin/fd ]]; then
      ln -sf /usr/bin/fdfind /usr/bin/fd
    fi
    ;;
  26.04)
    ln -sf /usr/bin/batcat /usr/bin/bat
    if [[ -x /usr/bin/fdfind ]] && [[ ! -e /usr/bin/fd ]]; then
      ln -sf /usr/bin/fdfind /usr/bin/fd
    fi
    ;;
  *)
    echo "Unsupported UBUNTU_VERSION: ${UBUNTU_VERSION}" >&2
    exit 1
    ;;
esac

echo "[Base] Cleaning apt metadata"
rm -rf /var/lib/apt/lists/*

bash "${SCRIPT_DIR}/install-gh-cli.sh"
bash "${SCRIPT_DIR}/install-docker-cli.sh"

echo "[Git LFS] Running git lfs install"
git lfs install

echo "[Locale] Generating en_US.UTF-8 locale"
locale-gen en_US.UTF-8

echo "[Node] Preparing NodeSource repository"
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
echo "[Node] Installing Node.js and npm"
apt-get update
apt-get install -y nodejs
rm -rf /var/lib/apt/lists/*

echo "[Zsh] Installing Oh My Zsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

echo "[Zsh] Fetching zsh plugins"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
  /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions.git \
  /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-completions.git \
  /root/.oh-my-zsh/custom/plugins/zsh-completions

echo "[Starship] Installing Starship prompt"
curl -sS https://starship.rs/install.sh | sh -s -- -y
mkdir -p /root/.config

echo "[Vim] Installing vim-plug and plugins"
curl -fLo /root/.vim/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
TERM=xterm-256color vim +'PlugInstall --sync' +qa

echo "[Fonts] Installing JetBrainsMono Nerd Font"
mkdir -p /usr/share/fonts/nerd-fonts
wget -O /tmp/JetBrainsMono.zip \
  https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
unzip /tmp/JetBrainsMono.zip -d /usr/share/fonts/nerd-fonts/
fc-cache -fv
rm /tmp/JetBrainsMono.zip

echo "[Shell] Setting default shell to zsh"
chsh -s "$(which zsh)"

sed -i 's/^ZSH_THEME=".*"/ZSH_THEME=""/' /root/.zshrc
sed -i 's/plugins=(git)/plugins=(git docker zsh-syntax-highlighting zsh-autosuggestions zsh-completions npm pip python)/' \
  /root/.zshrc

cp "${SCRIPT_DIR}/shell-cli-extras.zsh" /root/.shell-cli-extras.zsh

cat >> /root/.zshrc <<EOF

# Initialize Starship prompt
eval "\$(starship init zsh)"

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
echo "Welcome to the ${DEV_IMAGE_NAME} container (coding-ready)!"
if command -v python3 >/dev/null 2>&1; then
  PY_VER="\$(python3 --version 2>/dev/null)"
else
  PY_VER="Python: not installed"
fi
if command -v node >/dev/null 2>&1; then
  NODE_VER="Node.js \$(node --version 2>/dev/null)"
else
  NODE_VER="Node.js: not installed"
fi
if command -v npm >/dev/null 2>&1; then
  NPM_VER="npm \$(npm --version 2>/dev/null)"
else
  NPM_VER="npm: not installed"
fi
echo "Shell: Zsh + Starship + Oh My Zsh plugins"
echo "Editor: Vim with plugins"
if command -v opencode >/dev/null 2>&1; then echo "AI: opencode \$(opencode --version 2>/dev/null | head -1)"; fi
if command -v pi >/dev/null 2>&1; then echo "AI: pi \$(pi --version 2>/dev/null | head -1)"; fi
echo "\$PY_VER"
echo "\$NODE_VER"
echo "\$NPM_VER"
echo ""

EOF

DEV_IMAGE_PROFILE="${DEV_IMAGE_PROFILE:-ai-full}" bash "${SCRIPT_DIR}/install-ai-tools.sh"