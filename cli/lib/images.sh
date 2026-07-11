# shellcheck shell=bash

DOCKER_DEV_IMAGES=(u2204dev u2404dev u2604dev u2604dev-opencode)

docker_dev_validate_image() {
  local image="$1"
  local img
  for img in "${DOCKER_DEV_IMAGES[@]}"; do
    [ "$img" = "$image" ] && return 0
  done
  usage_error "Unsupported image: ${image} (use: docker-dev list)"
}