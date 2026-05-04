#!/bin/zsh
# Helper script to run u2604dev-opencode container
# Edit the paths below to customize

# ============== CONFIG ==============
# Customize these paths as needed:
WORKSPACE="${WORKSPACE:-$HOME/workspace}"
SSH_PATH="${SSH_PATH:-$HOME/.ssh}"
OPENCODE_CONFIG="${OPENCODE_CONFIG:-$HOME/.config/opencode}"

# Image name
IMAGE="u2604dev-opencode:latest"

# ===================================

# Build image if needed
echo "[OpenCode] Building image if needed..."
docker build -t "$IMAGE" "$(dirname "$0")" 2>/dev/null || true

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

# opencode config (optional)
if [ -d "$OPENCODE_CONFIG" ] && [ "$(ls -A "$OPENCODE_CONFIG" 2>/dev/null)" ]; then
    VOLUMES="$VOLUMES -v $OPENCODE_CONFIG:/root/.config/opencode"
    echo "[OpenCode] Including opencode config from $OPENCODE_CONFIG"
else
    echo "[OpenCode] opencode config not found at $OPENCODE_CONFIG (optional, skipping)"
fi

# Get UID/GID for file ownership
UID=$(id -u)
GID=$(id -g)

# Run container
echo "[OpenCode] Starting container..."
exec docker run -it --rm \
    --user "$UID:$GID" \
    $VOLUMES \
    --hostname opencode-dev \
    "$IMAGE"