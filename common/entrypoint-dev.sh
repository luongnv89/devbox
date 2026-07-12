#!/usr/bin/env bash
# Optional volume hygiene for dev containers.
set -euo pipefail

# Default TZ is Etc/UTC (set in Dockerfile). Honor runtime override.
if [ -n "${TZ:-}" ] && [ -f /usr/share/zoneinfo/"${TZ}" ]; then
  ln -snf /usr/share/zoneinfo/"${TZ}" /etc/localtime 2>/dev/null || true
fi

if [ -d /root/.ssh ] && [ "$(ls -A /root/.ssh 2>/dev/null)" ]; then
  chmod 700 /root/.ssh 2>/dev/null || true
  chmod 600 /root/.ssh/id_* 2>/dev/null || true
  chmod 644 /root/.ssh/*.pub 2>/dev/null || true
fi

for mount_label in \
  "/root/.ssh:SSH config" \
  "/root/.codex:Codex config" \
  "/root/.claude:Claude Code config" \
  "/root/.config/opencode:OpenCode config" \
  "/root/.pi:Pi agent config" \
  "/workspace:Workspace"; do
  path="${mount_label%%:*}"
  label="${mount_label#*:}"
  if [ -d "$path" ] && [ "$(ls -A "$path" 2>/dev/null | head -1)" != "" ]; then
    echo "[dev] Mounted ${label} → ${path}"
  fi
done

exec "$@"