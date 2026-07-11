# shellcheck shell=bash

docker_dev_cmd_config() {
  local repo_root="$1"
  shift

  local format="text"
  while [ $# -gt 0 ]; do
    case "$1" in
      --format) format="$2"; shift 2 ;;
      -h|--help)
        echo "Usage: cdev config [--format text|json]"
        return 0
        ;;
      *) usage_error "Unknown config option: $1" ;;
    esac
  done

  case "$format" in
    json)
      cat <<EOF
{
  "repo": "${repo_root}",
  "workspace_default": "${PWD}",
  "mounts": {
    "codex": "${HOME}/.codex",
    "claude": "${HOME}/.claude",
    "workspace_container": "/workspace"
  },
  "registry": "ghcr.io/luongnv89"
}
EOF
      ;;
    text)
      echo "cdev configuration"
      echo "  Repo root:     ${repo_root}"
      echo "  Registry:      ghcr.io/luongnv89/<image>:latest"
      echo "  Workspace:     host path → /workspace"
      echo "  Codex mount:   ${HOME}/.codex → /root/.codex"
      echo "  Claude mount:  ${HOME}/.claude → /root/.claude"
      echo "  Override repo: export CDEV_REPO=/path/to/docker-dev"
      ;;
    *)
      usage_error "Unknown format: ${format}"
      ;;
  esac
}