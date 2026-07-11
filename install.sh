#!/usr/bin/env bash
# Install docker-dev CLI (one-line: curl -fsSL .../install.sh | bash)
set -euo pipefail

REPO_URL="${DOCKER_DEV_INSTALL_REPO:-https://github.com/luongnv89/docker-dev.git}"
REF="${DOCKER_DEV_INSTALL_REF:-main}"
PREFIX="${DOCKER_DEV_PREFIX:-${HOME}/.local}"
BIN_DIR="${PREFIX}/bin"
SHARE_DIR="${PREFIX}/share/docker-dev"
CLI_DIR="${SHARE_DIR}/cli"
REPO_DIR="${SHARE_DIR}/repo"

die() {
  echo "✗ $*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

main() {
  need_cmd git
  need_cmd mkdir

  mkdir -p "${BIN_DIR}" "${SHARE_DIR}"

  if [ -d "${REPO_DIR}/.git" ]; then
    echo "● Updating docker-dev repository..."
    git -C "${REPO_DIR}" fetch origin "${REF}" --depth 1 2>/dev/null || git -C "${REPO_DIR}" fetch origin
    git -C "${REPO_DIR}" checkout "${REF}" 2>/dev/null || true
    git -C "${REPO_DIR}" pull --ff-only origin "${REF}" 2>/dev/null || true
  else
    echo "● Cloning docker-dev (shallow)..."
    rm -rf "${REPO_DIR}"
    git clone --depth 1 --branch "${REF}" "${REPO_URL}" "${REPO_DIR}" \
      || die "Clone failed. Check network and REPO_URL=${REPO_URL}"
  fi

  echo "● Installing CLI to ${CLI_DIR}..."
  rm -rf "${CLI_DIR}"
  cp -R "${REPO_DIR}/cli" "${CLI_DIR}"
  chmod +x "${CLI_DIR}/bin/docker-dev"

  cat > "${BIN_DIR}/docker-dev" <<WRAP
#!/usr/bin/env bash
export DOCKER_DEV_REPO="${REPO_DIR}"
exec "${CLI_DIR}/bin/docker-dev" "\$@"
WRAP
  chmod +x "${BIN_DIR}/docker-dev"

  echo ""
  echo "✓ docker-dev installed"
  echo "  Binary:  ${BIN_DIR}/docker-dev"
  echo "  Repo:    ${REPO_DIR}"
  echo ""
  if ! command -v docker-dev >/dev/null 2>&1; then
    echo "  Add to PATH:"
    echo "    export PATH=\"${BIN_DIR}:\$PATH\""
    echo ""
  fi
  echo "  Try:"
  echo "    docker-dev --version"
  echo "    docker-dev list"
  echo "    docker-dev run --help"
}

main "$@"