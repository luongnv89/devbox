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

## Available Images

| Folder | Description | Docs |
|--------|-------------|------|
| `u2604dev/` | Ubuntu 26.04 CLI/dev environment with Oh My Zsh, Starship prompt, Vim plugins, Node.js LTS, Python 3.13, etc. | [u2604dev/README.md](u2604dev/README.md) |
| `u2404dev/` | Ubuntu 24.04 CLI/dev environment with Oh My Zsh, Starship prompt, Vim plugins, Node.js LTS, Python 3.12, etc. | [u2404dev/README.md](u2404dev/README.md) |
| `u2204dev/` | Ubuntu 22.04 CLI/dev environment with Oh My Zsh, wedisagree theme, Vim plugins, Node.js, Python 3.12, etc. | [u2204dev/README.md](u2204dev/README.md) |
| `u2604dev-opencode/` | Ubuntu 26.04 with opencode CLI installed - seamless switching between host and container | [u2604dev-opencode/README.md](u2604dev-opencode/README.md) |

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

Build a specific image:
```bash
docker build -t my-dev-env -f u2604dev/Dockerfile u2604dev
```

Run locally built image:
```bash
docker run --rm -it -v "$PWD":/workspace my-dev-env zsh
```

### Using Docker Compose (u2604dev-opencode)

Build the opencode image:
```bash
cd u2604dev-opencode
docker compose build opencode-dev
```

Run the container interactively:
```bash
docker compose run --rm -it opencode-dev
```

Inside the container, verify opencode is installed:
```bash
opencode --version
```

## Documentation

| Topic | File |
|-------|------|
| Contributing guidelines | [CONTRIBUTING.md](CONTRIBUTING.md) |
| Code of conduct | [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) |
| Security policy | [SECURITY.md](SECURITY.md) |
| Changelog | [CHANGELOG.md](CHANGELOG.md) |

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

Using docker compose:
```bash
docker compose run --rm dev zsh
```

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

- **Matrix workflow**: Builds all 4 images with multi-platform support
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
