# u2404dev – Ubuntu 24.04 Development Image

[![Docker Pulls](https://img.shields.io/docker/pulls/ghcr.io/luongnv89/u2404dev)](https://github.com/luongnv89/docker-dev/pkgs/container/u2404dev)
[![GitHub Release](https://img.shields.io/github/v/release/luongnv89/docker-dev?filter=u2404dev)](https://github.com/luongnv89/docker-dev/releases)

This image bundles a productive CLI environment for day-to-day development on Ubuntu 24.04.

## Quick Start

**Recommended:** use the [`cdev` CLI](../../cli/README.md) from the repo root or after [install](../../README.md#using-the-cdev-cli-recommended):

```bash
cdev run --image u2404dev --workspace "$PWD"

# With host Git + AI config when present
cdev run --image u2404dev --workspace "$PWD" \
  --mount-ssh --mount-opencode --mount-pi \
  --mount-codex --mount-claude
```

Plain `docker` (no optional mounts):

```bash
docker pull ghcr.io/luongnv89/u2404dev:latest
docker run --rm -it ghcr.io/luongnv89/u2404dev:latest zsh
docker run --rm -it -v "$PWD":/workspace ghcr.io/luongnv89/u2404dev:latest zsh
```

## Features

### Shell

- **Oh My Zsh** with custom configuration
- **Starship** prompt for a fast, cross-shell experience
- Oh My Zsh plugins (built-in + custom): `git`, `npm`, `pip`, `python`, plus custom plugins zsh-syntax-highlighting, zsh-autosuggestions, zsh-completions
- **Docker CLI and kubectl are not installed** in the image (sandbox-friendly); Starship may still show container context when running inside Docker.

### Editor

- **Vim** configured with vim-plug
- Plugins: fzf, NERDTree, GitGutter, vim-surround, auto-pairs

### Languages & Tooling

| Tool | Version |
|------|---------|
| Node.js | LTS |
| npm | Latest |
| Python | 3.12 |
| git | Latest |
| ripgrep | Latest |
| bat | Latest |
| btop | Latest |
| jq | apt |
| fzf | apt |
| fd | apt (`fd-find` → `fd`) |
| gh | GitHub CLI (apt) |

### AI / coding agents (baked in)

Same stack as other `*dev` images — see [`common/install-ai-tools.sh`](../../common/install-ai-tools.sh) and [u2604dev](../u2604dev/README.md#ai--coding-agents-baked-in) for the full list (OpenCode, Pi, Claude Code, Codex, pi-extensions, herdr). Use `cdev run` mount flags for host config.

### Other Features

- JetBrains Mono Nerd Font pre-installed
- Welcome message on shell startup showing installed versions
- Development-friendly shell aliases configured

## Installed Packages

- **CLI Tools**: git, git-lfs, openssh-client, vim, wget, curl, zsh, unzip, fontconfig, jq, fzf, fd-find (symlinked as `fd`), gh
- **Build Tools**: build-essential, ninja-build, cmake, gettext
- **Utilities**: btop, ripgrep, bat, tzdata, ca-certificates, gnupg, lsb-release

## Build

```bash
# Build locally
docker build -t my-u2404dev -f u2404dev/Dockerfile .

# Run locally built image
docker run --rm -it -v "$PWD":/workspace my-u2404dev zsh
```

## Shell Aliases

The image includes useful aliases:

```bash
# General
alias ls='ls --color=auto'
alias ll='ls -lah'
alias la='ls -A'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias cat='bat --paging=never'
alias top='btop'
alias ff='fzf'
alias jj='jq'

# fzf uses fd for file search; Ctrl-T / Alt-C key bindings enabled in zsh

# Git
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'

# Python
alias venv='python3 -m venv venv'
alias activate='source venv/bin/activate'
```

## Environment Variables

| Variable | Value |
|----------|-------|
| LANG | en_US.UTF-8 |
| LC_ALL | en_US.UTF-8 |
| TZ | `Etc/UTC` (override at runtime, e.g. `docker run -e TZ=America/New_York …`) |
| SHELL | zsh |

## Image Details

| Property | Value |
|----------|-------|
| Base Image | ubuntu:24.04 |
| Default Shell | zsh |
| Non-root User | root |
| Port | 22 (SSH, if enabled) |

## Published Tags

| Tag | Description |
|-----|-------------|
| `latest` | Latest stable release |
| `sha-{git-sha}` | Specific commit SHA |
| `{major}.{minor}` | Minor version (e.g., 1.0) |
| `{major}` | Major version (e.g., 1) |

## CI/CD

This image is built and published by GitHub Actions:

- **Workflow**: [`.github/workflows/build-images.yml`](../../.github/workflows/build-images.yml)
- **Registry**: GitHub Container Registry (ghcr.io)
- **Multi-platform**: linux/amd64, linux/arm64

## Contributing

To modify this image:

1. Edit `u2404dev/Dockerfile`
2. Update this README if adding/removing features
3. Test with: `docker build -t test-u2404dev -f u2404dev/Dockerfile u2404dev`
4. Submit a PR

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for full guidelines.

## Related

- **Main Repository**: [docker-dev](https://github.com/luongnv89/docker-dev)
- **Other Images**: [u2604dev](../u2604dev/README.md), [u2204dev](../u2204dev/README.md)
- **Security Policy**: [SECURITY.md](../../SECURITY.md)
