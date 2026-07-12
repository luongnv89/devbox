#!/usr/bin/env bash
# Ubuntu-version-specific Python toolchain for dev images.
set -euo pipefail

UBUNTU_VERSION="${1:-}"
if [[ -z "${UBUNTU_VERSION}" ]]; then
  echo "Usage: install-python.sh <22.04|24.04|26.04>" >&2
  exit 1
fi

case "${UBUNTU_VERSION}" in
  22.04)
    apt-get update
    apt-get install -y software-properties-common ca-certificates curl
    echo "[Python] Adding deadsnakes PPA"
    add-apt-repository ppa:deadsnakes/ppa -y
    apt-get update
    echo "[Python] Installing Python 3.12 toolchain"
    apt-get install -y python3.12 python3.12-venv
    echo "[Python] Bootstrapping pip for Python 3.12"
    curl -sS https://bootstrap.pypa.io/get-pip.py | python3.12
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1
    update-alternatives --install /usr/bin/pip3 pip3 /usr/local/bin/pip3.12 1
    ;;
  24.04|26.04)
    echo "[Python] Installing Python 3 and pip (distro default)"
    apt-get update
    apt-get install -y python3 python3-venv python3-dev python3-pip
    ;;
  *)
    echo "Unsupported UBUNTU_VERSION: ${UBUNTU_VERSION}" >&2
    exit 1
    ;;
esac

rm -rf /var/lib/apt/lists/*