#!/usr/bin/env bash
# Audit current latest global AI npm packages (same set as install-ai-tools.sh).
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

if ! grep -q 'npm install -g' "${INSTALL_SCRIPT}" && ! grep -q 'npm_latest' "${INSTALL_SCRIPT}"; then
    echo "✗ ${INSTALL_SCRIPT} does not look like the AI CLI installer" >&2
    exit 1
fi

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT

cat >"${WORK_DIR}/package.json" <<'EOF'
{
  "name": "docker-dev-ai-globals-audit",
  "private": true,
  "version": "0.0.0",
  "dependencies": {
    "@anthropic-ai/claude-code": "latest",
    "@openai/codex": "latest",
    "opencode-ai": "latest",
    "@mariozechner/pi-coding-agent": "latest",
    "agent-skill-manager": "latest"
  }
}
EOF

echo "==> npm audit (latest AI global packages)"
cd "${WORK_DIR}"
npm install --package-lock-only --ignore-scripts --no-audit 2>/dev/null || npm install --ignore-scripts --no-audit

echo "==> Full audit report (informational)"
npm audit || true

if npm audit --audit-level=critical; then
    echo "✔ No critical vulnerabilities in latest AI npm dependencies"
else
    echo "✗ npm audit reported critical issues in current latest AI npm packages" >&2
    exit 1
fi
