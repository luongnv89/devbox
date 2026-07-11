# shellcheck shell=bash

docker_dev_cmd_build() {
  local repo_root="$1"
  shift
  local image="u2604dev"
  local tag="latest"

  while [ $# -gt 0 ]; do
    case "$1" in
      -i|--image) image="$2"; shift 2 ;;
      -t|--tag) tag="$2"; shift 2 ;;
      -h|--help)
        cat <<'EOF'
Usage: cdev build [options]

Build a dev image locally (requires Docker).

Options:
  -i, --image NAME   Image name (default: u2604dev)
  -t, --tag TAG      Image tag (default: latest)
  -h, --help         Show help
EOF
        return 0
        ;;
      *) usage_error "Unknown build option: $1" ;;
    esac
  done

  # shellcheck source=images.sh
  source "$(dirname "${BASH_SOURCE[0]}")/images.sh"
  docker_dev_validate_image "$image"

  require_cmd docker

  local dockerfile="${repo_root}/${image}/Dockerfile"
  [ -f "$dockerfile" ] || die "Dockerfile not found: ${dockerfile}"

  local local_tag="${image}:${tag}"
  log_info "Building ${local_tag}"

  if [ "$image" = "u2604dev-opencode" ]; then
    log_verbose "Building base u2604dev:latest first"
    docker build -t u2604dev:latest -f "${repo_root}/u2604dev/Dockerfile" "${repo_root}" \
      || die "Base image build failed"
  fi

  if ! docker build -t "$local_tag" -f "$dockerfile" "${repo_root}"; then
    die "Image build failed"
  fi

  echo "✓ Built ${local_tag}"
}