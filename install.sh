#!/usr/bin/env bash
# Install cdev CLI + herdr (one-line: curl -fsSL .../install.sh | bash)
set -euo pipefail

REPO_URL="${DOCKER_DEV_INSTALL_REPO:-https://github.com/luongnv89/docker-dev.git}"
REF="${DOCKER_DEV_INSTALL_REF:-main}"
PREFIX="${DOCKER_DEV_PREFIX:-${HOME}/.local}"
BIN_DIR="${PREFIX}/bin"
SHARE_DIR="${PREFIX}/share/docker-dev"
CLI_DIR="${SHARE_DIR}/cli"
REPO_DIR="${SHARE_DIR}/repo"
CLI_NAME="${CDEV_CLI_NAME:-cdev}"
INSTALL_HERDR="${CDEV_INSTALL_HERDR:-1}"

die() {
  echo "✗ $*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

ensure_cli_in_repo() {
  local repo="$1"
  [ -f "${repo}/cli/bin/cdev" ] \
    || die "cli/bin/cdev not found in ${repo} (ref ${REF}). Merge to main or set DOCKER_DEV_INSTALL_REF."
}

install_herdr() {
  [ "${INSTALL_HERDR}" = "1" ] || return 0
  if command -v herdr >/dev/null 2>&1; then
    echo "● herdr already installed: $(command -v herdr)"
    return 0
  fi
  need_cmd curl
  echo "● Installing herdr (https://herdr.dev)..."
  if curl -fsSL https://herdr.dev/install.sh | HERDR_INSTALL_DIR="${BIN_DIR}" bash; then
    echo "✓ herdr installed"
  else
    echo "⚠ herdr install failed — cdev is still installed. Retry: curl -fsSL https://herdr.dev/install.sh | bash" >&2
  fi
}

install_from_repo() {
  local repo="$1"
  ensure_cli_in_repo "${repo}"

  echo "● Installing cdev CLI to ${CLI_DIR}..."
  rm -rf "${CLI_DIR}"
  cp -R "${repo}/cli" "${CLI_DIR}"
  chmod +x "${CLI_DIR}/bin/cdev"

  cat > "${BIN_DIR}/${CLI_NAME}" <<WRAP
#!/usr/bin/env bash
export DOCKER_DEV_REPO="${repo}"
exec "${CLI_DIR}/bin/cdev" "\$@"
WRAP
  chmod +x "${BIN_DIR}/${CLI_NAME}"

  # Deprecated alias
  if [ "${CLI_NAME}" != "docker-dev" ] && [ ! -e "${BIN_DIR}/docker-dev" ]; then
    ln -sf "${CLI_NAME}" "${BIN_DIR}/docker-dev" 2>/dev/null || true
  fi
}

main() {
  need_cmd mkdir
  mkdir -p "${BIN_DIR}" "${SHARE_DIR}"

  local install_script="${BASH_SOURCE[0]:-}"
  if [ -n "${install_script}" ] && [ -f "${install_script}" ]; then
    local checkout_root
    checkout_root="$(cd "$(dirname "${install_script}")" && pwd)"
    if [ -f "${checkout_root}/cli/bin/cdev" ]; then
      echo "● Installing from local checkout: ${checkout_root}"
      install_from_repo "${checkout_root}"
      install_herdr
      print_success "${checkout_root}"
      return 0
    fi
  fi

  need_cmd git

  if [ -d "${REPO_DIR}/.git" ]; then
    echo "● Updating docker-dev repository (ref=${REF})..."
    git -C "${REPO_DIR}" fetch origin "${REF}" 2>/dev/null || git -C "${REPO_DIR}" fetch origin
    git -C "${REPO_DIR}" checkout "${REF}" 2>/dev/null || true
    git -C "${REPO_DIR}" pull --ff-only origin "${REF}" 2>/dev/null || true
  else
    echo "● Cloning docker-dev (shallow, ref=${REF})..."
    rm -rf "${REPO_DIR}"
    if ! git clone --depth 1 --branch "${REF}" "${REPO_URL}" "${REPO_DIR}" 2>/dev/null; then
      echo "● Shallow clone of branch ${REF} failed; cloning default branch..."
      git clone --depth 1 "${REPO_URL}" "${REPO_DIR}" || die "Clone failed. Check network and REPO_URL=${REPO_URL}"
      git -C "${REPO_DIR}" checkout "${REF}" 2>/dev/null || true
    fi
  fi

  install_from_repo "${REPO_DIR}"
  install_herdr
  print_success "${REPO_DIR}"
}

print_success() {
  local repo="$1"
  echo ""
  echo "✓ ${CLI_NAME} installed"
  echo "  Binary:  ${BIN_DIR}/${CLI_NAME}"
  echo "  Repo:    ${repo}"
  echo ""
  if ! command -v "${CLI_NAME}" >/dev/null 2>&1; then
    echo "  Add to PATH:"
    echo "    export PATH=\"${BIN_DIR}:\$PATH\""
    echo ""
  fi
  echo "  Try:"
  echo "    ${CLI_NAME} --version"
  echo "    ${CLI_NAME} list"
  echo "    herdr --help   # if herdr installed"
  echo "    ${CLI_NAME} run --help"
}

main "$@"