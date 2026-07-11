#!/usr/bin/env bash
# Regression check for issue #8: Oh My Zsh plugins must match installed CLIs.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
for df in u2204dev/Dockerfile u2404dev/Dockerfile u2604dev/Dockerfile; do
  path="$root/$df"
  if grep -q 'plugins=.*docker\|plugins=.*kubectl' "$path"; then
    echo "FAIL: $df still lists docker/kubectl in plugins="
    fail=1
  fi
  if ! grep -q 'plugins=(git zsh-syntax-highlighting zsh-autosuggestions zsh-completions npm pip python)' "$path"; then
    echo "FAIL: $df missing expected plugins= line"
    fail=1
  fi
done
if [ "$fail" -ne 0 ]; then
  exit 1
fi
echo "OK: Oh My Zsh plugins aligned across dev images"