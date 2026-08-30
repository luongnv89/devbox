#!/usr/bin/env bash
# Upgrade baked-in AI CLIs, personal tools, and skill repos to latest.
# Installed into images as /usr/local/bin/update-ai-tools.
# Profile via /etc/docker-dev-ai-profile or DEV_IMAGE_PROFILE (default: ai-full).
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        exec sudo -E "$0" "$@"
    fi
    echo "Error: update-ai-tools must run as root (or with sudo) so global npm installs can write to /usr/local." >&2
    exit 1
fi

PROFILE="${DEV_IMAGE_PROFILE:-}"
if [ -z "$PROFILE" ] && [ -f /etc/docker-dev-ai-profile ]; then
    PROFILE="$(tr -d '[:space:]' </etc/docker-dev-ai-profile)"
fi
PROFILE="${PROFILE:-ai-full}"

case "$PROFILE" in
minimal | standard | ai-full) ;;
*)
    echo "[AI] Invalid profile '${PROFILE}' (expected minimal, standard, or ai-full)" >&2
    exit 1
    ;;
esac

echo "[AI] Updating tooling (profile: ${PROFILE})"

if [ "$PROFILE" = "minimal" ]; then
    echo "[AI] minimal profile — no global AI npm CLIs to update."
    exit 0
fi

if ! command -v npm >/dev/null 2>&1; then
    echo "Error: npm is not on PATH." >&2
    exit 1
fi

export PATH="${PATH}:/usr/local/bin"
# Honor the calling user's HOME (sudo -E) so non-root containers update /home/dev.
HOME="${HOME:-/root}"
export HOME

AI_ASM_REPOS=(github:luongnv89/idd github:luongnv89/skills)

npm_latest() {
    local specs=()
    local pkg
    for pkg in "$@"; do
        specs+=("${pkg}@latest")
    done
    echo "[AI] npm install -g ${specs[*]}"
    npm install -g "${specs[@]}"
}

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
        echo "[AI] Warning: asm not on PATH — skipping skill update" >&2
        return 0
    fi

    local repo
    for repo in "${AI_ASM_REPOS[@]}"; do
        echo "[AI] asm install ${repo} --all -p agents -s global"
        asm install "$repo" --all -p agents -s global -y --force ||
            echo "[AI] Warning: asm install ${repo} failed (non-fatal)" >&2
    done

    if [ ! -d "${HOME}/.agents/skills" ]; then
        return 0
    fi

    local tool
    for tool in "$@"; do
        if [ "$tool" = pi ]; then
            link_pi_skills
            continue
        fi
        echo "[AI] asm link ${HOME}/.agents/skills → ${tool}"
        asm link "${HOME}/.agents/skills" -p "$tool" -f ||
            echo "[AI] Warning: asm link to ${tool} failed (non-fatal)" >&2
    done
}

if [ "$PROFILE" = "standard" ]; then
    npm_latest opencode-ai @mariozechner/pi-coding-agent agent-skill-manager
else
    npm_latest \
        @anthropic-ai/claude-code \
        @openai/codex \
        opencode-ai \
        @mariozechner/pi-coding-agent \
        agent-skill-manager
fi

if command -v pi >/dev/null 2>&1; then
    echo "[AI] Updating pi npm extensions..."
    pi install npm:opencode-pi npm:statusline-pi || echo "[AI] Warning: pi install npm extensions failed (non-fatal)" >&2
fi

if [ "$PROFILE" = "ai-full" ]; then
    echo "[AI] Updating luongnv89/pi-extensions..."
    curl -fsSL https://raw.githubusercontent.com/luongnv89/pi-extensions/main/install.sh |
        bash -s -- --auto || echo "[AI] Warning: pi-extensions install failed (non-fatal)" >&2

    echo "[AI] Updating herdr..."
    if curl -fsSL https://herdr.dev/install.sh | HERDR_INSTALL_DIR=/usr/local/bin bash; then
        echo "[AI] herdr updated in /usr/local/bin"
    else
        echo "[AI] Warning: herdr install failed (non-fatal)" >&2
    fi
    install_asm_skills claude opencode pi codex
else
    install_asm_skills opencode pi
fi

echo "[AI] Update complete. Restart the CLI (opencode / claude / codex / pi) so it picks up the new binary."
