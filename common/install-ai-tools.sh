#!/usr/bin/env bash
# Install coding-agent CLIs and pi-extensions (image build time).
set -euo pipefail

echo "[AI] Installing global npm CLIs..."
npm install -g \
  @anthropic-ai/claude-code \
  @openai/codex \
  opencode-ai \
  @mariozechner/pi-coding-agent \
  @warp-dot-dev/opencode-warp

export PATH="${PATH}:/usr/local/bin"

echo "[AI] Installing pi npm extensions..."
if command -v pi >/dev/null 2>&1; then
  pi install npm:opencode-pi npm:statusline-pi || echo "[AI] Warning: pi install npm extensions failed (non-fatal)"
else
  echo "[AI] Warning: pi not on PATH after npm install" >&2
fi

echo "[AI] Installing luongnv89/pi-extensions (extensions + themes)..."
curl -fsSL https://raw.githubusercontent.com/luongnv89/pi-extensions/main/install.sh \
  | bash -s -- --auto

echo "[AI] Verifying binaries..."
for cmd in git vim zsh starship node npm python3 opencode pi; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "[AI] Missing expected command: $cmd" >&2
    exit 1
  fi
done

# Claude/Codex may be installed as node shims; check npm globals if not on PATH
if ! command -v claude >/dev/null 2>&1; then
  echo "[AI] Note: claude CLI not on PATH (mount ~/.claude at runtime or use npx)"
fi
if ! command -v codex >/dev/null 2>&1; then
  echo "[AI] Note: codex CLI not on PATH (mount ~/.codex at runtime or use npx)"
fi

echo "[AI] Tooling install complete."