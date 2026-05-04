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

# Configure opencode
# Copy opencode configuration from host mount at runtime
# ENV OPENCODE_CONFIG_DIR=/root/.config/opencode

# Set up workspace directory (will be mounted from host)
RUN mkdir -p /workspace

# Display opencode version and welcome message
RUN set -eux; \
    echo "[OpenCode] Verifying installation"; \
    opencode --version || true; \
    echo ""; \
    echo "OpenCode is installed in this container!"; \
    echo "To use with your configuration:"; \
    echo "  1. Mount ~/workspace from host: -v ~/workspace:/workspace"; \
    echo "  2. Mount ~/.ssh from host: -v ~/.ssh:/root/.ssh"; \
    echo "  3. Copy your opencode config: cp /path/to/opencode.json /root/.config/opencode/opencode.json"; \
    echo ""

# Drop into zsh by default for interactive containers
CMD [ "zsh" ]