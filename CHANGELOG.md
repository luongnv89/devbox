# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **`update-ai-tools`** in every image (`/usr/local/bin/update-ai-tools`) to upgrade OpenCode, Pi, Claude Code, Codex, pi-extensions, herdr, asm, and baked skill repos without rebuilding
- **`devbox`** Debian 13 slim image for sandboxed OpenCode tasks, with a lean
  development toolchain and the existing `standard` / `ai-full` profiles
- **`AI_REQUIRED_COMMANDS`** override for profile verification so lean images
  can validate only the commands they install
- **`AI_VERIFY_MODE`** (`lenient` / `strict`) for `common/install-ai-tools.sh`; CI builds use `strict`
- **`scripts/verify-ai-globals-audit.sh`** and CI job **npm audit (latest AI globals)** for supply-chain checks on current latest AI npm packages
- **Dockerfile layer split**: AI npm install in a separate `RUN` after apt/base (`install-ai-tools.sh` no longer invoked from `dev-image-base.sh`)
- **Corepack** enabled in dev images for pnpm/Yarn; documented in README and shell welcome
- **`common/install-uv.sh`** — Astral uv for fast Python venvs alongside distro `python3 -m venv`
- **`cdev run --preset`** — `ai` and `full` workflow presets; documented in `cdev run --help`, root README, and `cli/README.md`
- **Sandbox authentication docs** — README and `cli/README.md` sections for AI CLI credentials, mount paths, and env vars (placeholders only)
- `cli/lib/presets.sh` — preset definitions; interactive mount prompts reference auth docs when declined
- **Optional non-root `dev` user** for bind-mount sandboxes: `DEV_CREATE_NONROOT_USER`, `DEV_UID`, `DEV_GID` build args; `common/setup-dev-user.sh`; `cdev build|run --nonroot`; default `WORKDIR /workspace`
- **Build profiles** for dev images (`minimal`, `standard`, `ai-full`): `DEV_IMAGE_PROFILE` build arg, branched `common/install-ai-tools.sh`, GHCR tags `latest` / `latest-standard` / `latest-minimal`, `cdev build|run --profile`
- `cli/lib/profiles.sh` — profile validation and image tag mapping
- `common/install-docker-cli.sh` — Docker CLI (client) in dev images; optional `docker-compose-v2` when available on the base
- `cdev run --mount-docker-socket` — bind host `/var/run/docker.sock` for in-container compose workflows
- Base Ubuntu images (`u2204dev`, `u2404dev`, `u2604dev`): jq, tzdata, fzf, fd-find (`fd` symlink), GitHub CLI (`gh`), shared `shell-cli-extras.zsh` (fzf key bindings)
- `common/install-gh-cli.sh` — install `gh` from GitHub’s apt repository
- `common/install-ai-tools.sh` — shared image install for Claude Code, Codex, OpenCode, Pi, and `luongnv89/pi-extensions` (opencode-pi, statusline-pi, themes)
- `common/entrypoint-dev.sh` — optional mount notices for workspace and AI config dirs
- `cdev run` flags `--mount-ssh`, `--mount-opencode`, `--mount-pi` (optional Pi when host dir exists)
- `cdev` CLI (`cli/bin/cdev`) — `run`, `build`, `list`, `config`
- `install.sh` — installs host `cdev` via `curl | bash` (default ref: `main`)
- Dev images: [herdr](https://herdr.dev/) via `common/install-ai-tools.sh`
- `scripts/docker-dev` — deprecated wrapper to `cdev`

### Changed

- **CI** publishes only **u2604dev** and **devbox** at the **ai-full** profile (12-job matrix reduced to 2) to speed image builds; `u2204dev`, `u2404dev`, `standard`, and `minimal` remain local `cdev build` / `docker build`
- **`common/install-ai-tools.sh`:** install global AI npm CLIs at `@latest` instead of pinned versions; drop Warp; add `agent-skill-manager` (`asm`) and bake [`luongnv89/idd`](https://github.com/luongnv89/idd) + [`luongnv89/skills`](https://github.com/luongnv89/skills) via `asm`; CI/`cdev build` pass `AI_TOOLS_CACHEBUST` so that layer is not served from a stale cache
- **CONTRIBUTING.md:** document tracked high npm advisories on pinned `pi-coding-agent` and CI recovery for transient Docker Hub auth 502s
- Ubuntu dev Dockerfiles (`u2204dev`, `u2404dev`, `u2604dev`) retain the shared Ubuntu installers; `devbox` uses a Debian-specific lean installer and reuses compatible runtime/profile steps

- **Deprecated `u2604dev-opencode` as a first-class image.** OpenCode and other AI tooling already ship in `u2604dev` (and other base images). `cdev list` shows the four first-class images; `cdev run` / `cdev build` accept `--image u2604dev-opencode` as an alias to `u2604dev` with a migration hint. CI publishes `u2604dev` and `devbox` at `ai-full` only. Migration: `cdev run --image u2604dev --mount-opencode --mount-pi`.
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
