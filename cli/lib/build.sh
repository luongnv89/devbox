# shellcheck shell=bash

docker_dev_cmd_build() {
  local repo_root="$1"
  shift
  local image="u2604dev"
  local tag=""
  local profile=""

  while [ $# -gt 0 ]; do
    case "$1" in
      -i|--image) image="$2"; shift 2 ;;
      -t|--tag) tag="$2"; shift 2 ;;
      -p|--profile) profile="$2"; shift 2 ;;
      -h|--help)
        cat <<'EOF'
Usage: cdev build [options]

Build a dev image locally (requires Docker).

Options:
  -i, --image NAME      Image name (default: u2604dev)
  -p, --profile NAME    Build profile: minimal, standard, ai-full (default: ai-full)
  -t, --tag TAG         Image tag (default: latest, or latest-<profile> when --profile set)
  -h, --help            Show help
EOF
        return 0
        ;;
      *) usage_error "Unknown build option: $1" ;;
    esac
  done

  # shellcheck source=images.sh
  source "$(dirname "${BASH_SOURCE[0]}")/images.sh"
  # shellcheck source=profiles.sh
  source "$(dirname "${BASH_SOURCE[0]}")/profiles.sh"

  image="$(docker_dev_resolve_image "$image")"
  docker_dev_validate_image "$image"

  if [ -z "$profile" ]; then
    profile="$DOCKER_DEV_DEFAULT_PROFILE"
  fi
  docker_dev_validate_profile "$profile"

  if [ -z "$tag" ]; then
    tag="$(docker_dev_profile_image_tag "$profile")"
  fi

  require_cmd docker

  local dockerfile="${repo_root}/${image}/Dockerfile"
  [ -f "$dockerfile" ] || die "Dockerfile not found: ${dockerfile}"

  local local_tag="${image}:${tag}"
  log_info "Building ${local_tag} (profile: ${profile})"

  if ! docker build \
    --build-arg "DEV_IMAGE_PROFILE=${profile}" \
    -t "$local_tag" \
    -f "$dockerfile" \
    "${repo_root}"; then
    die "Image build failed"
  fi

  echo "✓ Built ${local_tag} (profile: ${profile})"
}