#!/usr/bin/env bash
# devbox-launch.sh — Create and launch a devbox container with configurable options.
#
# Usage:
#   ./devbox-launch.sh [OPTIONS]
#
# Options:
#   -w, --workspace PATH   Workspace directory to mount (default: current directory)
#   -n, --name NAME        Container name (default: auto-generated with "devbox-" prefix)
#   -i, --image IMAGE      Docker image to use (default: ghcr.io/luongnv89/devbox:latest)
#   -p, --port PORT        Port mapping (can be specified multiple times, e.g. -p 5173:5173)
#   -e, --env KEY=VALUE    Environment variable (can be specified multiple times)
#   -d, --detach           Run container in detached mode (no attach)
#   -h, --help             Show this help message
#
# Features:
#   - Workspace mounting (user-specified or current directory)
#   - Auto-generated or custom container names (prefix: devbox-)
#   - AI agent setup mounting (~/.agents → /root/.agents)
#   - SSH agent/key forwarding for GitHub authentication
#   - Automatic container attachment after startup (unless --detach)

set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────────────────
IMAGE="ghcr.io/luongnv89/devbox:latest"
WORKSPACE=""
CONTAINER_NAME=""
DETACH=false
declare -a PORT_MAPS=()
declare -a ENV_VARS=()

# ── Helpers ───────────────────────────────────────────────────────────────────
usage() {
    sed -n '2,/^$/s/^# \?//p' "$0" | cat -n
    exit 0
}

log_info()  { echo "[devbox] ℹ $*"; }
log_warn()  { echo "[devbox] ⚠ $*" >&2; }
log_error() { echo "[devbox] ✗ $*" >&2; exit 1; }

# Generate a unique container name with the devbox- prefix
generate_name() {
    local timestamp
    timestamp="$(date +%Y%m%d-%H%M%S)"
    echo "devbox-${timestamp}"
}

# Check if docker is available
check_docker() {
    if ! command -v docker &>/dev/null; then
        log_error "docker is not installed. Please install Docker Desktop or Docker CLI."
    fi
    if ! docker info &>/dev/null; then
        log_error "Docker daemon is not running. Please start Docker Desktop or Docker Engine."
    fi
}

# ── Argument Parsing ─────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        -w|--workspace)
            WORKSPACE="$2"; shift 2 ;;
        -n|--name)
            CONTAINER_NAME="$2"; shift 2 ;;
        -i|--image)
            IMAGE="$2"; shift 2 ;;
        -p|--port)
            PORT_MAPS+=("-p" "$2"); shift 2 ;;
        -e|--env)
            ENV_VARS+=("-e" "$2"); shift 2 ;;
        -d|--detach)
            DETACH=true; shift ;;
        -h|--help)
            usage ;;
        *)
            log_error "Unknown option: $1. Use --help for usage." ;;
    esac
done

# ── Validation ────────────────────────────────────────────────────────────────
check_docker

# Default workspace to current directory if not specified
if [[ -z "$WORKSPACE" ]]; then
    WORKSPACE="$(pwd)"
fi

# Validate workspace directory exists
if [[ ! -d "$WORKSPACE" ]]; then
    log_error "Workspace directory does not exist: $WORKSPACE"
fi

# Resolve to absolute path
WORKSPACE="$(cd "$WORKSPACE" && pwd)"

# Generate container name if not provided
if [[ -z "$CONTAINER_NAME" ]]; then
    CONTAINER_NAME="$(generate_name)"
fi

# Check if container name already exists
if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    log_error "A container with name '$CONTAINER_NAME' already exists. Use --name to specify a different name, or remove the existing container."
fi

# ── Build docker run command ──────────────────────────────────────────────────
CMD=(docker run)

# Interactive and TTY for attachment
if [[ "$DETACH" == false ]]; then
    CMD+=("-it")
fi

# Container name
CMD+=("--name" "$CONTAINER_NAME")

# Workspace mount
CMD+=("-v" "${WORKSPACE}:/workspace")

# AI agent setup mount: ~/.agents → /root/.agents
if [[ -d "$HOME/.agents" ]]; then
    CMD+=("-v" "${HOME}/.agents:/root/.agents")
    log_info "Mounted ~/.agents → /root/.agents"
else
    log_warn "~/.agents not found — skipping AI agent skills mount"
fi

# SSH config mount (read-only)
if [[ -d "$HOME/.ssh" ]] && ls "$HOME/.ssh" >/dev/null 2>&1; then
    CMD+=("-v" "${HOME}/.ssh:/root/.ssh:ro")
    log_info "Mounted ~/.ssh → /root/.ssh (read-only)"
else
    log_warn "~/.ssh not found — SSH authentication not available"
fi

# SSH agent forwarding (if ssh-agent is running)
if [[ -n "${SSH_AUTH_SOCK:-}" ]]; then
    # Determine the socket path (macOS vs Linux)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: ssh-auth-sock is typically in a non-standard location
        CMD+=("-v" "${SSH_AUTH_SOCK}:/tmp/ssh-auth-sock")
        CMD+=("-e" "SSH_AUTH_SOCK=/tmp/ssh-auth-sock")
    else
        # Linux: typically in a tmp directory
        CMD+=("-v" "${SSH_AUTH_SOCK}:/tmp/ssh-auth-sock")
        CMD+=("-e" "SSH_AUTH_SOCK=/tmp/ssh-auth-sock")
    fi
    log_info "Forwarded SSH agent via $SSH_AUTH_SOCK"
else
    log_info "No SSH agent found — GitHub SSH authentication will rely on mounted keys"
fi

# OpenCode config mount
if [[ -d "$HOME/.config/opencode" ]]; then
    CMD+=("-v" "${HOME}/.config/opencode:/root/.config/opencode")
    log_info "Mounted ~/.config/opencode → /root/.config/opencode"
fi

# Pi agent config mount
if [[ -d "$HOME/.pi" ]]; then
    CMD+=("-v" "${HOME}/.pi:/root/.pi")
    log_info "Mounted ~/.pi → /root/.pi"
fi

# Port mappings
for i in "${!PORT_MAPS[@]}"; do
    CMD+=("${PORT_MAPS[$i]}")
done

# Environment variables
for i in "${!ENV_VARS[@]}"; do
    CMD+=("${ENV_VARS[$i]}")
done

# Image and command
CMD+=("$IMAGE")
if [[ "$DETACH" == false ]]; then
    CMD+=("zsh")
fi

# ── Launch ────────────────────────────────────────────────────────────────────
log_info "Container: $CONTAINER_NAME"
log_info "Image:     $IMAGE"
log_info "Workspace: $WORKSPACE"
log_info "──────────────────────────────────────"

if [[ "$DETACH" == true ]]; then
    CMD+=("-d")
    log_info "Starting in detached mode..."
    docker run -d --name "$CONTAINER_NAME" \
        -v "${WORKSPACE}:/workspace" \
        "$IMAGE" sleep infinity
    log_info "Container '$CONTAINER_NAME' started in background."
    log_info "Enter with: docker exec -it $CONTAINER_NAME zsh"
else
    log_info "Starting interactive container (press Ctrl+D or exit to stop)..."
    exec "${CMD[@]}"
fi
