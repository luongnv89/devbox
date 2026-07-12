#!/usr/bin/env bash
# Regression check: Oh My Zsh plugins must match installed CLIs (issue #8, #9).
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
expected='plugins=(git docker zsh-syntax-highlighting zsh-autosuggestions zsh-completions npm pip python)'
for df in u2204dev/Dockerfile u2404dev/Dockerfile u2604dev/Dockerfile; do
  path="$root/$df"
  if grep -q 'plugins=.*kubectl' "$path"; then
    echo "FAIL: $df lists kubectl in plugins= without kubectl CLI"
    fail=1
  fi
  if ! grep -qF "$expected" "$path"; then
    echo "FAIL: $df missing expected plugins= line"
    fail=1
  fi
  if ! grep -q 'install-docker-cli.sh' "$path"; then
    echo "FAIL: $df does not install Docker CLI (issue #9)"
    fail=1
  fi
done
if [ "$fail" -ne 0 ]; then
  exit 1
fi
echo "OK: Oh My Zsh plugins aligned across dev images"