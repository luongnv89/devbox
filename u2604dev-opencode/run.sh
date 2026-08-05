#!/bin/zsh
# Helper script to run u2604dev-opencode container
# Edit the paths below to customize

# ============== CONFIG ==============
# Customize these paths as needed:
WORKSPACE="${WORKSPACE:-$HOME/workspace}"
SSH_PATH="${SSH_PATH:-$HOME/.ssh}"
OPENCODE_CONFIG="${OPENCODE_CONFIG:-$HOME/.config/opencode}"

# Image name (u2604dev-opencode variant deprecated — use u2604dev)
IMAGE="u2604dev:latest"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# ===================================

# Build image if needed (repo root context for common/ scripts)
echo "[cdev] Building u2604dev if needed..."
docker build -t "$IMAGE" -f "${REPO_ROOT}/u2604dev/Dockerfile" "${REPO_ROOT}" 2>/dev/null || true

# Build volume arguments
VOLUMES=""

# Workspace
if [ -d "$WORKSPACE" ]; then
    VOLUMES="$VOLUMES -v $WORKSPACE:/workspace"
else
    echo "[OpenCode] Warning: Workspace not found at $WORKSPACE, creating..."
    mkdir -p "$WORKSPACE"
    VOLUMES="$VOLUMES -v $WORKSPACE:/workspace"
fi

# SSH (optional)
if [ -d "$SSH_PATH" ] && [ "$(ls -A "$SSH_PATH" 2>/dev/null)" ]; then
    VOLUMES="$VOLUMES -v $SSH_PATH:/root/.ssh:ro"
    echo "[OpenCode] Including SSH from $SSH_PATH"
else
    echo "[OpenCode] SSH not found at $SSH_PATH (optional, skipping)"
fi

# opencode config (optional) — mount host config read-only, then copy into a
# writable named volume at startup. This keeps usage tracking isolated from the
# host while giving the container your full config.
if [ -d "$OPENCODE_CONFIG" ] && [ "$(ls -A "$OPENCODE_CONFIG" 2>/dev/null)" ]; then
    VOLUMES="$VOLUMES -v $OPENCODE_CONFIG:/root/.config/opencode-host:ro"
    VOLUMES="$VOLUMES -v opencode-config:/root/.config/opencode"
    echo "[OpenCode] Including opencode config from $OPENCODE_CONFIG (read-only host → writable volume)"
else
    echo "[OpenCode] opencode config not found at $OPENCODE_CONFIG (optional, skipping)"
fi

# Get UID/GID for file ownership
UID=$(id -u)
GID=$(id -g)

# Run container
echo "[OpenCode] Starting container..."

# Determine if opencode config is mounted (for entrypoint override)
OPENCODE_MOUNTED=0
if [ -d "$OPENCODE_CONFIG" ] && [ "$(ls -A "$OPENCODE_CONFIG" 2>/dev/null)" ]; then
    OPENCODE_MOUNTED=1
fi

if [ "$OPENCODE_MOUNTED" -eq 1 ]; then
    # Copy host config into writable volume, then exec zsh.
    # Image must come before -c: with --entrypoint sh, a leading -c is
    # parsed as docker run --cpu-shares, not shell -c.
    exec docker run -it --rm \
        --user "$UID:$GID" \
        $VOLUMES \
        --hostname opencode-dev \
        --entrypoint sh \
        "$IMAGE" \
        -c "[ -z \"\$(ls -A /root/.config/opencode 2>/dev/null)\" ] && cp -a /root/.config/opencode-host/. /root/.config/opencode/ 2>/dev/null || true; exec zsh"
else
    exec docker run -it --rm \
        --user "$UID:$GID" \
        $VOLUMES \
        --hostname opencode-dev \
        "$IMAGE"
fi
