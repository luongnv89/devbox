# shellcheck shell=bash

docker_dev_cmd_run() {
  local repo_root="$1"
  shift

  local image="u2604dev"
  local image_tag="latest"
  local workspace=""
  local mount_codex=0
  local mount_claude=0
  local mount_ssh=0
  local mount_opencode=0
  local mount_pi=0
  local mount_docker_socket=0
  local do_build=0
  local do_pull=0
  local name=""

  while [ $# -gt 0 ]; do
    case "$1" in
      -i|--image) image="$2"; shift 2 ;;
      -w|--workspace) workspace="$2"; shift 2 ;;
      --mount-codex) mount_codex=1; shift ;;
      --mount-claude) mount_claude=1; shift ;;
      --mount-ssh) mount_ssh=1; shift ;;
      --mount-opencode) mount_opencode=1; shift ;;
      --mount-pi) mount_pi=1; shift ;;
      --mount-docker-socket) mount_docker_socket=1; shift ;;
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
  --mount-ssh          Mount $HOME/.ssh → /root/.ssh (read-only)
  --mount-opencode     Mount $HOME/.config/opencode → /root/.config/opencode
  --mount-pi           Mount $HOME/.pi → /root/.pi when present on host
  --mount-docker-socket
                       Mount host Docker socket (/var/run/docker.sock) so the
                       in-container docker CLI talks to the host daemon.
                       Grants container processes host-level Docker API access.
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
    && [ "$mount_codex" -eq 0 ] && [ "$mount_claude" -eq 0 ] \
    && [ "$mount_ssh" -eq 0 ] && [ "$mount_opencode" -eq 0 ] && [ "$mount_pi" -eq 0 ] \
    && [ "$mount_docker_socket" -eq 0 ]; then
    echo "◆ cdev run"
    echo "  Image: ${image}"
    prompt_yes_no "Mount Codex config from \$HOME/.codex?" y && mount_codex=1 || true
    prompt_yes_no "Mount Claude Code config from \$HOME/.claude?" y && mount_claude=1 || true
    prompt_yes_no "Mount SSH config from \$HOME/.ssh (read-only)?" y && mount_ssh=1 || true
    prompt_yes_no "Mount OpenCode config from \$HOME/.config/opencode?" y && mount_opencode=1 || true
    prompt_yes_no "Mount Pi agent config from \$HOME/.pi (when present)?" y && mount_pi=1 || true
    prompt_yes_no "Mount host Docker socket (docker CLI in image → host daemon)?" n && mount_docker_socket=1 || true
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

  if [ "$mount_ssh" -eq 1 ]; then
    local ssh_home="${HOME}/.ssh"
    [ -d "$ssh_home" ] || die "SSH directory missing: ${ssh_home}"
    docker_dev_dir_has_content "$ssh_home" || die "SSH directory is empty: ${ssh_home}"
    volumes+=(-v "${ssh_home}:/root/.ssh:ro")
  fi

  if [ "$mount_opencode" -eq 1 ]; then
    local opencode_home="${HOME}/.config/opencode"
    [ -d "$opencode_home" ] || die "OpenCode config directory missing: ${opencode_home}"
    docker_dev_dir_has_content "$opencode_home" || die "OpenCode config directory is empty: ${opencode_home}"
    volumes+=(-v "${opencode_home}:/root/.config/opencode")
  fi

  if [ "$mount_docker_socket" -eq 1 ]; then
    local sock="/var/run/docker.sock"
    [ -S "$sock" ] || die "Docker socket not found: ${sock} (is Docker running on the host?)"
    volumes+=(-v "${sock}:/var/run/docker.sock")
  fi

  local pi_mounted=0
  if [ "$mount_pi" -eq 1 ]; then
    local pi_home="${HOME}/.pi"
    if docker_dev_dir_has_content "$pi_home"; then
      volumes+=(-v "${pi_home}:/root/.pi")
      pi_mounted=1
    else
      log_verbose "Pi config not found at ${pi_home} (optional, skipping)"
    fi
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
    [ "$mount_ssh" -eq 1 ] && echo "  SSH:        \$HOME/.ssh → /root/.ssh (ro)"
    [ "$mount_opencode" -eq 1 ] && echo "  OpenCode:   \$HOME/.config/opencode → /root/.config/opencode"
    [ "$pi_mounted" -eq 1 ] && echo "  Pi:         \$HOME/.pi → /root/.pi"
    [ "$mount_docker_socket" -eq 1 ] && echo "  Docker:     /var/run/docker.sock (host daemon — privileged)"
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