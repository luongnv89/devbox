#!/usr/bin/env bash
# Optional volume hygiene for dev containers.
set -euo pipefail

if [ -d /root/.ssh ] && [ "$(ls -A /root/.ssh 2>/dev/null)" ]; then
  chmod 700 /root/.ssh 2>/dev/null || true
  chmod 600 /root/.ssh/id_* 2>/dev/null || true
  chmod 644 /root/.ssh/*.pub 2>/dev/null || true
fi

for mount_label in \
  "/root/.codex:Codex config" \
  "/root/.claude:Claude Code config" \
  "/workspace:Workspace"; do
  path="${mount_label%%:*}"
  label="${mount_label#*:}"
  if [ -d "$path" ] && [ "$(ls -A "$path" 2>/dev/null | head -1)" != "" ]; then
    echo "[dev] Mounted ${label} → ${path}"
  fi
done

exec "$@"