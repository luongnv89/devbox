<p align="center"><img src="logo.png" alt="docker-dev Logo" width="400"></p>

# docker-dev

[![Build and Publish](https://github.com/luongnv89/docker-dev/actions/workflows/build-images.yml/badge.svg)](https://github.com/luongnv89/docker-dev/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/luongnv89/docker-dev)](https://github.com/luongnv89/docker-dev/stargazers)

Curated Docker images for different development environments. Each image lives in its own directory (e.g., `u2204dev/`) with a dedicated Dockerfile and per-image README describing that environment.

## Features

- **Multi-Platform Support**: Builds for linux/amd64 and linux/arm64 (M-series Macs, ARM servers)
- **Automated CI/CD**: GitHub Actions builds and publishes to GitHub Container Registry
- **Security Scanned**: Images are scanned with Trivy for vulnerabilities
- **Pre-commit Hooks**: Automated formatting, linting, and testing on every commit
- **Production Ready**: Artifact attestation for image provenance
- **Coding-ready images**: git, vim, zsh, Starship, jq, fzf, fd, gh, **Docker CLI** (client only), tzdata (`TZ=Etc/UTC`, overridable), Node.js LTS with **Corepack** (pnpm/yarn), **uv** for Python envs, OpenCode, Pi (+ `luongnv89/pi-extensions`), Claude Code & Codex npm CLIs
- **`cdev` CLI**: Interactive launcher with optional workspace, SSH, OpenCode, Pi, `~/.codex`, and `~/.claude` mounts

## Available Images

| Folder | Description | Docs |
|--------|-------------|------|
| `u2604dev/` | Ubuntu 26.04 CLI/dev environment with Oh My Zsh, Starship prompt, Vim plugins, Node.js LTS, Python 3.13, etc. | [u2604dev/README.md](u2604dev/README.md) |
| `u2404dev/` | Ubuntu 24.04 CLI/dev environment with Oh My Zsh, Starship prompt, Vim plugins, Node.js LTS, Python 3.12, etc. | [u2404dev/README.md](u2404dev/README.md) |
| `u2204dev/` | Ubuntu 22.04 CLI/dev environment with Oh My Zsh, wedisagree theme, Vim plugins, Node.js, Python 3.12, etc. | [u2204dev/README.md](u2204dev/README.md) |

CI publishes **u2204dev**, **u2404dev**, and **u2604dev** only (see [.github/workflows/build-images.yml](.github/workflows/build-images.yml)). Each image is built in three **profiles** (build arg `DEV_IMAGE_PROFILE`):

| Profile | GHCR tag | AI tooling |
|---------|----------|------------|
| `ai-full` (default) | `:latest` | Claude Code, Codex, OpenCode, Pi, pi-extensions, herdr |
| `standard` | `:latest-standard` | OpenCode, Pi (+ npm pi extensions) |
| `minimal` | `:latest-minimal` | None (terminal, Node, Python, vim, zsh only) |

Use `cdev build --profile minimal` or `cdev run --pull --profile standard` to select a profile locally.

**Migration from `u2604dev-opencode`:** use `cdev run --image u2604dev` with `--mount-opencode` and `--mount-pi`. The legacy name still resolves to `u2604dev` with a deprecation notice. Optional local Dockerfile: [u2604dev-opencode/README.md](u2604dev-opencode/README.md).

> As new images are added, follow the same pattern: create `<image-name>/Dockerfile`, add a `<image-name>/README.md`, and update this table.

## Quick Start

### Pull and Run

Authenticate with GitHub Container Registry:
```bash
echo "${GH_PAT}" | docker login ghcr.io -u <your-github-username> --password-stdin
```

Pull an image:
```bash
docker pull ghcr.io/luongnv89/u2604dev:latest
```

Run the container:
```bash
docker run --rm -it ghcr.io/luongnv89/u2604dev:latest zsh
```

### Build Locally

Build a specific image (context is repo root so `common/` scripts are included):
```bash
docker build -t my-dev-env -f u2604dev/Dockerfile .
# Smaller image without global AI npm CLIs:
docker build --build-arg DEV_IMAGE_PROFILE=minimal -t my-dev-env:minimal -f u2604dev/Dockerfile .
```

Run locally built image:
```bash
docker run --rm -it -v "$PWD":/workspace my-dev-env zsh
```

#### Non-root sandbox (bind-mount friendly)

By default containers start as **root**, which can leave root-owned files on bind-mounted `/workspace`. Opt in at **build** time with `DEV_CREATE_NONROOT_USER=1` (creates user `dev`, passwordless `sudo`, default `WORKDIR /workspace`):

```bash
docker build \
  --build-arg DEV_CREATE_NONROOT_USER=1 \
  --build-arg DEV_UID="$(id -u)" --build-arg DEV_GID="$(id -g)" \
  -t my-dev-env:nonroot -f u2604dev/Dockerfile .
docker run --rm -it --user "$(id -u):$(id -g)" -v "$PWD":/workspace my-dev-env:nonroot zsh
```

With **`cdev`**: `cdev build --nonroot` then `cdev run --nonroot --build` (build passes your host uid/gid; run uses `--user` and mounts AI/SSH config under `/home/dev`). Published GHCR `:latest` images remain root-by-default; non-root is a local or custom-registry build.

### Using the `cdev` CLI (recommended)

**One-line install** — installs **`cdev`** to `~/.local/bin` and clones the images repo to `~/.local/share/docker-dev`. **[herdr](https://herdr.dev/)** is installed inside dev images:
```bash
curl -fsSL https://raw.githubusercontent.com/luongnv89/docker-dev/main/install.sh | bash
```

From a clone:
```bash
./install.sh
```

Ensure `~/.local/bin` is on your `PATH`, then:
```bash
cdev --help
cdev list
cdev run --image u2604dev --workspace "$PWD" --build
```

With host AI config and Git remotes (SSH read-only, OpenCode/Pi when present):
```bash
cdev run --image u2604dev --workspace "$PWD" \
  --mount-ssh --mount-opencode --mount-pi \
  --mount-codex --mount-claude --build
```

Or use a **preset** (same mounts as above; `full` also enables the Docker socket):
```bash
cdev run --preset ai --workspace "$PWD" --build
cdev run --preset full -w "$PWD" --build
```

Presets compose with explicit flags: a preset turns on a baseline set of mounts; any `--mount-*` you pass on the command line **also** enables that mount. See `cdev run --help`.

From a git clone (without install):
```bash
./cli/bin/cdev --help
```

Inside the container:
```bash
opencode --version
pi --version
```

#### Node package managers (pnpm, Yarn)

Images run **`corepack enable`** at build time (Node.js LTS). Inside the sandbox:

```bash
pnpm install          # after corepack prepare pnpm@latest --activate, or per project
yarn install          # Yarn Berry via corepack when packageManager is set in package.json
```

Global **npm** installs used for AI CLIs (`opencode`, `pi`, Claude Code, Codex) are unchanged; Corepack only manages project-local `pnpm`/`yarn` shims.

#### Python environments (venv and uv)

Distro **python3** and **pip** remain the default. **[uv](https://docs.astral.sh/uv/)** is installed to `/usr/local/bin` for faster venvs and installs:

```bash
uv venv && source .venv/bin/activate
uv pip install -r requirements.txt
```

Shell aliases `venv` / `activate` still wrap `python3 -m venv` for stdlib workflows.

Mount paths inside the container: `/workspace`, and under `/root` (default) or `/home/dev` with `--nonroot`: `.ssh` (ro), `.config/opencode`, `.pi`, `.codex`, `.claude`.

#### Authentication for AI CLIs in the sandbox

Dev images ship Claude Code, Codex, OpenCode, and Pi, but **credentials are not baked in**. Use host config mounts and/or environment variables you pass at `docker run` / `cdev run` time. Never commit real keys; use placeholders in docs and scripts.

| Tool | Typical auth | Host → container (default root user) | Notes |
|------|----------------|--------------------------------------|-------|
| **Claude Code** | Anthropic API key and/or logged-in CLI state | `$HOME/.claude` → `/root/.claude` (`--mount-claude`) | API: `-e ANTHROPIC_API_KEY=sk-ant-...` (placeholder). Mount carries sessions and settings from the host. |
| **Codex** (OpenAI) | OpenAI / ChatGPT login or API key | `$HOME/.codex` → `/root/.codex` (`--mount-codex`) | API: `-e OPENAI_API_KEY=sk-...` (placeholder). Mount mirrors host Codex auth files. |
| **OpenCode** | Provider keys in OpenCode config | `$HOME/.config/opencode` → `/root/.config/opencode` (`--mount-opencode`) | Configure providers on the host, then mount; or set provider env vars OpenCode reads (see [OpenCode docs](https://opencode.ai/)). |
| **Pi** | Provider config under Pi agent dir | `$HOME/.pi` → `/root/.pi` (`--mount-pi`, optional if dir missing) | Same pattern: mount host `~/.pi` or inject keys via env per Pi provider docs. |
| **Git / SSH remotes** | SSH keys and `known_hosts` | `$HOME/.ssh` → `/root/.ssh` read-only (`--mount-ssh`) | Not an AI key; needed for private repos inside the sandbox. |

With **`cdev run --nonroot`**, replace `/root` with `/home/dev` in the container column above.

**Examples (placeholders only):**
```bash
# API keys without mounting Claude/Codex dirs
docker run --rm -it -e ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY}" \
  -v "$PWD":/workspace ghcr.io/luongnv89/u2604dev:latest zsh

# Recommended: reuse host login state
cdev run --preset ai --workspace "$PWD" --build
```

Interactive `cdev run` prompts link here when you skip a mount. More detail: [cli/README.md](cli/README.md).

#### Docker / Compose from inside the sandbox

Images include the **Docker CLI** (not the daemon). To run `docker` or `docker compose` against your **host** engine, bind-mount the socket (opt-in):

```bash
cdev run --image u2604dev --workspace "$PWD" --mount-docker-socket --build
```

Equivalent `docker run`:

```bash
docker run --rm -it -v "$PWD":/workspace -v /var/run/docker.sock:/var/run/docker.sock ghcr.io/luongnv89/u2604dev:latest zsh
```

**Security:** Anything in the container that can use `/var/run/docker.sock` can control the host Docker API (start privileged containers, mount host paths, etc.). Use `--mount-docker-socket` only on trusted projects and avoid sharing that container with untrusted code. See [Docker daemon attack surface](https://docs.docker.com/engine/security/#docker-daemon-attack-surface).

Legacy helper [u2604dev-opencode/run.sh](u2604dev-opencode/run.sh) now targets `u2604dev` (the separate opencode image variant is deprecated).

## Documentation

| Topic | File |
|-------|------|
| Architecture & CI layout | [docs/architecture.md](docs/architecture.md) |
| Development setup | [docs/development.md](docs/development.md) |
| Troubleshooting | [docs/troubleshooting.md](docs/troubleshooting.md) |
| Doc change log | [docs/DECISIONS.md](docs/DECISIONS.md) |
| `cdev` CLI | [cli/README.md](cli/README.md) |
| Contributing guidelines | [CONTRIBUTING.md](CONTRIBUTING.md) |
| Code of conduct | [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) |
| Security policy | [SECURITY.md](SECURITY.md) |
| Changelog | [CHANGELOG.md](CHANGELOG.md) |

> Validate install/runbook checks: `./scripts/validate-cdev-install.sh --check`, `./scripts/validate-dev-environment.sh --check` (`scripts/validate-cdev-install.sh`, `scripts/validate-dev-environment.sh`).

## Installation

### Prerequisites

- Docker Desktop or Docker Engine
- (Optional) GitHub PAT for pulling from GHCR

### Getting Images

Images are published to GitHub Container Registry. See [Available Images](#available-images) for the full list.

#### Authentication

Using GitHub PAT (requires read:packages scope):
```bash
echo "${GH_PAT}" | docker login ghcr.io -u <github-username> --password-stdin
```

#### Pulling Images

Pull latest tag:
```bash
docker pull ghcr.io/luongnv89/u2604dev:latest
```

Pull specific version by commit SHA:
```bash
docker pull ghcr.io/luongnv89/u2604dev:<git-sha>
```

#### Running Containers

Interactive shell:
```bash
docker run --rm -it ghcr.io/luongnv89/u2604dev:latest zsh
```

With current directory mounted:
```bash
docker run --rm -it -v "$PWD":/workspace ghcr.io/luongnv89/u2604dev:latest zsh
```

Or use [`cdev run`](#using-the-cdev-cli-recommended) for mounts and optional AI config.

## Development

### Setting Up

1. Fork the repository
2. Clone your fork
3. Create a feature branch

Clone the repository:
```bash
git clone https://github.com/YOUR-USERNAME/docker-dev.git
```

Navigate to the directory:
```bash
cd docker-dev
```

Create a feature branch:
```bash
git checkout -b my-feature
```

### Pre-commit Hooks

Install the pre-commit hook for automated quality checks:
```bash
ln -sf ../../scripts/pre-commit.sh .git/hooks/pre-commit
```

Or run ad-hoc:
```bash
./scripts/pre-commit.sh
```

This will:
- Format shell scripts via shfmt
- Lint shell scripts with ShellCheck
- Lint Dockerfiles with Hadolint
- Build the u2604dev image to verify Dockerfile validity
- Clean up temporary files

### Adding a New Image

See [CONTRIBUTING.md](CONTRIBUTING.md#adding-a-new-image) for detailed instructions.

### CI/CD

The repository uses GitHub Actions for automated builds:

- **Matrix workflow**: Builds **u2204dev**, **u2404dev**, and **u2604dev** (three profiles each) with multi-platform support (`.github/workflows/build-images.yml:57-89`)
- **Path-based detection**: Only builds images that changed
- **Security scanning**: Trivy scans for vulnerabilities
- **Artifact attestation**: Provenance for published images

Workflow file: [`.github/workflows/build-images.yml`](.github/workflows/build-images.yml)

## Contributing

We welcome contributions! Please read our [Contributing Guide](CONTRIBUTING.md) for:

- Setting up your development environment
- Development workflow
- Pull request process
- Code style guidelines
- Testing requirements

By participating, you are expected to uphold our [Code of Conduct](CODE_OF_CONDUCT.md).

## Security

For security vulnerabilities, please read our [Security Policy](SECURITY.md) for responsible reporting guidelines.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Oh My Zsh](https://ohmyz.sh/) for the excellent shell framework
- [Starship](https://starship.rs/) for the cross-shell prompt
- [Vim](https://www.vim.org/) community for editor plugins
- [Docker](https://www.docker.com/) for container technology

## Support

- [Issues](../../issues) for bug reports and feature requests
- [Discussions](../../discussions) for questions and general discussion
- Email: luongnv89@gmail.com
