#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CLI="${ROOT_DIR}/scripts/docker-dev"

"${CLI}" --help | grep -q "docker-dev"

if "${CLI}" --no-interactive --image badimage -w "${ROOT_DIR}" 2>/dev/null; then
  echo "Expected failure for bad image" >&2
  exit 1
fi

echo "docker-dev CLI smoke checks passed."