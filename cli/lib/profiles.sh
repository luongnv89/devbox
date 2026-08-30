# shellcheck shell=bash

# Build-time / pull-time dev image profiles (issue #14)
DOCKER_DEV_PROFILES=(minimal standard ai-full)
DOCKER_DEV_DEFAULT_PROFILE="ai-full"

docker_dev_validate_profile() {
  local profile="$1"
  local p
  for p in "${DOCKER_DEV_PROFILES[@]}"; do
    [ "$p" = "$profile" ] && return 0
  done
  usage_error "Unsupported profile: ${profile} (use: minimal, standard, ai-full)"
}

# The lean Debian image is intended for OpenCode and defaults to standard;
# Ubuntu images retain ai-full for backwards compatibility.
docker_dev_default_profile_for_image() {
  local image="$1"
  if [ "$image" = "devbox" ]; then
    printf '%s' "standard"
  else
    printf '%s' "$DOCKER_DEV_DEFAULT_PROFILE"
  fi
}

# Image reference tag for ghcr.io pulls (ai-full keeps unprefixed latest for compatibility)
docker_dev_profile_image_tag() {
  local profile="$1"
  docker_dev_validate_profile "$profile"
  if [ "$profile" = "ai-full" ]; then
    printf '%s' "latest"
  else
    printf '%s' "latest-${profile}"
  fi
}