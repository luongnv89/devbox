#!/usr/bin/env bash
# Install coding-agent CLIs, pi-extensions, asm, and personal skill repos
# (image build time).
# Profile via DEV_IMAGE_PROFILE: minimal | standard | ai-full (default: ai-full)
set -euo pipefail

PROFILE="${DEV_IMAGE_PROFILE:-ai-full}"
# lenient: warn on optional PATH shims (default, local-friendly)
# strict: fail image build if required CLIs are not on PATH after install (CI/release)
AI_VERIFY_MODE="${AI_VERIFY_MODE:-lenient}"
case "$AI_VERIFY_MODE" in
  lenient|strict) ;;
  *)
    echo "[AI] Invalid AI_VERIFY_MODE: ${AI_VERIFY_MODE} (expected lenient or strict)" >&2
    exit 1
    ;;
esac

case "$PROFILE" in
  minimal|standard|ai-full) ;;
  *)
    echo "[AI] Invalid DEV_IMAGE_PROFILE: ${PROFILE} (expected minimal, standard, or ai-full)" >&2
    exit 1
    ;;
esac

echo "[AI] Build profile: ${PROFILE} (verify: ${AI_VERIFY_MODE})"

# Image build runs as root; keep HOME deterministic for asm skill placement.
export HOME=/root
export PATH="${PATH}:/usr/local/bin"

# Always install current npm latest so CLIs do not nag for upgrades on first
# use. Refresh a running container with update-ai-tools. Bust the image AI
# layer with build-arg AI_TOOLS_CACHEBUST.
AI_NPM_STANDARD=(opencode-ai @mariozechner/pi-coding-agent agent-skill-manager)
AI_NPM_FULL=(
  @anthropic-ai/claude-code
  @openai/codex
  opencode-ai
  @mariozechner/pi-coding-agent
  agent-skill-manager
)
AI_ASM_REPOS=(github:luongnv89/idd github:luongnv89/skills)

install_updater() {
  printf '%s\n' "$PROFILE" >/etc/docker-dev-ai-profile
  if [ -f /opt/common/update-ai-tools.sh ]; then
    install -m 0755 /opt/common/update-ai-tools.sh /usr/local/bin/update-ai-tools
    echo "[AI] Installed /usr/local/bin/update-ai-tools"
  else
    echo "[AI] Warning: /opt/common/update-ai-tools.sh missing — updater not installed" >&2
  fi
}

npm_latest() {
  local specs=()
  local pkg
  for pkg in "$@"; do
    specs+=("${pkg}@latest")
  done
  echo "[AI] npm install -g ${specs[*]}"
  npm install -g "${specs[@]}"
}

install_pi_npm_extensions() {
  if command -v pi >/dev/null 2>&1; then
    echo "[AI] Installing pi npm extensions..."
    pi install npm:opencode-pi npm:statusline-pi || echo "[AI] Warning: pi install npm extensions failed (non-fatal)" >&2
  else
    echo "[AI] Warning: pi not on PATH after npm install" >&2
  fi
}

# Canonical copies in ~/.agents/skills, then symlink into the CLIs this image ships.
# asm has no `pi` provider; Pi still reads ~/.pi/skills.
link_pi_skills() {
  local src="${HOME}/.agents/skills"
  local dest="${HOME}/.pi/skills"
  if [ ! -d "$src" ]; then
    return 0
  fi
  mkdir -p "$dest"
  local skill
  for skill in "$src"/*; do
    [ -d "$skill" ] || continue
    ln -sfn "$skill" "${dest}/$(basename "$skill")"
  done
  echo "[AI] Linked skills into ${dest}"
}

install_asm_skills() {
  if ! command -v asm >/dev/null 2>&1; then
    echo "[AI] Warning: asm not on PATH — skipping skill install" >&2
    return 0
  fi
  if ! command -v git >/dev/null 2>&1; then
    echo "[AI] Warning: git not on PATH — asm cannot clone skill repos" >&2
    return 0
  fi

  local repo
  for repo in "${AI_ASM_REPOS[@]}"; do
    echo "[AI] asm install ${repo} --all -p agents -s global"
    asm install "$repo" --all -p agents -s global -y --force \
      || echo "[AI] Warning: asm install ${repo} failed (non-fatal)" >&2
  done

  if [ ! -d "${HOME}/.agents/skills" ]; then
    echo "[AI] Warning: ${HOME}/.agents/skills missing after asm install" >&2
    return 0
  fi

  local tool
  for tool in "$@"; do
    if [ "$tool" = pi ]; then
      link_pi_skills
      continue
    fi
    echo "[AI] asm link ${HOME}/.agents/skills → ${tool}"
    asm link "${HOME}/.agents/skills" -p "$tool" -f \
      || echo "[AI] Warning: asm link to ${tool} failed (non-fatal)" >&2
  done
}

# setup-dev-user.sh runs before this script, so copy baked skills into /home/dev.
seed_ai_home_for_dev() {
  if ! getent passwd dev >/dev/null 2>&1; then
    return 0
  fi
  local dest
  dest="$(getent passwd dev | cut -d: -f6)"
  if [ -z "$dest" ] || [ "$dest" = /root ]; then
    return 0
  fi
  echo "[AI] Seeding ${dest} with baked agent skills"
  mkdir -p "${dest}/.config"
  if [ -d /root/.agents ]; then
    rm -rf "${dest}/.agents"
    cp -a /root/.agents "${dest}/"
  fi
  if [ -d /root/.config/agent-skill-manager ]; then
    rm -rf "${dest}/.config/agent-skill-manager"
    cp -a /root/.config/agent-skill-manager "${dest}/.config/"
  fi
  if [ -d "${dest}/.agents/skills" ]; then
    local old_home="${HOME}"
    export HOME="$dest"
    local tool
    for tool in "$@"; do
      if [ "$tool" = pi ]; then
        link_pi_skills
        continue
      fi
      asm link "${dest}/.agents/skills" -p "$tool" -f \
        || echo "[AI] Warning: asm link for ${dest} → ${tool} failed (non-fatal)" >&2
    done
    export HOME="$old_home"
  fi
  chown -R dev:dev \
    "${dest}/.agents" \
    "${dest}/.claude" \
    "${dest}/.codex" \
    "${dest}/.pi" \
    "${dest}/.config/opencode" \
    "${dest}/.config/agent-skill-manager" \
    2>/dev/null || true
}

declare -a REQUIRED_COMMANDS=()
if [ -n "${AI_REQUIRED_COMMANDS:-}" ]; then
  read -r -a REQUIRED_COMMANDS <<< "${AI_REQUIRED_COMMANDS}"
else
  REQUIRED_COMMANDS=(git vim zsh starship node npm python3)
fi

verify_commands() {
  local cmd
  for cmd in "$@"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo "[AI] Missing expected command: $cmd" >&2
      exit 1
    fi
  done
}

verify_core_tooling() {
  echo "[AI] Verifying core dev binaries..."
  verify_commands "${REQUIRED_COMMANDS[@]}"
}

if [ "$PROFILE" = "minimal" ]; then
  echo "[AI] minimal profile — skipping global AI npm CLIs and herdr"
  install_updater
  verify_core_tooling
  echo "[AI] Tooling install complete (minimal)."
  exit 0
fi

if [ "$PROFILE" = "standard" ]; then
  echo "[AI] standard profile — installing OpenCode, Pi, and asm at latest..."
  npm_latest "${AI_NPM_STANDARD[@]}"
  install_pi_npm_extensions
  install_asm_skills opencode pi
  seed_ai_home_for_dev opencode pi
  install_updater
  verify_core_tooling
  verify_commands opencode pi asm
  echo "[AI] Tooling install complete (standard)."
  exit 0
fi

echo "[AI] ai-full profile — installing global npm CLIs at latest..."
npm_latest "${AI_NPM_FULL[@]}"

install_pi_npm_extensions

echo "[AI] Installing luongnv89/pi-extensions (extensions + themes)..."
curl -fsSL https://raw.githubusercontent.com/luongnv89/pi-extensions/main/install.sh \
  | bash -s -- --auto

echo "[AI] Installing herdr (https://herdr.dev)..."
if curl -fsSL https://herdr.dev/install.sh | HERDR_INSTALL_DIR=/usr/local/bin bash; then
  echo "[AI] herdr installed to /usr/local/bin"
else
  echo "[AI] Warning: herdr install failed (non-fatal)" >&2
fi

install_asm_skills claude opencode pi codex
seed_ai_home_for_dev claude opencode pi codex

echo "[AI] Verifying binaries..."
install_updater
verify_core_tooling
verify_commands opencode pi asm

# Claude/Codex are required for ai-full; lenient mode only warns if npm shims are missing
for optional_cmd in claude codex; do
  if ! command -v "$optional_cmd" >/dev/null 2>&1; then
    msg="[AI] ${optional_cmd} CLI not on PATH after global npm install"
    if [ "$AI_VERIFY_MODE" = "strict" ]; then
      echo "${msg} (strict verify — failing build)" >&2
      exit 1
    fi
    echo "[AI] Note: ${optional_cmd} CLI not on PATH (lenient — mount ~/.${optional_cmd} at runtime or use npx)"
  fi
done

echo "[AI] Tooling install complete (ai-full)."
