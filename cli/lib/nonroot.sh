# shellcheck shell=bash

# Non-root sandbox helpers (issue #16)
DOCKER_DEV_NONROOT_HOME="/home/dev"

docker_dev_nonroot_enabled() {
  [ "${1:-0}" -eq 1 ]
}

docker_dev_home_for_mounts() {
  local nonroot="$1"
  if docker_dev_nonroot_enabled "$nonroot"; then
    printf '%s' "${DOCKER_DEV_NONROOT_HOME}"
  else
    printf '%s' "/root"
  fi
}
