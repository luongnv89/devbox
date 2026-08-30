# Documentation decisions log

Append-only record of ambiguities resolved while reconciling docs to the codebase.

## 2026-07-12

- Q: Per-image READMEs state “Docker CLI and kubectl are not installed”; root README says Docker CLI is included. Which is correct?
- A (code audit): **Docker CLI** (client) is installed via `common/install-docker-cli.sh` from `common/dev-image-base.sh` (`common/install-docker-cli.sh:6-15`, `common/dev-image-base.sh:57-58`). **kubectl** is not installed; theme files only show context if `kubectl` exists on PATH (`u2604dev/wedisagree.zsh-theme:129-130`).
- Source: `common/install-docker-cli.sh`, `scripts/validate-ohmyzsh-plugins.sh:17-19`

- Q: CI/CD section says “Builds all 4 images”; workflow only lists three GHCR images.
- A (code audit): CI publishes **u2204dev**, **u2404dev**, and **u2604dev** only (`README.md` table aligns with `.github/workflows/build-images.yml:60-72`). `u2604dev-opencode` is deprecated and not in the matrix.
- Source: `.github/workflows/build-images.yml`

- Q: Per-image “Contributing” build examples use wrong Docker context (`… Dockerfile u2604dev`).
- A (code audit): Build context must be **repository root** so `COPY common/…` resolves (`u2604dev/Dockerfile:9-14`, root `README.md` local build example).
- Source: `u2604dev/Dockerfile`

## 2026-08-30

- Q: Which image should power sandboxed OpenCode tasks without changing Ubuntu installers?
- A (code audit): `devbox` uses `debian:13-slim` with a Debian-specific lean toolchain and keeps glibc/apt compatibility. The existing Ubuntu images remain available for the full shell/CLI stack.
- Source: `devbox/Dockerfile`, `common/install-devbox-base.sh`, `README.md`

- Q: How should the new image be published and selected by `cdev`?
- A (code audit): Publish `devbox` across the same `ai-full`, `standard`, and `minimal` profile tags; default `devbox` to `standard` while preserving `ai-full` as the Ubuntu default.
- Source: `.github/workflows/build-images.yml`, `cli/lib/images.sh`, `cli/lib/profiles.sh`
