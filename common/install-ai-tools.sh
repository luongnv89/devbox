#!/usr/bin/env bash
# Install coding-agent CLIs and pi-extensions (image build time).
# Profile via DEV_IMAGE_PROFILE: minimal | standard | ai-full (default: ai-full)
set -euo pipefail

PROFILE="${DEV_IMAGE_PROFILE:-ai-full}"
case "$PROFILE" in
  minimal|standard|ai-full) ;;
  *)
    echo "[AI] Invalid DEV_IMAGE_PROFILE: ${PROFILE} (expected minimal, standard, or ai-full)" >&2
    exit 1
    ;;
esac

echo "[AI] Build profile: ${PROFILE}"

# Pinned versions — bump process: CONTRIBUTING.md § "Bumping AI CLI versions"
CLAUDE_CODE_VERSION="2.1.207"
CODEX_VERSION="0.144.1"
OPENCODE_AI_VERSION="1.17.18"
PI_CODING_AGENT_VERSION="0.73.1"
OPENCODE_WARP_VERSION="0.1.7"

verify_core_tooling() {
  echo "[AI] Verifying core dev binaries..."
  for cmd in git vim zsh starship node npm python3; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo "[AI] Missing expected command: $cmd" >&2
      exit 1
    fi
  done
}

if [ "$PROFILE" = "minimal" ]; then
  echo "[AI] minimal profile — skipping global AI npm CLIs and herdr"
  verify_core_tooling
  echo "[AI] Tooling install complete (minimal)."
  exit 0
fi

if [ "$PROFILE" = "standard" ]; then
  echo "[AI] standard profile — installing OpenCode and Pi only..."
  npm install -g \
    "opencode-ai@${OPENCODE_AI_VERSION}" \
    "@mariozechner/pi-coding-agent@${PI_CODING_AGENT_VERSION}"
  export PATH="${PATH}:/usr/local/bin"
  if command -v pi >/dev/null 2>&1; then
    pi install npm:opencode-pi npm:statusline-pi || echo "[AI] Warning: pi install npm extensions failed (non-fatal)"
  else
    echo "[AI] Warning: pi not on PATH after npm install" >&2
  fi
  for cmd in git vim zsh starship node npm python3 opencode pi; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo "[AI] Missing expected command: $cmd" >&2
      exit 1
    fi
  done
  echo "[AI] Tooling install complete (standard)."
  exit 0
fi

echo "[AI] ai-full profile — installing global npm CLIs (pinned)..."
npm install -g \
  "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
  "@openai/codex@${CODEX_VERSION}" \
  "opencode-ai@${OPENCODE_AI_VERSION}" \
  "@mariozechner/pi-coding-agent@${PI_CODING_AGENT_VERSION}" \
  "@warp-dot-dev/opencode-warp@${OPENCODE_WARP_VERSION}"

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

echo "[AI] Installing herdr (https://herdr.dev)..."
if curl -fsSL https://herdr.dev/install.sh | HERDR_INSTALL_DIR=/usr/local/bin bash; then
  echo "[AI] herdr installed to /usr/local/bin"
else
  echo "[AI] Warning: herdr install failed (non-fatal)" >&2
fi

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

echo "[AI] Tooling install complete (ai-full)."