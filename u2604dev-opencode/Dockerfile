FROM u2604dev:latest

# Author / Maintainer: luongnv89
LABEL maintainer="luongnv89"

ENV DEBIAN_FRONTEND=noninteractive

# Install opencode from npm
RUN set -eux; \
    echo "[OpenCode] Installing opencode CLI from npm"; \
    npm install -g opencode-ai;

# Install opencode warp plugin
RUN set -eux; \
    echo "[OpenCode] Installing opencode warp plugin"; \
    npm install -g @warp-dot-dev/opencode-warp;

# Set up directories
RUN mkdir -p /workspace /root/.ssh /root/.config/opencode

# Create entrypoint that handles optional volumes
COPY <<'EOF' /entrypoint.sh
#!/bin/zsh
# Entrypoint: handles optional volume mounts gracefully

# Fix SSH permissions if .ssh volume is mounted
if [ -d /root/.ssh ] && [ "$(ls -A /root/.ssh 2>/dev/null)" ]; then
    chmod 700 /root/.ssh 2>/dev/null || true
    chmod 600 /root/.ssh/id_* 2>/dev/null || true
    chmod 644 /root/.ssh/*.pub 2>/dev/null || true
fi

# Create default workspace if not mounted
if [ ! -d /workspace ] || [ "$(ls -A /workspace 2>/dev/null | head -1)" = "" ]; then
    echo "[OpenCode] No workspace mounted, using default /workspace"
fi

exec "$@"
EOF
RUN chmod +x /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]

# Display opencode version and welcome message
RUN set -eux; \
    echo "[OpenCode] Verifying installation"; \
    opencode --version || true; \
    echo ""; \
    echo "================================================="; \
    echo "  OpenCode is installed in this container!"; \
    echo "================================================="; \
    echo ""

# Drop into zsh
CMD [ "zsh" ]

# ============== Usage (docker run only) ==============
#
# DEFAULT (all volumes):
#   docker run -it --rm \
#     -v ~/workspace:/workspace \
#     -v ~/.ssh:/root/.ssh:ro \
#     -v ~/.config/opencode:/root/.config/opencode \
#     u2604dev-opencode:latest
#
# CUSTOM PATHS:
#   docker run -it --rm \
#     -v /my/workspace:/workspace \
#     -v /my/ssh:/root/.ssh:ro \
#     -v /my/opencode:/root/.config/opencode \
#     u2604dev-opencode:latest
#
# WORKSPACE ONLY (optional volumes disabled):
#   docker run -it --rm \
#     -v ~/workspace:/workspace \
#     u2604dev-opencode:latest
#
# VOLUME OPTIONS:
#   -v ~/workspace:/workspace          workspace (required)
#   -v ~/.ssh:/root/.ssh:ro            SSH credentials (optional)
#   -v ~/.config/opencode:/root/.config/opencode  opencode config (optional)