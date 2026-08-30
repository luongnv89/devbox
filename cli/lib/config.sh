# shellcheck shell=bash

# Escape a string for JSON double-quoted value (no surrounding quotes).
_docker_dev_json_escape() {
    local s="$1" out="" i c
    for ((i = 0; i < ${#s}; i++)); do
        c="${s:i:1}"
        case "$c" in
        $'\\') out+='\\' ;;
        '"') out+='\"' ;;
        $'\n') out+='\n' ;;
        $'\r') out+='\r' ;;
        $'\t') out+='\t' ;;
        *) out+="$c" ;;
        esac
    done
    printf '%s' "$out"
}

docker_dev_cmd_config() {
    local repo_root="$1"
    shift

    local format="text"
    while [ $# -gt 0 ]; do
        case "$1" in
        --format)
            format="$2"
            shift 2
            ;;
        -h | --help)
            echo "Usage: cdev config [--format text|json]"
            return 0
            ;;
        *) usage_error "Unknown config option: $1" ;;
        esac
    done

    case "$format" in
    json)
        local jr jw jc jl
        jr="$(_docker_dev_json_escape "$repo_root")"
        jw="$(_docker_dev_json_escape "$PWD")"
        jc="$(_docker_dev_json_escape "${HOME}/.codex")"
        jl="$(_docker_dev_json_escape "${HOME}/.claude")"
        js="$(_docker_dev_json_escape "${HOME}/.ssh")"
        jo="$(_docker_dev_json_escape "${HOME}/.config/opencode")"
        jp="$(_docker_dev_json_escape "${HOME}/.pi")"
        cat <<EOF
{
  "repo": "${jr}",
  "workspace_default": "${jw}",
  "mounts": {
    "ssh": "${js}",
    "codex": "${jc}",
    "claude": "${jl}",
    "opencode": "${jo}",
    "pi": "${jp}",
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
        echo "  SSH mount:     ${HOME}/.ssh → /root/.ssh (ro with --mount-ssh)"
        echo "  Codex mount:   ${HOME}/.codex → /root/.codex"
        echo "  Claude mount:  ${HOME}/.claude → /root/.claude"
        echo "  OpenCode:      ${HOME}/.config/opencode → /root/.config/opencode"
        echo "  Pi mount:      ${HOME}/.pi → /root/.pi (when present)"
        echo "  Override repo: export CDEV_REPO=/path/to/docker-dev"
        ;;
    *)
        usage_error "Unknown format: ${format}"
        ;;
    esac
}
