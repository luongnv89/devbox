#!/usr/bin/env bash
# run_opencode.sh — run OpenCode non-interactively, sandboxed in a disposable
# luongnv89/docker-dev container. One process, one exit code: no TUI to drive,
# no readiness timing, no permission dialogs to click through.
#
# Usage:
#   run_opencode.sh --project DIR --message "task text" [options]
#
# Required:
#   --project DIR          local directory to mount read-write at /workspace
#   --message TEXT          prompt text passed to `opencode run`
#
# Optional:
#   --file PATH              host file to attach (mounted read-only, passed via opencode --file).
#                             For long/complex tasks: write them to a file, pass --file, and give
#                             a short --message like "Follow the attached file's instructions exactly."
#   --with-claude-skills      mount ~/.claude (and ~/.agents, for symlinked skills) read-only
#   --with-git-identity       mount ~/.gitconfig read-only, for correct commit authorship
#   --image IMAGE             docker image (default: ghcr.io/luongnv89/u2604dev:latest)
#   --format FORMAT           opencode output format: default | json (default: default)
#
# Never mounts ~/.ssh or injects a GH token/GH_TOKEN — see
# references/mounts-and-credentials.md for why, and what to do if a task
# genuinely needs push/publish access.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  grep '^#' "${BASH_SOURCE[0]}" | sed -e '1d' -e 's/^# \{0,1\}//'
}

IMAGE="ghcr.io/luongnv89/u2604dev:latest"
FORMAT="default"
PROJECT_DIR=""
MESSAGE=""
TASK_FILE=""
WITH_CLAUDE_SKILLS=0
WITH_GIT_IDENTITY=0

while [ $# -gt 0 ]; do
  case "$1" in
    --project|--message|--file|--image|--format)
      # A value-flag with nothing after it (e.g. a trailing `--message` with
      # no text) would make `shift 2` fail with bash's bare, unhelpful
      # "shift count out of range" — or under `set -e`, exit silently with no
      # message at all. Catch it here with a specific, actionable error.
      if [ $# -lt 2 ]; then
        echo "Error: '$1' requires a value but none was given. Run with --help for usage." >&2
        exit 1
      fi
      ;;
  esac
  case "$1" in
    --project) PROJECT_DIR="$2"; shift 2 ;;
    --message) MESSAGE="$2"; shift 2 ;;
    --file) TASK_FILE="$2"; shift 2 ;;
    --with-claude-skills) WITH_CLAUDE_SKILLS=1; shift ;;
    --with-git-identity) WITH_GIT_IDENTITY=1; shift ;;
    --image) IMAGE="$2"; shift 2 ;;
    --format) FORMAT="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Error: unknown argument '$1'. Run with --help for usage." >&2; exit 1 ;;
  esac
done

if [ -z "$PROJECT_DIR" ]; then
  echo "Error: --project DIR is required (the local project directory to mount at /workspace)." >&2
  exit 1
fi
if [ ! -d "$PROJECT_DIR" ]; then
  echo "Error: project directory '$PROJECT_DIR' does not exist." >&2
  exit 1
fi
if [ -z "$MESSAGE" ]; then
  echo "Error: --message TEXT is required (the prompt to send to OpenCode). For long/complex tasks, write them to a file and pass --file plus a short --message like \"Follow the attached file's instructions exactly.\"" >&2
  exit 1
fi
if [ -n "$TASK_FILE" ] && [ ! -f "$TASK_FILE" ]; then
  echo "Error: --file path '$TASK_FILE' does not exist." >&2
  exit 1
fi
case "$FORMAT" in
  default|json) ;;
  *) echo "Error: --format must be 'default' or 'json', got '$FORMAT'." >&2; exit 1 ;;
esac

PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

bash "$SCRIPT_DIR/preflight.sh" "$IMAGE"

MOUNTS=(-v "${PROJECT_DIR}:/workspace")

if [ -d "$HOME/.config/opencode" ]; then
  MOUNTS+=(-v "$HOME/.config/opencode:/root/.config/opencode")
else
  echo "Warning: $HOME/.config/opencode not found — the container will have no OpenCode auth/config and may prompt to log in. Run 'opencode' once on the host first if this task needs a real provider." >&2
fi

if [ "$WITH_CLAUDE_SKILLS" = "1" ]; then
  if [ -d "$HOME/.claude" ]; then
    MOUNTS+=(-v "$HOME/.claude:/root/.claude:ro")
    # ~/.claude/skills/<name> is frequently a symlink to ~/.agents/skills/<name>.
    # Mounting ~/.claude alone leaves that symlink dangling inside the
    # container (ls shows the entry, but reading the file 404s) — mount
    # ~/.agents too whenever it exists so skill files actually resolve.
    if [ -d "$HOME/.agents" ]; then
      MOUNTS+=(-v "$HOME/.agents:/root/.agents:ro")
    fi
  else
    echo "Warning: --with-claude-skills was requested but $HOME/.claude does not exist; skipping." >&2
  fi
fi

if [ "$WITH_GIT_IDENTITY" = "1" ]; then
  if [ -f "$HOME/.gitconfig" ]; then
    MOUNTS+=(-v "$HOME/.gitconfig:/root/.gitconfig:ro")
  else
    echo "Warning: --with-git-identity was requested but $HOME/.gitconfig does not exist; skipping." >&2
  fi
fi

OPENCODE_ARGS=(run "$MESSAGE")

SCRATCH_DIR=""
cleanup() {
  # NOTE: must be an `if`, not `[ -n "$SCRATCH_DIR" ] && rm ...` — under
  # `set -e`, a falsy short-circuit as the last command of an EXIT trap
  # clobbers the script's real exit status to 1, even on success.
  if [ -n "$SCRATCH_DIR" ]; then
    rm -rf "$SCRATCH_DIR"
  fi
}
trap cleanup EXIT

if [ -n "$TASK_FILE" ]; then
  SCRATCH_DIR="$(mktemp -d)"
  BASENAME="$(basename "$TASK_FILE")"
  cp "$TASK_FILE" "$SCRATCH_DIR/$BASENAME"
  MOUNTS+=(-v "${SCRATCH_DIR}:/scratch:ro")
  OPENCODE_ARGS+=("--file=/scratch/$BASENAME")
fi

OPENCODE_ARGS+=(--auto --format "$FORMAT")

echo "Running OpenCode in a disposable container (image: $IMAGE, workspace: $PROJECT_DIR)..." >&2
docker run --rm \
  "${MOUNTS[@]}" \
  -w /workspace \
  "$IMAGE" \
  opencode "${OPENCODE_ARGS[@]}"
