# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **`cdev run --preset`** — `ai` and `full` workflow presets; documented in `cdev run --help`, root README, and `cli/README.md`
- **Sandbox authentication docs** — README and `cli/README.md` sections for AI CLI credentials, mount paths, and env vars (placeholders only)
- `cli/lib/presets.sh` — preset definitions; interactive mount prompts reference auth docs when declined
- **Optional non-root `dev` user** for bind-mount sandboxes: `DEV_CREATE_NONROOT_USER`, `DEV_UID`, `DEV_GID` build args; `common/setup-dev-user.sh`; `cdev build|run --nonroot`; default `WORKDIR /workspace`
- **Build profiles** for dev images (`minimal`, `standard`, `ai-full`): `DEV_IMAGE_PROFILE` build arg, branched `common/install-ai-tools.sh`, GHCR tags `latest` / `latest-standard` / `latest-minimal`, `cdev build|run --profile`
- `cli/lib/profiles.sh` — profile validation and image tag mapping
- `common/install-docker-cli.sh` — Docker CLI (client) in dev images; optional `docker-compose-v2` when available on the base
- `cdev run --mount-docker-socket` — bind host `/var/run/docker.sock` for in-container compose workflows
- Base dev images (`u2204dev`, `u2404dev`, `u2604dev`): jq, tzdata, fzf, fd-find (`fd` symlink), GitHub CLI (`gh`), shared `shell-cli-extras.zsh` (fzf key bindings)
- `common/install-gh-cli.sh` — install `gh` from GitHub’s apt repository
- `common/install-ai-tools.sh` — shared image install for Claude Code, Codex, OpenCode, Pi, and `luongnv89/pi-extensions` (opencode-pi, statusline-pi, themes)
- `common/entrypoint-dev.sh` — optional mount notices for workspace and AI config dirs
- `cdev run` flags `--mount-ssh`, `--mount-opencode`, `--mount-pi` (optional Pi when host dir exists)
- `cdev` CLI (`cli/bin/cdev`) — `run`, `build`, `list`, `config`
- `install.sh` — installs host `cdev` via `curl | bash` (default ref: `main`)
- Dev images: [herdr](https://herdr.dev/) via `common/install-ai-tools.sh`
- `scripts/docker-dev` — deprecated wrapper to `cdev`

### Changed

- Ubuntu dev Dockerfiles (`u2204dev`, `u2404dev`, `u2604dev`): shared build logic in `common/dev-image-base.sh` and `common/install-python.sh`; per-image Dockerfiles only set base tag and copy image-specific shell/editor config

- **Deprecated `u2604dev-opencode` as a first-class image.** OpenCode and other AI tooling already ship in `u2604dev` (and other base images). `cdev list` shows three images only; `cdev run` / `cdev build` accept `--image u2604dev-opencode` as an alias to `u2604dev` with a migration hint. CI matrix unchanged (never built opencode). Migration: `cdev run --image u2604dev --mount-opencode --mount-pi`.
- `common/install-ai-tools.sh`: pin global npm AI CLI versions; see CONTRIBUTING for bump process
- `u2204dev`, `u2404dev`, `u2604dev` Dockerfiles: repo-root build context, AI tooling baked in, shared entrypoint; Oh My Zsh `docker` plugin re-enabled with installed CLI
- CI and pre-commit test builds use repository root as Docker build context
- README: document `docker-dev` CLI and fix obsolete docker compose instructions

## [1.0.0] - 2026-01-11

### Added

- Initial release of docker-dev project
- Three Ubuntu-based development environment images:
  - **u2204dev**: Ubuntu 22.04 with Oh My Zsh, wedisagree theme, Vim plugins
  - **u2404dev**: Ubuntu 24.04 with Oh My Zsh, Starship prompt, Vim plugins
  - **u2604dev**: Ubuntu 26.04 with Oh My Zsh, Starship prompt, Vim plugins
- GitHub Actions CI/CD workflow for automated builds
- Pre-commit hook system with:
  - Shell script formatting (shfmt)
  - Shell script linting (ShellCheck)
  - Dockerfile linting (Hadolint)
  - Docker build verification
- Common development tools across all images:
  - Git, Vim, curl, wget, zsh
  - Node.js (LTS) and npm
  - Python with pip
  - ripgrep, bat, btop
  - JetBrains Mono Nerd Font
- Oh My Zsh with plugins:
  - zsh-syntax-highlighting
  - zsh-autosuggestions
  - zsh-completions
- Custom shell aliases and configurations

### Features

- Multi-architecture support (linux/amd64, linux/arm64)
- GitHub Container Registry publishing
- Automated security scanning with Trivy
- Artifact attestation for provenance

### Documentation

- Root README with image overview and quick start
- Per-image README files with detailed documentation
- CONTRIBUTING guide for contributors

### Infrastructure

- MIT License
- GitHub Actions workflows
- Pre-commit hook system
