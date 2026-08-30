# shellcheck shell=bash

docker_dev_cmd_build() {
  local repo_root="$1"
  shift
  local image="u2604dev"
  local tag=""
  local profile=""
  local nonroot=0
  local dev_uid=""
  local dev_gid=""

  while [ $# -gt 0 ]; do
    case "$1" in
      -i|--image) image="$2"; shift 2 ;;
      -t|--tag) tag="$2"; shift 2 ;;
      -p|--profile) profile="$2"; shift 2 ;;
      --nonroot) nonroot=1; shift ;;
      --dev-uid) dev_uid="$2"; shift 2 ;;
      --dev-gid) dev_gid="$2"; shift 2 ;;
      -h|--help)
        cat <<'EOF'
Usage: cdev build [options]

Build a dev image locally (requires Docker).

Options:
  -i, --image NAME      Image name: u2204dev, u2404dev, u2604dev, devbox (default: u2604dev)
  -p, --profile NAME    Build profile: minimal, standard, ai-full (default: ai-full; devbox: standard)
  -t, --tag TAG         Image tag (default: latest, or latest-<profile> when --profile set)
  --nonroot             Create dev user (uid/gid 1000 or host id when set)
  --dev-uid UID         UID for dev user when --nonroot (default: 1000)
  --dev-gid GID         GID for dev user when --nonroot (default: 1000)
  -h, --help            Show help

AI npm CLIs install @latest. Each cdev build refreshes that layer
(AI_TOOLS_CACHEBUST). Inside a running container: update-ai-tools
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
  # shellcheck source=nonroot.sh
  source "$(dirname "${BASH_SOURCE[0]}")/nonroot.sh"

  image="$(docker_dev_resolve_image "$image")"
  docker_dev_validate_image "$image"

  if [ -z "$profile" ]; then
    profile="$(docker_dev_default_profile_for_image "$image")"
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

  local build_args=(--build-arg "DEV_IMAGE_PROFILE=${profile}" --build-arg "AI_TOOLS_CACHEBUST=$(date +%s)")
  if docker_dev_nonroot_enabled "$nonroot"; then
    dev_uid="${dev_uid:-1000}"
    dev_gid="${dev_gid:-1000}"
    build_args+=(--build-arg "DEV_CREATE_NONROOT_USER=1" --build-arg "DEV_UID=${dev_uid}" --build-arg "DEV_GID=${dev_gid}")
  fi

  if ! docker build \
    "${build_args[@]}" \
    -t "$local_tag" \
    -f "$dockerfile" \
    "${repo_root}"; then
    die "Image build failed"
  fi

  if docker_dev_nonroot_enabled "$nonroot"; then
    echo "✓ Built ${local_tag} (profile: ${profile}, non-root dev user uid=${dev_uid})"
  else
    echo "✓ Built ${local_tag} (profile: ${profile})"
  fi
}