# shellcheck shell=bash

# Named workflow presets for cdev run (issue #20).
# Explicit --mount-* flags passed on the CLI are OR'd with the preset (add mounts only).

docker_dev_preset_names() {
  printf '%s\n' ai full
}

docker_dev_validate_preset_name() {
  local name="$1"
  case "$name" in
    ai|full) return 0 ;;
    *)
      usage_error "Unknown preset: ${name} (choose: ai, full). See: cdev run --help"
      ;;
  esac
}

# Apply preset defaults to mount_* flags (1 = enable). Does not disable flags already set.
# Mount variables are owned by docker_dev_cmd_run in run.sh.
# shellcheck disable=SC2034
docker_dev_apply_run_preset() {
  local name="$1"
  docker_dev_validate_preset_name "$name"

  case "$name" in
    ai)
      mount_ssh=1
      mount_claude=1
      mount_codex=1
      mount_opencode=1
      mount_pi=1
      ;;
    full)
      mount_ssh=1
      mount_claude=1
      mount_codex=1
      mount_opencode=1
      mount_pi=1
      mount_docker_socket=1
      ;;
  esac
}

docker_dev_presets_help_text() {
  cat <<'EOF'
Presets (--preset NAME):
  ai     Workspace (default cwd) + SSH, Claude, Codex, OpenCode, Pi mounts
  full   Same as ai + host Docker socket (--mount-docker-socket)

Precedence: preset enables a baseline; any explicit --mount-* on the command line
also enables that mount. Presets do not provide --no-mount-* flags — omit --preset
for a minimal run. See README.md § Authentication for AI CLIs in the sandbox.
EOF
}