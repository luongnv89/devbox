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
#   -D, --dry-run          Print the docker run command without executing it
#   -h, --help             Show this help message
#
# Features:
#   - Workspace mounting (user-specified or current directory)
#   - Auto-generated or custom container names (prefix: devbox-)
#   - AI skills-only mounting (~/.agents → /root/.agents)
#   - SSH config volume refreshed on every launch, host paths rewritten for the container
#   - gh CLI auth + host git identity for GitHub operations
#   - Automatic container attachment after startup (interactive runs are --rm)

set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────────────────
IMAGE="ghcr.io/luongnv89/devbox:latest"
WORKSPACE=""
CONTAINER_NAME=""
DETACH=false
declare -a PORT_MAPS=()
declare -a ENV_VARS=()
SSH_VOL="devbox-ssh-config"
DRY_RUN=false
FINAL_CMD=""
# Git identity is read from the host so commits in the container are attributed
# to whoever launched it, not a hardcoded maintainer.
GIT_USER_NAME="$(git config --global user.name 2>/dev/null || true)"
GIT_USER_EMAIL="$(git config --global user.email 2>/dev/null || true)"

# ── Helpers ───────────────────────────────────────────────────────────────────
usage() {
    sed -n '2,/^$/s/^# \?//p' "$0" | cat -n
    exit 0
}

log_info() { echo "[devbox] ℹ $*"; }
log_warn() { echo "[devbox] ⚠ $*" >&2; }
log_error() {
    echo "[devbox] ✗ $*" >&2
    exit 1
}

# Stage SSH entries without runtime sockets. Check every operation explicitly:
# callers use this in a conditional, where Bash disables implicit errexit.
stage_ssh_dir() (
    local src="$1" dst="$2" entry
    shopt -s dotglob nullglob
    [[ -r "$src" && -x "$src" ]] || return 1
    mkdir -m 700 "$dst" || return 1
    for entry in "$src"/*; do
        if [[ -L "$entry" ]]; then
            cp -a "$entry" "$dst/" || return 1
        elif [[ -S "$entry" ]]; then
            continue
        elif [[ -d "$entry" ]]; then
            stage_ssh_dir "$entry" "$dst/${entry##*/}" || return 1
        else
            cp -a "$entry" "$dst/" || return 1
        fi
    done
)

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
    -w | --workspace)
        WORKSPACE="$2"
        shift 2
        ;;
    -n | --name)
        CONTAINER_NAME="$2"
        shift 2
        ;;
    -i | --image)
        IMAGE="$2"
        shift 2
        ;;
    -p | --port)
        PORT_MAPS+=("-p" "$2")
        shift 2
        ;;
    -e | --env)
        ENV_VARS+=("-e" "$2")
        shift 2
        ;;
    -d | --detach)
        DETACH=true
        shift
        ;;
    -D | --dry-run)
        DRY_RUN=true
        shift
        ;;
    -h | --help)
        usage
        ;;
    *)
        log_error "Unknown option: $1. Use --help for usage."
        ;;
    esac
done

# ── Validation ────────────────────────────────────────────────────────────────
# Dry run only renders the command — it must not touch the Docker daemon.
if [[ "$DRY_RUN" == false ]]; then
    check_docker
fi

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

# Check if container name already exists (skipped on dry run — no daemon needed)
if [[ "$DRY_RUN" == false ]] && docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    log_error "A container with name '$CONTAINER_NAME' already exists. Use --name to specify a different name, or remove the existing container."
fi

# ── Build docker run command ─────────────────────────────────────────────────
CMD=(docker run)

# Container name
CMD+=("--name" "$CONTAINER_NAME")

# Workspace mount
CMD+=("-v" "${WORKSPACE}:/workspace")

# AI skills-only mount. Do not mount provider or agent state such as
# ~/.config/opencode or ~/.pi.
if [[ -d "$HOME/.agents" ]]; then
    CMD+=("-v" "${HOME}/.agents:/root/.agents")
    log_info "Mounted ~/.agents → /root/.agents"
else
    log_warn "$HOME/.agents not found — skipping AI agent skills mount"
fi

# SSH config mount via Docker volume
CMD+=("-v" "${SSH_VOL}:/root/.ssh")

# gh CLI auth mount
if [[ -d "$HOME/.config/gh" ]]; then
    CMD+=("-v" "${HOME}/.config/gh:/root/.config/gh")
    log_info "Mounted ~/.config/gh → /root/.config/gh"
fi

# Git identity for in-container commits (propagated via env, configured below)
if [[ -n "$GIT_USER_NAME" ]]; then
    CMD+=("-e" "DEVBOX_GIT_NAME=$GIT_USER_NAME")
fi
if [[ -n "$GIT_USER_EMAIL" ]]; then
    CMD+=("-e" "DEVBOX_GIT_EMAIL=$GIT_USER_EMAIL")
fi

# Port mappings (stored as "-p" "spec" pairs — append verbatim)
for i in "${!PORT_MAPS[@]}"; do
    CMD+=("${PORT_MAPS[$i]}")
done

# Environment variables (stored as "-e" "KEY=VALUE" pairs — append verbatim)
for i in "${!ENV_VARS[@]}"; do
    CMD+=("${ENV_VARS[$i]}")
done

# Mode flags must precede the image name: detached keeps the container alive via
# `sleep infinity`; interactive gets a TTY when launched from a terminal and is
# removed on exit.
CMD+=("--entrypoint" "zsh")
if [[ "$DETACH" == true ]]; then
    CMD+=("-d")
    FINAL_CMD="sleep infinity"
else
    if [[ -t 0 && -t 1 ]]; then
        CMD+=("-it")
    else
        log_warn "No TTY detected — interactive shell will exit immediately. Use -d/--detach for a background container."
    fi
    CMD+=("--rm")
    FINAL_CMD="zsh"
fi
CMD+=("$IMAGE")

# Inline init: fix SSH permissions (NULL_GLOB makes missing key types a no-op
# instead of zsh "no matches found" errors), apply host git identity, setup gh.
CMD+=(-c '
    setopt NULL_GLOB
    chown -R root:root /root/.ssh
    chmod 700 /root/.ssh
    chmod 600 /root/.ssh/config /root/.ssh/config.bak 2>/dev/null || true
    chmod 600 /root/.ssh/id_* 2>/dev/null || true
    chmod 644 /root/.ssh/*.pub 2>/dev/null || true
    chmod 644 /root/.ssh/known_hosts /root/.ssh/known_hosts.old 2>/dev/null || true
    chmod 644 /root/.ssh/authorized_keys 2>/dev/null || true
    if [ -n "${DEVBOX_GIT_NAME:-}" ]; then git config --global user.name "$DEVBOX_GIT_NAME"; fi
    if [ -n "${DEVBOX_GIT_EMAIL:-}" ]; then git config --global user.email "$DEVBOX_GIT_EMAIL"; fi
    git config --global init.defaultBranch main
    gh auth setup-git 2>/dev/null
    exec '"$FINAL_CMD"'
')

# ── Dry run: render the command, no side effects ──────────────────────────────
if [[ "$DRY_RUN" == true ]]; then
    log_info "Container: $CONTAINER_NAME"
    log_info "Image:     $IMAGE"
    log_info "Workspace: $WORKSPACE"
    log_info "Would execute:"
    printf ' %q' "${CMD[@]}"
    echo ""
    exit 0
fi

# ── Prepare SSH volume (rewrites host paths for container) ───────────────────
# Refreshed on every launch so new keys/config on the host reach the container.
if [[ -d "$HOME/.ssh" ]]; then
    if ! docker volume inspect "$SSH_VOL" >/dev/null 2>&1; then
        docker volume create "$SSH_VOL" >/dev/null
    fi
    SSH_TMP=$(mktemp -d)
    trap 'rm -rf "$SSH_TMP"' EXIT
    if ! stage_ssh_dir "$HOME/.ssh" "$SSH_TMP/.ssh"; then
        log_error "SSH staging failed — existing SSH volume left unchanged."
    fi
    # Rewrite host paths to container paths. `sed -i.bak` is the portable form —
    # plain `sed -i` fails on BSD/macOS sed (it eats `-e` as the backup suffix).
    if [[ -f "$SSH_TMP/.ssh/config" ]]; then
        sed -i.bak \
            -e "s|${HOME}/.ssh/|/root/.ssh/|g" \
            -e 's|/home/${USER}/.ssh/|/root/.ssh/|g' \
            -e 's|/Users/${USER}/.ssh/|/root/.ssh/|g' \
            -e "s|${HOME}/|/root/|g" \
            "$SSH_TMP/.ssh/config"
        rm -f "$SSH_TMP/.ssh/config.bak"
    fi
    # One daemon reserves this volume-derived name before executing the helper;
    # contenders fail fast. If stale, inspect it manually before removal/retry.
    docker run --rm --name "${SSH_VOL}-refresh" \
        -v "$SSH_TMP/.ssh:/src:ro" \
        -v "$SSH_VOL:/dst" \
        alpine:latest \
        sh -c '
            set -eu
            src=$1 dst=$2
            umask 077
            staged=$(mktemp -d "$dst/.devbox-ssh-refresh.XXXXXX")
            trap '\''rm -rf "$staged"'\'' EXIT
            # Complete the copy on the volume before removing any existing keys.
            cp -a "$src/." "$staged/"
            for entry in "$dst"/* "$dst"/.[!.]* "$dst"/..?*; do
                [ "$entry" = "$staged" ] && continue
                rm -rf "$entry"
            done
            for entry in "$staged"/* "$staged"/.[!.]* "$staged"/..?*; do
                [ -e "$entry" ] || [ -L "$entry" ] || continue
                mv "$entry" "$dst/"
            done
        ' sh /src /dst
    rm -rf "$SSH_TMP"
    trap - EXIT
    log_info "Refreshed ~/.ssh → /root/.ssh (volume: $SSH_VOL)"
else
    log_warn "$HOME/.ssh not found — SSH authentication not available"
fi

# ── Launch ────────────────────────────────────────────────────────────────────
log_info "Container: $CONTAINER_NAME"
log_info "Image:     $IMAGE"
log_info "Workspace: $WORKSPACE"
log_info "──────────────────────────────────────"

if [[ "$DETACH" == true ]]; then
    log_info "Starting in detached mode..."
    "${CMD[@]}"
    log_info "Container '$CONTAINER_NAME' started in background."
    log_info "Enter with: docker exec -it $CONTAINER_NAME zsh"
else
    log_info "Starting interactive container (press Ctrl+D or exit to stop)..."
    exec "${CMD[@]}"
fi
