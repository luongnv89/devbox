#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CLI="${ROOT_DIR}/cli/bin/docker-dev"
export DOCKER_DEV_REPO="${ROOT_DIR}"

assert_contains() {
  local out="$1"
  local needle="$2"
  case "$out" in
    *"$needle"*) ;;
    *) echo "Expected output to contain: ${needle}" >&2; exit 1 ;;
  esac
}

assert_contains "$("${CLI}" --version)" "docker-dev"
assert_contains "$("${CLI}" --help)" "docker-dev run"
assert_contains "$("${CLI}" list)" "u2604dev"
assert_contains "$("${CLI}" list --format json)" "u2604dev"
assert_contains "$("${CLI}" config)" "Repo root"
assert_contains "$("${CLI}" config --format json)" '"repo"'

if "${CLI}" build --image badimage 2>/dev/null; then
  echo "Expected failure for bad image" >&2
  exit 1
fi

if "${CLI}" bogus 2>/dev/null; then
  echo "Expected failure for unknown command" >&2
  exit 1
fi

assert_contains "$("${ROOT_DIR}/scripts/docker-dev" --version)" "docker-dev"

echo "docker-dev CLI smoke checks passed."