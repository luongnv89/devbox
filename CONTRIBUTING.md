# Contributing to docker-dev

Thank you for your interest in contributing to docker-dev! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Adding a New Image](#adding-a-new-image)
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
- Build the u2604dev image to verify Dockerfile validity
- Clean up temporary files

### Building Images Locally

Build any image locally for testing:

```bash
# Build a specific image
docker build -t my-test -f u2604dev/Dockerfile .

# Run interactive shell
docker run --rm -it my-test zsh
```

### Testing Changes

Always test your changes by building the relevant image:

```bash
# Test u2604dev changes
docker build -t test-u2604dev -f u2604dev/Dockerfile .

# Test all images
for dir in u2204dev u2404dev u2604dev; do
  docker build -t "test-${dir}" -f "${dir}/Dockerfile" .
done
```

## Adding a New Image

To add a new development environment image:

1. Create a new directory following the naming convention:

```bash
mkdir -p uYYMMdev
```

2. Create a thin `Dockerfile` in the new directory (base tag, `UBUNTU_VERSION`, image-specific `.vimrc` / `starship.toml`); shared steps live in `common/dev-image-base.sh` and `common/install-python.sh`

3. Create a `README.md` with:
   - Image description
   - Features list
   - Build instructions
   - Usage instructions

4. Create configuration files:
   - `starship.toml` (if using Starship)
   - `.vimrc` (if using Vim)

5. Update the main `README.md` to include your new image

6. The CI/CD workflow will automatically detect and build the new image

## Pull Request Process

### Before Submitting

1. Ensure all pre-commit checks pass
2. Test your changes locally
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
feat(u2604dev): Add Python 3.13 support

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

## Bumping AI CLI versions

Dev images install global AI CLIs from `common/install-ai-tools.sh` with **explicit npm versions** so CI and sandbox builds stay reproducible.

When upgrading a CLI:

1. Check the latest version: `npm view <package-name> version`
2. Update the matching `*_VERSION` variable at the top of `common/install-ai-tools.sh`
3. Run `./scripts/pre-commit.sh` (includes a Docker build that runs the install script)
4. Note the bump in `CHANGELOG.md` under `[Unreleased]`

Packages pinned today:

| Variable | npm package |
|----------|-------------|
| `CLAUDE_CODE_VERSION` | `@anthropic-ai/claude-code` |
| `CODEX_VERSION` | `@openai/codex` |
| `OPENCODE_AI_VERSION` | `opencode-ai` |
| `PI_CODING_AGENT_VERSION` | `@mariozechner/pi-coding-agent` |
| `OPENCODE_WARP_VERSION` | `@warp-dot-dev/opencode-warp` |

`pi install npm:…` extensions and `herdr` / `pi-extensions` installers are not npm-pinned in this script; bump those when their upstream install docs change.

## Testing

### Automated Tests

The project includes:

- **Shell script linting**: ShellCheck
- **Dockerfile linting**: Hadolint
- **Docker build tests**: Building images in CI

### Manual Testing

Before submitting:

1. Run `./scripts/pre-commit.sh`
2. Build the modified image(s) locally
3. Verify the container starts and shell is accessible

## Documentation

### README Files

- Root `README.md`: Overview, quick start, available images
- Per-image `README.md`: Detailed documentation for each image

### Updating Documentation

When adding features:

1. Update relevant README files
2. Add examples if applicable
3. Update the CHANGELOG

## Questions?

- Check existing [Issues](../../issues)
- Open a new issue for bugs or feature requests
- Start a [Discussion](../../discussions) for questions
