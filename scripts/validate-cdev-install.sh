#!/usr/bin/env bash
# Validates: README.md (cdev install), cli/README.md
# Usage: validate-cdev-install.sh [--check] [--run-destructive]
set -uo pipefail

MODE="check"
[ "${1:-}" = "--run-destructive" ] && MODE="destructive"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
ok()   { printf '[CHECK] %-32s OK\n' "$1"; }
bad()  { printf '[CHECK] %-32s FAIL — %s\n' "$1" "$2"; fail=1; }
man()  { printf '[MANUAL] %-31s SKIPPED (run by operator)\n' "$1"; }

# install.sh present (install.sh:1-3)
[ -f "$ROOT/install.sh" ] && ok "install.sh exists" || bad "install.sh exists" "missing"

# CLI entrypoint (install.sh:24-27)
[ -x "$ROOT/cli/bin/cdev" ] && ok "cli/bin/cdev executable" || bad "cli/bin/cdev executable" "missing or not +x"

# Wrapper installs DOCKER_DEV_REPO (install.sh:38-43)
grep -q 'DOCKER_DEV_REPO' "$ROOT/install.sh" 2>/dev/null \
  && ok "install.sh sets DOCKER_DEV_REPO" || bad "install.sh sets DOCKER_DEV_REPO" "pattern missing"

# Default prefix layout (install.sh:7-8)
grep -q 'DOCKER_DEV_PREFIX' "$ROOT/install.sh" 2>/dev/null \
  && ok "install.sh supports DOCKER_DEV_PREFIX" || bad "install.sh supports DOCKER_DEV_PREFIX" "pattern missing"

if [ "$MODE" = "destructive" ]; then
  echo "[RUN] Would run: curl ... | bash or ./install.sh (skipped in automation)"
  man "install.sh to host PREFIX"
else
  man "install.sh to host PREFIX"
fi

exit $fail
