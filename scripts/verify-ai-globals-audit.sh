#!/usr/bin/env bash
# Audit pinned global AI npm packages from common/install-ai-tools.sh.
# Complements Trivy image scans (OS/packages in the built image).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_SCRIPT="${ROOT_DIR}/common/install-ai-tools.sh"

if [[ ! -f "${INSTALL_SCRIPT}" ]]; then
  echo "✗ Missing ${INSTALL_SCRIPT}" >&2
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "✗ npm is required on the runner (Node.js LTS)." >&2
  exit 1
fi

read_version() {
  local var_name="$1"
  grep -E "^${var_name}=" "${INSTALL_SCRIPT}" | head -1 | cut -d= -f2- | tr -d '"'
}

CLAUDE_CODE_VERSION="$(read_version CLAUDE_CODE_VERSION)"
CODEX_VERSION="$(read_version CODEX_VERSION)"
OPENCODE_AI_VERSION="$(read_version OPENCODE_AI_VERSION)"
PI_CODING_AGENT_VERSION="$(read_version PI_CODING_AGENT_VERSION)"
OPENCODE_WARP_VERSION="$(read_version OPENCODE_WARP_VERSION)"

for v in CLAUDE_CODE_VERSION CODEX_VERSION OPENCODE_AI_VERSION PI_CODING_AGENT_VERSION OPENCODE_WARP_VERSION; do
  if [[ -z "${!v}" ]]; then
    echo "✗ Could not read ${v} from ${INSTALL_SCRIPT}" >&2
    exit 1
  fi
done

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT

cat > "${WORK_DIR}/package.json" <<EOF
{
  "name": "docker-dev-ai-globals-audit",
  "private": true,
  "version": "0.0.0",
  "dependencies": {
    "@anthropic-ai/claude-code": "${CLAUDE_CODE_VERSION}",
    "@openai/codex": "${CODEX_VERSION}",
    "opencode-ai": "${OPENCODE_AI_VERSION}",
    "@mariozechner/pi-coding-agent": "${PI_CODING_AGENT_VERSION}",
    "@warp-dot-dev/opencode-warp": "${OPENCODE_WARP_VERSION}"
  }
}
EOF

echo "==> npm audit (pinned AI global packages)"
cd "${WORK_DIR}"
npm install --package-lock-only --ignore-scripts --no-audit 2>/dev/null || npm install --ignore-scripts --no-audit

echo "==> Full audit report (informational)"
npm audit || true

# Block on critical only; high findings are tracked via pin bumps (see CONTRIBUTING.md).
if npm audit --audit-level=critical; then
  echo "✔ No critical vulnerabilities in pinned AI npm dependencies"
else
  echo "✗ npm audit reported critical issues — bump pins in install-ai-tools.sh" >&2
  exit 1
fi