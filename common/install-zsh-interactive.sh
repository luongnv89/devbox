#!/usr/bin/env bash
# Oh My Zsh + plugins + Starship, matching the maintainer host setup:
#   ZSH_THEME=wedisagree
#   plugins=(git zsh-syntax-highlighting zsh-autosuggestions zsh-completions)
#   eval "$(starship init zsh)"
# Does not copy host-only PATH blocks or secrets from ~/.zshrc.
set -euo pipefail

echo "[Zsh] Installing Oh My Zsh"
export RUNZSH=no
export CHSH=no
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

echo "[Zsh] Fetching plugins"
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git \
    /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git \
    /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone --depth=1 https://github.com/zsh-users/zsh-completions.git \
    /root/.oh-my-zsh/custom/plugins/zsh-completions

if [[ ! -f /root/.config/starship.toml ]]; then
    echo "starship.toml must be copied to /root/.config before this script" >&2
    exit 1
fi

echo "[Starship] Installing Starship prompt"
curl -sS https://starship.rs/install.sh | sh -s -- -y

echo "[Fonts] Installing JetBrainsMono Nerd Font (Starship glyphs)"
mkdir -p /usr/share/fonts/nerd-fonts
wget -O /tmp/JetBrainsMono.zip \
    https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
unzip -qo /tmp/JetBrainsMono.zip -d /usr/share/fonts/nerd-fonts/
fc-cache -fv
rm -f /tmp/JetBrainsMono.zip

echo "[Shell] Setting default shell to zsh"
chsh -s "$(command -v zsh)"

# Match host ~/.zshrc (theme + plugins). Starship then owns the visible prompt.
sed -i 's/^ZSH_THEME=".*"/ZSH_THEME="wedisagree"/' /root/.zshrc
sed -i 's/plugins=(git)/plugins=(git zsh-syntax-highlighting zsh-autosuggestions zsh-completions)/' \
    /root/.zshrc
sed -i 's/# DISABLE_AUTO_UPDATE="true"/DISABLE_AUTO_UPDATE="true"/' /root/.zshrc
sed -i 's/# ENABLE_CORRECTION="true"/ENABLE_CORRECTION="true"/' /root/.zshrc

cat >>/root/.zshrc <<'EOF'

# Starship prompt (same config as the Ubuntu images / host)
eval "$(starship init zsh)"

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
EOF
