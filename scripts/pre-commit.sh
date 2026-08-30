#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TASK_DIR="$ROOT_DIR/scripts/tasks"

run_step() {
    local label="$1"
    shift
    echo "==> ${label}"
    if "$@"; then
        echo "✔ ${label} completed"
    else
        echo "✖ ${label} failed" >&2
        exit 1
    fi
    echo
}

run_step "Format" "$TASK_DIR/format.sh"
run_step "Lint" "$TASK_DIR/lint.sh"
run_step "Test" "$TASK_DIR/test.sh"
run_step "Cleanup" "$TASK_DIR/cleanup.sh"

echo "All pre-commit checks passed."
