# shellcheck shell=bash
# Shared helpers for docker-dev CLI.

DOCKER_DEV_VERSION="${DOCKER_DEV_VERSION:-}"

die() {
  echo "✗ $*" >&2
  exit 1
}

usage_error() {
  echo "✗ $*" >&2
  exit 2
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

# Resolve repository root (Dockerfiles + common/).
docker_dev_resolve_repo_root() {
  local cli_root="$1"
  local candidate
  candidate="$(cd "${cli_root}/.." && pwd)"
  if [ -f "${candidate}/u2604dev/Dockerfile" ] && [ -d "${candidate}/common" ]; then
    echo "${candidate}"
    return 0
  fi
  if [ -n "${DOCKER_DEV_REPO:-}" ] && [ -f "${DOCKER_DEV_REPO}/u2604dev/Dockerfile" ]; then
    echo "${DOCKER_DEV_REPO}"
    return 0
  fi
  local default="${HOME}/.local/share/docker-dev/repo"
  if [ -f "${default}/u2604dev/Dockerfile" ]; then
    echo "${default}"
    return 0
  fi
  die "docker-dev repo not found. Set DOCKER_DEV_REPO or run: curl -fsSL https://raw.githubusercontent.com/luongnv89/docker-dev/main/install.sh | bash"
}

color_enabled() {
  [ -n "${NO_COLOR:-}" ] && return 1
  [ "${DOCKER_DEV_NO_COLOR:-0}" -eq 1 ] && return 1
  return 0
}

log_info() {
  [ "${DOCKER_DEV_QUIET:-0}" -eq 1 ] && return 0
  if color_enabled; then
    echo "● $*"
  else
    echo "● $*"
  fi
}

log_verbose() {
  [ "${DOCKER_DEV_VERBOSE:-0}" -eq 0 ] && return 0
  echo "  $*" >&2
}

require_dir() {
  local label="$1"
  local path="$2"
  [ -n "$path" ] || usage_error "${label} path is empty"
  [ -d "$path" ] || die "${label} not found: ${path} (create it or fix the path)"
}

prompt_yes_no() {
  local prompt="$1"
  local default="${2:-y}"
  [ "${DOCKER_DEV_INTERACTIVE:-1}" -eq 0 ] && return 0
  local hint="[Y/n]"
  [ "$default" = "n" ] && hint="[y/N]"
  read -r -p "${prompt} ${hint} " ans || true
  ans="${ans:-$default}"
  case "$ans" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}