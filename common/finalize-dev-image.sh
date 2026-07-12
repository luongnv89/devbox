#!/usr/bin/env bash
# Final image steps: optional non-root user + workspace workdir marker.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "${SCRIPT_DIR}/setup-dev-user.sh"

mkdir -p /workspace
if [ ! -f /etc/docker-dev-run-as ]; then
  echo "root" > /etc/docker-dev-run-as
fi