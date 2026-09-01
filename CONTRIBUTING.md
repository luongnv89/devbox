# Contributing to devbox

Thank you for your interest in contributing to devbox! This single-image repository builds one Ubuntu 26.04 dev container (`Dockerfile` at the repo root) and publishes it as `ghcr.io/luongnv89/devbox`.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Pull Request Process](#pull-request-process)
- [Code Style](#code-style)
- [Testing](#testing)
- [Documentation](#documentation)

## Getting Started

### Prerequisites

- Docker Desktop or Docker Engine
- Git
- A GitHub account

### Setting Up Your Development Environment

1. Fork the repository on GitHub

2. Clone your fork locally:

```bash
git clone https://github.com/YOUR-USERNAME/docker-dev.git
cd docker-dev
```

3. Add the original repository as upstream:

```bash
git remote add upstream https://github.com/luongnv89/docker-dev.git
```

4. Create a feature branch:

```bash
git checkout -b my-feature-branch
```

## Development Workflow

### Building the Image Locally

The single `Dockerfile` is self-contained and has no `COPY` dependency on legacy directories. It inlines `starship.toml`, `.vimrc`, shell extras, and the entrypoint, so the build context is minimal (`.dockerignore` excludes legacy `common/`/`u2604dev/` etc.). Always use the repository root as context:

```bash
# Default build (ai-full — opencode2, Claude, Codex, Pi, herdr)
docker build -t devbox .

# Strict verification (matches CI)
docker build --build-arg AI_VERIFY_MODE=strict -t devbox:strict .

# Alternative profiles (local only — CI publishes ai-full as :latest)
docker build --build-arg DEV_IMAGE_PROFILE=standard -t devbox:standard .
docker build --build-arg DEV_IMAGE_PROFILE=minimal -t devbox:minimal .
```

Run an interactive shell:

```bash
docker run --rm -it -v "$PWD":/workspace devbox zsh
# opencode2 inside: opencode2 --version (legacy `opencode` must be absent)
```

Non-root variant (avoids root-owned files on bind-mounted `/workspace`):

```bash
docker build --build-arg DEV_CREATE_NONROOT_USER=1 --build-arg DEV_UID="$(id -u)" --build-arg DEV_GID="$(id -g)" -t devbox:nonroot .
docker run --rm -it --user "$(id -u):$(id -g)" -v "$PWD":/workspace devbox:nonroot zsh
```

### Verifying Changes

Before committing:

```bash
# Syntax / lint (hadolint is optional locally; CI builds enforce it)
docker build -t devbox:verify --build-arg AI_VERIFY_MODE=strict .

# Inside the built image, verify parity with BASELINE-u2604dev.md:
docker run --rm devbox:verify bash -c 'cat /etc/os-release | grep VERSION_ID; whoami; echo $SHELL; pwd; opencode2 --version; pi --version'
docker run --rm -v "$PWD":/workspace devbox:verify bash -c 'ls -la /workspace | head'
```

## Pull Request Process

### Before Submitting

1. Test your changes locally via `docker build -t devbox .`
2. Update documentation as needed (`README.md`, this file, `SECURITY.md`)
3. Commit with clear messages
4. Ensure `docker build` shows the resolved `@opencode-ai/cli@beta` version and `opencode2 --version` succeeds; the old `opencode-ai` package must be absent (`npm list -g opencode-ai` shows nothing)

### Commit Message Format

```
<type>(<scope>): <description>

<body>

<footer>
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`.

Example:

```
feat(devbox): bump Node.js LTS

- Rebuild from new NodeSource setup_lts.x
- Verify opencode2 still present

Closes #123
```

### Submitting PRs

1. Push your feature branch to your fork
2. Open a PR against `main`
3. Fill in the PR template, link related issues
4. CI builds the root `Dockerfile` on pull requests without publishing; pushes to `main` publish `latest` + `sha` to GHCR as `ghcr.io/luongnv89/devbox`

## Code Style

### Dockerfiles

- Use Hadolint for linting
- Follow Dockerfile best practices:
  - Use specific base image tags (`ubuntu:26.04`)
  - Keep `ARG` for `DEV_IMAGE_PROFILE` / `AI_VERIFY_MODE` / `AI_TOOLS_CACHEBUST` in its own layer so AI changes do not invalidate base layers
  - Combine `RUN` statements to reduce layers; clean up `apt` metadata in the same layer
  - Prefer `COPY` only when not inlining — this repo's `Dockerfile` has **no** `COPY` from legacy dirs; keep it that way

### Shell Scripts

- Use `#!/usr/bin/env bash`, `set -euo pipefail`, ShellCheck, Google Shell Style Guide

### Markdown

- Consistent heading hierarchy, fenced code blocks with language tags

## Image Build Verify Modes (`AI_VERIFY_MODE`)

The single AI layer (after base setup) is validated per `AI_VERIFY_MODE`:

| Mode | When to use | Behavior |
|------|-------------|----------|
| `lenient` (default) | Local `docker build` | Hard-fail on missing core tools (`git`, `node`, `opencode2`, `pi`, …). For `ai-full`, missing `claude`/`codex` shims logs a note only (runtime mounts may supply them). Also fails if `opencode2` is missing or old `opencode-ai` is still installed. |
| `strict` | CI (`.github/workflows/devbox.yml`) | Same as lenient, plus `ai-full` fails if `claude` or `codex` is not on `PATH` after global install. CI also builds with `AI_TOOLS_CACHEBUST=$GITHUB_RUN_ID` so the AI layer is not stale. |

```bash
# Local strict check (matches CI):
docker build --build-arg AI_VERIFY_MODE=strict -t devbox:strict .
```

## Global npm Supply-Chain

- Images install AI CLIs at **npm `@latest`** (except `opencode2` which is `@opencode-ai/cli@beta`): `standard` → `opencode2`, `pi`, `asm`; `ai-full` → plus `claude`, `codex`, `herdr`, `pi-extensions`
- CI builds use `AI_TOOLS_CACHEBUST` so the AI layer is not served from a stale Docker cache
- Inside a running container, `update-ai-tools` upgrades the same set (plus re-installs `luongnv89/idd` + `luongnv89/skills` via `asm`)

## Testing

### Automated

- Dockerfile linting: Hadolint
- Docker build tests: CI builds the single devbox image on every PR/push
- Runtime parity: compare against `BASELINE-u2604dev.md` (Ubuntu 26.04, root, zsh, `/workspace`, entrypoint, dev/AI commands, `/root` files)

### Manual

Before submitting:

1. `docker build -t devbox .` succeeds from repository root
2. `docker run --rm devbox bash -c 'cat /etc/os-release | grep 26.04; whoami; echo $SHELL; opencode2 --version; which opencode && echo "old opencode should be absent" && exit 1 || echo "opencode absent ok"'`
3. Container starts and `zsh` is accessible; workspace mounts work (`-v "$PWD":/workspace`)

## Documentation

- `README.md`: devbox purpose, build/pull/run, mounts (`.agents`/`.claude`/`.codex`/`.pi`/OpenCode config, read-only `.ssh`), ports (`0.0.0.0`), warnings (root-owned files, credential mounts, Docker socket, floating beta pinning)
- This file: contributor workflow for the single root Dockerfile
- `SECURITY.md`: credential mounts, SSH keys, Docker socket, root execution, floating beta, image pinning
- `BASELINE-u2604dev.md`: pre-migration inventory for parity checks
- No `docs/` directory is maintained — the implementation is one `Dockerfile` + `.dockerignore` + workflow; documentation lives in the three files above

## Questions?

- Check existing [Issues](../../issues)
- Open a new issue for bugs or feature requests
- Start a [Discussion](../../discussions) for questions
