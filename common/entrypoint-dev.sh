#!/usr/bin/env bash
# Optional volume hygiene for dev containers.
set -euo pipefail

# Default TZ is Etc/UTC (set in Dockerfile). Honor runtime override.
if [ -n "${TZ:-}" ] && [ -f /usr/share/zoneinfo/"${TZ}" ]; then
    ln -snf /usr/share/zoneinfo/"${TZ}" /etc/localtime 2>/dev/null || true
fi

RUN_AS="root"
if [ -f /etc/docker-dev-run-as ]; then
    RUN_AS="$(tr -d '[:space:]' </etc/docker-dev-run-as)"
fi

home_for_run_as() {
    case "$1" in
    root) printf '%s' "/root" ;;
    dev)
        if getent passwd dev >/dev/null 2>&1; then
            getent passwd dev | cut -d: -f6
        else
            printf '%s' "/home/dev"
        fi
        ;;
    *) printf '%s' "/root" ;;
    esac
}

HOME_DIR="$(home_for_run_as "$RUN_AS")"

if [ -d "${HOME_DIR}/.ssh" ] && [ "$(ls -A "${HOME_DIR}/.ssh" 2>/dev/null)" ]; then
    chmod 700 "${HOME_DIR}/.ssh" 2>/dev/null || true
    chmod 600 "${HOME_DIR}/.ssh"/id_* 2>/dev/null || true
    chmod 644 "${HOME_DIR}/.ssh"/*.pub 2>/dev/null || true
fi

for mount_label in \
    "${HOME_DIR}/.ssh:SSH config" \
    "${HOME_DIR}/.codex:Codex config" \
    "${HOME_DIR}/.claude:Claude Code config" \
    "${HOME_DIR}/.config/opencode:OpenCode config" \
    "${HOME_DIR}/.pi:Pi agent config" \
    "${HOME_DIR}/.agents:Agent skills" \
    "/workspace:Workspace"; do
    path="${mount_label%%:*}"
    label="${mount_label#*:}"
    if [ -d "$path" ] && [ "$(ls -A "$path" 2>/dev/null | head -1)" != "" ]; then
        echo "[dev] Mounted ${label} → ${path}"
    fi
done

if command -v update-ai-tools >/dev/null 2>&1; then
    echo "[dev] AI CLIs: run update-ai-tools to upgrade OpenCode/Claude/Codex/Pi to latest (stops in-app update nags)."
fi

if [ "$(id -u)" -eq 0 ] && [ "$RUN_AS" = "dev" ] && id -u dev >/dev/null 2>&1; then
    exec gosu dev "$@"
fi

exec "$@"
