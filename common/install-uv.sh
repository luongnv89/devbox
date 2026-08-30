#!/usr/bin/env bash
# Astral uv — user-space install under /usr/local/bin (does not replace distro python3/pip).
set -euo pipefail

UV_INSTALL_DIR="${UV_INSTALL_DIR:-/usr/local/bin}"

echo "[uv] Installing uv to ${UV_INSTALL_DIR}"
install -d -m 0755 "${UV_INSTALL_DIR}"
curl -fsSL https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="${UV_INSTALL_DIR}" UV_NO_MODIFY_PATH=1 sh

if ! command -v uv >/dev/null 2>&1; then
    echo "[uv] uv not on PATH after install" >&2
    exit 1
fi

echo "[uv] $(uv --version)"
