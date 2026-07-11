# shellcheck shell=bash

docker_dev_cmd_run() {
  local repo_root="$1"
  shift

  local image="u2604dev"
  local image_tag="latest"
  local workspace=""
  local mount_codex=0
  local mount_claude=0
  local do_build=0
  local do_pull=0
  local name=""

  while [ $# -gt 0 ]; do
    case "$1" in
      -i|--image) image="$2"; shift 2 ;;
      -w|--workspace) workspace="$2"; shift 2 ;;
      --mount-codex) mount_codex=1; shift ;;
      --mount-claude) mount_claude=1; shift ;;
      --build) do_build=1; shift ;;
      --pull) do_pull=1; shift ;;
      -n|--name) name="$2"; shift 2 ;;
      --no-interactive) DOCKER_DEV_INTERACTIVE=0; shift ;;
      -h|--help)
        cat <<'EOF'
Usage: cdev run [options]

Create and start an interactive dev container (zsh).

Options:
  -i, --image NAME     Image (u2204dev|u2404dev|u2604dev|u2604dev-opencode)
  -w, --workspace DIR  Host path mounted at /workspace (default: cwd)
  --mount-codex        Mount $HOME/.codex → /root/.codex
  --mount-claude       Mount $HOME/.claude → /root/.claude
  --build              Build image before run
  --pull               Pull from ghcr.io/luongnv89/IMAGE:latest
  -n, --name NAME      Container name (omit --rm behavior when set)
  --no-interactive     Skip prompts
  -h, --help           Show help
EOF
        return 0
        ;;
      *) usage_error "Unknown run option: $1" ;;
    esac
  done

  # shellcheck source=images.sh
  source "$(dirname "${BASH_SOURCE[0]}")/images.sh"
  docker_dev_validate_image "$image"
  require_cmd docker

  if [ "$do_pull" -eq 1 ] && [ "$do_build" -eq 1 ]; then
    usage_error "--pull and --build cannot be used together (local --build uses image:tag; --pull uses ghcr.io)"
  fi

  if [ "${DOCKER_DEV_INTERACTIVE:-1}" -eq 1 ] && [ -t 0 ] && [ -z "$workspace" ] \
    && [ "$mount_codex" -eq 0 ] && [ "$mount_claude" -eq 0 ]; then
    echo "◆ cdev run"
    echo "  Image: ${image}"
    prompt_yes_no "Mount Codex config from \$HOME/.codex?" y && mount_codex=1 || true
    prompt_yes_no "Mount Claude Code config from \$HOME/.claude?" y && mount_claude=1 || true
    if [ -z "$workspace" ]; then
      read -r -p "Workspace directory [${PWD}]: " ws || true
      workspace="${ws:-$PWD}"
    fi
    prompt_yes_no "Build image locally before run?" y && do_build=1 || true
  fi

  workspace="${workspace:-$PWD}"
  require_dir "Workspace" "$workspace"

  local local_tag="${image}:${image_tag}"
  local dockerfile="${repo_root}/${image}/Dockerfile"
  [ -f "$dockerfile" ] || die "Dockerfile not found: ${dockerfile}"

  if [ "$do_pull" -eq 1 ]; then
    log_info "Pulling ghcr.io/luongnv89/${image}:latest"
    docker pull "ghcr.io/luongnv89/${image}:latest" || die "Pull failed"
    local_tag="ghcr.io/luongnv89/${image}:latest"
  fi

  if [ "$do_build" -eq 1 ]; then
    docker_dev_cmd_build "$repo_root" --image "$image" --tag "$image_tag" || exit $?
  fi

  local volumes=(-v "${workspace}:/workspace")

  if [ "$mount_codex" -eq 1 ]; then
    local codex_home="${HOME}/.codex"
    [ -d "$codex_home" ] || die "Codex config directory missing: ${codex_home}"
    volumes+=(-v "${codex_home}:/root/.codex")
  fi

  if [ "$mount_claude" -eq 1 ]; then
    local claude_home="${HOME}/.claude"
    [ -d "$claude_home" ] || die "Claude config directory missing: ${claude_home}"
    volumes+=(-v "${claude_home}:/root/.claude")
  fi

  local run_args=(docker run --rm)
  if [ -n "$name" ]; then
    run_args=(docker run --name "$name")
  fi
  if [ -t 0 ] && [ -t 1 ]; then
    run_args+=(-it)
  fi
  run_args+=("${volumes[@]}" -w /workspace "$local_tag" zsh)

  [ "${DOCKER_DEV_QUIET:-0}" -eq 0 ] && {
    echo ""
    echo "◆ Starting container"
    echo "  Image:      ${local_tag}"
    echo "  Workspace:  ${workspace} → /workspace"
    [ "$mount_codex" -eq 1 ] && echo "  Codex:      \$HOME/.codex → /root/.codex"
    [ "$mount_claude" -eq 1 ] && echo "  Claude:     \$HOME/.claude → /root/.claude"
    echo ""
    log_verbose "Command: ${run_args[*]}"
    echo "  Shell:      zsh (exit to leave)"
    if [ -n "$name" ]; then
      echo "  Re-attach:  docker exec -it ${name} zsh"
      echo "  Stop:       docker stop ${name} && docker rm ${name}"
    fi
    echo ""
  }

  exec "${run_args[@]}"
}