#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if ! command -v docker >/dev/null 2>&1; then
    echo "Docker not available; skipping container build test." >&2
    exit 0
fi

IMAGE_TAG="u2204dev:pre-commit"

echo "Building $IMAGE_TAG for verification..."
docker build -t "$IMAGE_TAG" -f "$ROOT_DIR/u2204dev/Dockerfile" "$ROOT_DIR"

echo "Docker image built successfully."

"$ROOT_DIR/scripts/tasks/test-docker-dev-cli.sh"
