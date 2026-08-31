# Contributing to docker-dev

Thank you for your interest in contributing to docker-dev! This document provides
guidelines and instructions for contributing to this single-root Dockerfile devbox
image project.

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

### Running Pre-commit Checks

Before committing, run the pre-commit checks:

```bash
./scripts/pre-commit.sh
```

This will:

- Format shell scripts with shfmt
- Lint shell scripts with ShellCheck
- Lint Dockerfiles with Hadolint
- Build the u2204dev image to verify Dockerfile validity
- Clean up temporary files

### Building Images Locally

Build the main devbox image locally for testing:

```bash
# Build the root Dockerfile (Ubuntu 26.04 dev image)
docker build -t my-devbox -f Dockerfile .

# Build the lean devbox image (Debian 13)
docker build -t my-devbox-debian -f devbox/Dockerfile .

# Run interactive shell
docker run --rm -it my-devbox zsh
```

### Testing Changes

Always test your changes by building the relevant image:

```bash
# Build and test the root Dockerfile
docker build -t test-devbox -f Dockerfile .

# Build and test the lean devbox image
docker build -t test-devbox-debian -f devbox/Dockerfile .

# Run a quick smoke test
docker run --rm -it test-devbox zsh -c 'echo "OK"'
```

## Pull Request Process

### Before Submitting

1. Ensure all pre-commit checks pass
2. Test your changes locally by building the image
3. Update documentation as needed
4. Commit your changes with clear commit messages

### Commit Message Format

```
<type>(<scope>): <description>

<body>

<footer>
```

Types:

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Formatting changes
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance

Example:

```
feat(devbox): Add Python 3.13 support

- Install Python 3.13 alongside existing Python versions
- Set Python 3.13 as default
- Add pip configuration

Closes #123
```

### Submitting PRs

1. Push your feature branch to your fork
2. Open a Pull Request against the `main` branch
3. Fill in the PR template completely
4. Link any related issues

## Code Style

### Shell Scripts

- Use `#!/usr/bin/env bash`
- Enable `set -euo pipefail`
- Use `shellcheck` for linting
- Follow Google Shell Style Guide

### Dockerfiles

- Use Hadolint for linting
- Follow Dockerfile best practices:
  - Use specific base image tags
  - Combine RUN statements to reduce layers
  - Clean up in the same layer
  - Use multi-stage builds when applicable

### Markdown

- Use consistent heading hierarchy
- Include code blocks with language tags
- Keep line width to 80 characters

## Image build verify modes (`AI_VERIFY_MODE`)

`common/install-ai-tools.sh` runs in a **dedicated Docker layer** (after apt/base
setup) so bumps to AI tooling do not invalidate cached base layers.

| Mode     | When to use                        | Behavior                                                                                         |
|----------|------------------------------------|--------------------------------------------------------------------------------------------------|
| `lenient` (default) | Local `docker build` | Hard-fail on missing core tools (`git`, `node`, `opencode`, `pi`, …). For **ai-full**, missing `claude` / `codex` on `PATH` after `npm install -g` logs a note only (runtime mounts may supply them). |
| `strict` | CI and release checks | Same as lenient, plus **ai-full** builds **fail** if `claude` or `codex` is not on `PATH` after global install. |

```bash
# Local strict check (matches CI):
docker build --build-arg AI_VERIFY_MODE=strict -f Dockerfile .
```

## Global npm supply-chain checks

- **CI:** `scripts/verify-ai-globals-audit.sh` runs on every workflow (resolves
  **latest** versions of the AI npm packages, prints the full `npm audit` report,
  and **fails on critical** severity). **High** findings are logged; they do not
  block the workflow. This covers **transitive npm vulnerabilities** in current
  latest AI CLIs; it does not replace Trivy.
- **Transient registry errors in CI:** occasional `auth.docker.io` 502 responses
  during `docker/build-push-action` are infrastructure flakes. Re-run failed
  matrix jobs (`gh run rerun <run-id> --failed`) rather than changing image code.
- **Images:** Published images on `main` are still scanned with **Trivy** (OS and
  installed packages in the image). Use both gates: audit at build time, Trivy
  after push.

## AI CLI versions (always latest)

Images install global AI CLIs from `common/install-ai-tools.sh` at **npm
`@latest`** (`standard`: OpenCode + Pi + `agent-skill-manager`; `ai-full`: also
Claude Code, Codex, pi-extensions, herdr). `minimal` skips AI npm CLIs but still
ships `/usr/local/bin/update-ai-tools`.

CI and `cdev build` pass `AI_TOOLS_CACHEBUST` so the AI layer is not served from
a stale Docker cache.

Inside a running container (as root or via sudo):

```bash
update-ai-tools
```

That upgrades the same package set as image build, re-runs `asm install` for
`github:luongnv89/idd` and `github:luongnv89/skills`, and is the way to silence
in-app "install new version" nags without rebuilding.

Packages (always `@latest`):

| Profile  | npm packages                                                        |
|----------|---------------------------------------------------------------------|
| `standard` | `opencode-ai`, `@mariozechner/pi-coding-agent`, `agent-skill-manager` |
| `ai-full`  | those plus `@anthropic-ai/claude-code`, `@openai/codex`             |

`pi install npm:…` extensions and `herdr` / `pi-extensions` installers follow
their upstream install scripts. Skills are installed with `asm` into
`~/.agents/skills` and linked into the CLIs the profile ships.

## Testing

### Automated Tests

The project includes:

- **Shell script linting**: ShellCheck
- **Dockerfile linting**: Hadolint
- **Docker build tests**: Building images in CI

### Manual Testing

Before submitting:

1. Run `./scripts/pre-commit.sh`
2. Build the modified image locally
3. Verify the container starts and shell is accessible

## Documentation

### README Files

- Root `README.md`: Overview, quick start, available images
- Per-image `README.md`: Detailed documentation for each image
- `docs/architecture.md`, `docs/development.md`: Cross-cutting layout and contributor setup
- `docs/DECISIONS.md`: Resolved doc ambiguities (append-only)

Validate contributor docs: `./scripts/validate-dev-environment.sh --check` (`docs/development.md`).

### Updating Documentation

When adding features:

1. Update relevant README files
2. Add examples if applicable
3. Update the CHANGELOG

## Questions?

- Check existing [Issues](https://github.com/luongnv89/docker-dev/issues)
- Open a new issue for bugs or feature requests
- Start a [Discussion](https://github.com/luongnv89/docker-dev/discussions) for questions
