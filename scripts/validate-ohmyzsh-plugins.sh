#!/usr/bin/env bash
# Regression check: Oh My Zsh plugins must match installed CLIs (issue #8, #9).
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
expected='plugins=(git docker zsh-syntax-highlighting zsh-autosuggestions zsh-completions npm pip python)'
base="$root/common/dev-image-base.sh"
if grep -q 'plugins=.*kubectl' "$base"; then
    echo "FAIL: dev-image-base.sh lists kubectl in plugins= without kubectl CLI"
    fail=1
fi
if ! grep -qF "$expected" "$base"; then
    echo "FAIL: dev-image-base.sh missing expected plugins= sed line (common/dev-image-base.sh:115-116)"
    fail=1
fi
if ! grep -q 'install-docker-cli.sh' "$base"; then
    echo "FAIL: dev-image-base.sh does not invoke install-docker-cli.sh"
    fail=1
fi
devbox_zsh="$root/common/install-zsh-interactive.sh"
devbox_expected='plugins=(git zsh-syntax-highlighting zsh-autosuggestions zsh-completions)'
if [[ ! -f "$devbox_zsh" ]]; then
    echo "FAIL: common/install-zsh-interactive.sh is missing"
    fail=1
elif ! grep -qF "$devbox_expected" "$devbox_zsh"; then
    echo "FAIL: install-zsh-interactive.sh missing host-matching plugins= line"
    fail=1
elif grep -q 'plugins=.*docker' "$devbox_zsh"; then
    echo "FAIL: install-zsh-interactive.sh lists docker in plugins= without Docker CLI"
    fail=1
fi

for df in u2204dev/Dockerfile u2404dev/Dockerfile u2604dev/Dockerfile; do
    path="$root/$df"
    if grep -q 'plugins=.*kubectl' "$path"; then
        echo "FAIL: $df lists kubectl in plugins= without kubectl CLI"
        fail=1
    fi
    if ! grep -q 'dev-image-base.sh' "$path"; then
        echo "FAIL: $df does not run common/dev-image-base.sh"
        fail=1
    fi
done
if [ "$fail" -ne 0 ]; then
    exit 1
fi
echo "OK: Oh My Zsh plugins aligned across dev images"
