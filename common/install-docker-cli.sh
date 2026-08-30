#!/usr/bin/env bash
# Install Docker CLI (client only) for in-container use against a host daemon via socket mount.
# Does not install or start dockerd inside the image.
set -euo pipefail

echo "[Docker] Installing Docker CLI (client)"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends docker.io
if apt-cache show docker-compose-v2 >/dev/null 2>&1; then
    echo "[Docker] Installing docker-compose-v2 plugin"
    apt-get install -y --no-install-recommends docker-compose-v2 || true
fi
rm -rf /var/lib/apt/lists/*
docker --version
