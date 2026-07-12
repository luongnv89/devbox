#!/usr/bin/env bash
# Validates: docs/development.md, CONTRIBUTING.md workflow
# Usage: validate-dev-environment.sh [--check] [--run-destructive]
set -uo pipefail

MODE="check"
[ "${1:-}" = "--run-destructive" ] && MODE="destructive"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
ok()   { printf '[CHECK] %-32s OK\n' "$1"; }
bad()  { printf '[CHECK] %-32s FAIL — %s\n' "$1" "$2"; fail=1; }
man()  { printf '[MANUAL] %-31s SKIPPED (run by operator)\n' "$1"; }

command -v git >/dev/null && ok "git on PATH" || bad "git on PATH" "install git"

# Pre-commit driver (scripts/pre-commit.sh:4-23)
[ -x "$ROOT/scripts/pre-commit.sh" ] && ok "scripts/pre-commit.sh" || bad "scripts/pre-commit.sh" "missing"

for df in u2204dev/Dockerfile u2404dev/Dockerfile u2604dev/Dockerfile; do
  [ -f "$ROOT/$df" ] && ok "$df present" || bad "$df present" "missing"
done

[ -f "$ROOT/.github/workflows/build-images.yml" ] && ok "build-images workflow" || bad "build-images workflow" "missing"

[ -f "$ROOT/common/dev-image-base.sh" ] && ok "common/dev-image-base.sh" || bad "common/dev-image-base.sh" "missing"

if command -v docker >/dev/null 2>&1; then
  ok "docker on PATH (optional for test.sh)"
else
  printf '[CHECK] %-32s WARN — test.sh skips image build\n' "docker on PATH"
fi

# Oh My Zsh / Docker CLI alignment (scripts/validate-ohmyzsh-plugins.sh)
if [ -x "$ROOT/scripts/validate-ohmyzsh-plugins.sh" ]; then
  if bash "$ROOT/scripts/validate-ohmyzsh-plugins.sh" >/dev/null 2>&1; then
    ok "validate-ohmyzsh-plugins.sh"
  else
    bad "validate-ohmyzsh-plugins.sh" "plugin/CLI regression"
  fi
fi

if [ "$MODE" = "destructive" ]; then
  man "./scripts/pre-commit.sh full run"
else
  man "./scripts/pre-commit.sh full run"
fi

exit $fail
