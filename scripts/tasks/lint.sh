#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

lint_shell() {
    local files=("$@")
    if [[ ${#files[@]} -eq 0 ]]; then
        echo "No shell scripts to lint."
        return 0
    fi

    if command -v shellcheck >/dev/null 2>&1; then
        shellcheck --severity=warning "${files[@]}"
        echo "Shell scripts linted with shellcheck."
    elif command -v docker >/dev/null 2>&1; then
        docker run --rm -v "$ROOT_DIR":/work -w /work koalaman/shellcheck:stable shellcheck --severity=warning "${files[@]/$ROOT_DIR\//}"
        echo "Shell scripts linted with Dockerized shellcheck."
    else
        echo "shellcheck not available locally or via Docker. Skipping shell lint." >&2
    fi
}

lint_zsh() {
    local files=("$@")
    if [[ ${#files[@]} -eq 0 ]]; then
        return 0
    fi

    if command -v zsh >/dev/null 2>&1; then
        zsh -n "${files[@]}"
        echo "Zsh scripts checked with zsh -n."
    else
        echo "zsh not available; skipping zsh syntax checks." >&2
    fi
}

lint_dockerfiles() {
    local dockerfiles=("$@")
    if [[ ${#dockerfiles[@]} -eq 0 ]]; then
        echo "No Dockerfiles to lint."
        return 0
    fi

    if command -v hadolint >/dev/null 2>&1; then
        for file in "${dockerfiles[@]}"; do
            if [[ "$file" == "$ROOT_DIR/u2604dev-opencode/Dockerfile" ]]; then
                hadolint --ignore DL3007 "$file"
            else
                hadolint "$file"
            fi
        done
        echo "Dockerfiles linted with hadolint."
    elif command -v docker >/dev/null 2>&1; then
        for file in "${dockerfiles[@]}"; do
            if [[ "$file" == "$ROOT_DIR/u2604dev-opencode/Dockerfile" ]]; then
                docker run --rm -i hadolint/hadolint hadolint --ignore DL3007 - <"$file"
            else
                docker run --rm -i hadolint/hadolint hadolint - <"$file"
            fi
        done
        echo "Dockerfiles linted with Dockerized hadolint."
    else
        echo "hadolint not available locally or via Docker. Skipping Dockerfile lint." >&2
    fi
}

SH_FILES=()
ZSH_FILES=()
while IFS= read -r file; do
    IFS= read -r first_line <"$file" || true
    if [[ "$first_line" == *zsh* ]]; then
        ZSH_FILES+=("$file")
    else
        SH_FILES+=("$file")
    fi
done < <(find "$ROOT_DIR" -path "$ROOT_DIR/.git" -prune -o -type f -name "*.sh" -print)
readarray -t DOCKERFILES < <(find "$ROOT_DIR" -type f -name "Dockerfile")

lint_shell "${SH_FILES[@]}"
lint_zsh "${ZSH_FILES[@]}"
lint_dockerfiles "${DOCKERFILES[@]}"
