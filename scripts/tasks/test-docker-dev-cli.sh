#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CLI="${ROOT_DIR}/cli/bin/cdev"
export CDEV_REPO="${ROOT_DIR}"

assert_contains() {
  local out="$1"
  local needle="$2"
  case "$out" in
    *"$needle"*) ;;
    *) echo "Expected output to contain: ${needle}" >&2; exit 1 ;;
  esac
}

assert_contains "$("${CLI}" --version)" "cdev"
assert_contains "$("${CLI}" --help)" "cdev run"

BUILD_HELP="$(${CLI} build --help)"
assert_contains "$BUILD_HELP" "--profile"
assert_contains "$BUILD_HELP" "--nonroot"

RUN_HELP="$(${CLI} run --help)"
assert_contains "$RUN_HELP" "--profile"
assert_contains "$RUN_HELP" "--nonroot"
assert_contains "$RUN_HELP" "--mount-ssh"
assert_contains "$RUN_HELP" "--mount-opencode"
assert_contains "$RUN_HELP" "--mount-pi"
assert_contains "$RUN_HELP" "--mount-docker-socket"
assert_contains "$RUN_HELP" "read-only"
assert_contains "$("${CLI}" list)" "u2604dev"
LIST_JSON="$("${CLI}" list --format json)"
assert_contains "$LIST_JSON" "u2604dev"
case "$LIST_JSON" in
  *u2604dev-opencode*) echo "u2604dev-opencode should not appear in cdev list" >&2; exit 1 ;;
esac
RESOLVED="$(CDEV_REPO="${ROOT_DIR}" DOCKER_DEV_QUIET=1 bash -c '
  source "${CDEV_REPO}/cli/lib/common.sh"
  source "${CDEV_REPO}/cli/lib/images.sh"
  docker_dev_resolve_image u2604dev-opencode
')"
[ "$RESOLVED" = "u2604dev" ] || { echo "expected u2604dev, got: ${RESOLVED}" >&2; exit 1; }
assert_contains "$("${CLI}" config)" "Repo root"
assert_contains "$("${CLI}" config --format json)" '"repo"'

if "${CLI}" build --image badimage 2>/dev/null; then
  echo "Expected failure for bad image" >&2
  exit 1
fi

if "${CLI}" build --profile notreal --image u2604dev 2>/dev/null; then
  echo "Expected failure for bad profile" >&2
  exit 1
fi

PROFILE_TAG="$(CDEV_REPO="${ROOT_DIR}" DOCKER_DEV_QUIET=1 bash -c '
  source "${CDEV_REPO}/cli/lib/common.sh"
  source "${CDEV_REPO}/cli/lib/profiles.sh"
  docker_dev_profile_image_tag minimal
')"
[ "$PROFILE_TAG" = "latest-minimal" ] || { echo "expected latest-minimal, got: ${PROFILE_TAG}" >&2; exit 1; }

HOME_ROOT="$(CDEV_REPO="${ROOT_DIR}" DOCKER_DEV_QUIET=1 bash -c '
  source "${CDEV_REPO}/cli/lib/common.sh"
  source "${CDEV_REPO}/cli/lib/nonroot.sh"
  docker_dev_home_for_mounts 0
')"
[ "$HOME_ROOT" = "/root" ] || { echo "expected /root, got: ${HOME_ROOT}" >&2; exit 1; }
HOME_DEV="$(CDEV_REPO="${ROOT_DIR}" DOCKER_DEV_QUIET=1 bash -c '
  source "${CDEV_REPO}/cli/lib/common.sh"
  source "${CDEV_REPO}/cli/lib/nonroot.sh"
  docker_dev_home_for_mounts 1
')"
[ "$HOME_DEV" = "/home/dev" ] || { echo "expected /home/dev, got: ${HOME_DEV}" >&2; exit 1; }

if "${CLI}" bogus 2>/dev/null; then
  echo "Expected failure for unknown command" >&2
  exit 1
fi

assert_contains "$("${ROOT_DIR}/scripts/docker-dev" --version)" "cdev"

echo "cdev CLI smoke checks passed."