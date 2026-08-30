#!/usr/bin/env bash
# Lean Debian base for the devbox OpenCode image.
set -euo pipefail

export DEBIAN_FRONTEND="${DEBIAN_FRONTEND:-noninteractive}"

printf '%s\n' "[devbox] Installing development tools"
apt-get update
apt-get install -y --no-install-recommends \
    bash \
    build-essential \
    ca-certificates \
    coreutils \
    curl \
    fd-find \
    git \
    git-lfs \
    jq \
    less \
    pkg-config \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    ripgrep \
    tzdata \
    unzip \
    vim-tiny \
    zsh

echo "[devbox] Installing Node.js LTS"
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt-get update
apt-get install -y --no-install-recommends nodejs

# Debian names these commands fdfind and vi. Provide the conventional names
# expected by development tools without installing larger metapackages.
if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
    ln -s /usr/bin/fdfind /usr/local/bin/fd
fi

mkdir -p /workspace /root/.config/opencode

git lfs install

rm -rf /var/lib/apt/lists/*
