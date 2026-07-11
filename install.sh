#!/usr/bin/env bash
# Install docker-dev CLI (one-line: curl -fsSL .../install.sh | bash)
set -euo pipefail

REPO_URL="${DOCKER_DEV_INSTALL_REPO:-https://github.com/luongnv89/docker-dev.git}"
REF="${DOCKER_DEV_INSTALL_REF:-main}"
# Until the CLI is on main, curl installs use this branch automatically when main lacks cli/
FALLBACK_REF="${DOCKER_DEV_INSTALL_FALLBACK_REF:-feature/4-dev-ready-docker-cli}"
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

ensure_cli_in_repo() {
  local repo="$1"
  if [ -f "${repo}/cli/bin/docker-dev" ]; then
    return 0
  fi
  if [ "${REF}" = "main" ] && [ -n "${FALLBACK_REF}" ]; then
    echo "● main does not include cli/ yet; checking out ${FALLBACK_REF}..."
    git -C "${repo}" fetch origin "${FALLBACK_REF}" --depth 1 2>/dev/null \
      || git -C "${repo}" fetch origin "${FALLBACK_REF}"
    git -C "${repo}" checkout "${FALLBACK_REF}" 2>/dev/null \
      || git -C "${repo}" checkout -B "${FALLBACK_REF}" "origin/${FALLBACK_REF}" \
      || die "Could not checkout ${FALLBACK_REF}. Set DOCKER_DEV_INSTALL_REF explicitly."
  fi
  [ -f "${repo}/cli/bin/docker-dev" ] || die "cli/ not found in ${repo}. Set DOCKER_DEV_INSTALL_REF to a branch that contains cli/ (e.g. ${FALLBACK_REF})."
}

install_from_repo() {
  local repo="$1"
  ensure_cli_in_repo "${repo}"

  echo "● Installing CLI to ${CLI_DIR}..."
  rm -rf "${CLI_DIR}"
  cp -R "${repo}/cli" "${CLI_DIR}"
  chmod +x "${CLI_DIR}/bin/docker-dev"

  cat > "${BIN_DIR}/docker-dev" <<WRAP
#!/usr/bin/env bash
export DOCKER_DEV_REPO="${repo}"
exec "${CLI_DIR}/bin/docker-dev" "\$@"
WRAP
  chmod +x "${BIN_DIR}/docker-dev"
}

main() {
  need_cmd mkdir

  mkdir -p "${BIN_DIR}" "${SHARE_DIR}"

  # Running ./install.sh from a git checkout (recommended while developing)
  local install_script="${BASH_SOURCE[0]:-}"
  if [ -n "${install_script}" ] && [ -f "${install_script}" ]; then
    local checkout_root
    checkout_root="$(cd "$(dirname "${install_script}")" && pwd)"
    if [ -f "${checkout_root}/cli/bin/docker-dev" ]; then
      echo "● Installing from local checkout: ${checkout_root}"
      install_from_repo "${checkout_root}"
      print_success "${checkout_root}"
      return 0
    fi
  fi

  need_cmd git

  if [ -d "${REPO_DIR}/.git" ]; then
    echo "● Updating docker-dev repository..."
    git -C "${REPO_DIR}" fetch origin "${REF}" 2>/dev/null || git -C "${REPO_DIR}" fetch origin
    git -C "${REPO_DIR}" checkout "${REF}" 2>/dev/null || true
    git -C "${REPO_DIR}" pull --ff-only origin "${REF}" 2>/dev/null || true
  else
    echo "● Cloning docker-dev (shallow, ref=${REF})..."
    rm -rf "${REPO_DIR}"
    if ! git clone --depth 1 --branch "${REF}" "${REPO_URL}" "${REPO_DIR}" 2>/dev/null; then
      echo "● Branch ${REF} shallow clone failed; cloning default branch..."
      git clone --depth 1 "${REPO_URL}" "${REPO_DIR}" || die "Clone failed. Check network and REPO_URL=${REPO_URL}"
      git -C "${REPO_DIR}" checkout "${REF}" 2>/dev/null || true
    fi
  fi

  install_from_repo "${REPO_DIR}"
  print_success "${REPO_DIR}"
}

print_success() {
  local repo="$1"
  echo ""
  echo "✓ docker-dev installed"
  echo "  Binary:  ${BIN_DIR}/docker-dev"
  echo "  Repo:    ${repo}"
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