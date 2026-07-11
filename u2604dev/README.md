# u2604dev – Ubuntu 26.04 Development Image

[![Docker Pulls](https://img.shields.io/docker/pulls/ghcr.io/luongnv89/u2604dev)](https://github.com/luongnv89/docker-dev/pkgs/container/u2604dev)
[![GitHub Release](https://img.shields.io/github/v/release/luongnv89/docker-dev?filter=u2604dev)](https://github.com/luongnv89/docker-dev/releases)

This image bundles a productive CLI environment for day-to-day development on Ubuntu 26.04.

## Quick Start

```bash
# Pull from GitHub Container Registry
docker pull ghcr.io/luongnv89/u2604dev:latest

# Run interactively
docker run --rm -it ghcr.io/luongnv89/u2604dev:latest zsh

# With current directory mounted
docker run --rm -it -v "$PWD":/workspace ghcr.io/luongnv89/u2604dev:latest zsh
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
| Python | 3.13 |
| git | Latest |
| ripgrep | Latest |
| bat | Latest |
| btop | Latest |

### AI / coding agents (baked in)

- **OpenCode**, **Pi** (`@mariozechner/pi-coding-agent`)
- **Claude Code** and **Codex** (npm globals; use `--mount-claude` / `--mount-codex` via [`scripts/docker-dev`](../../scripts/docker-dev) for host login state)
- **pi-extensions** from [`luongnv89/pi-extensions`](https://github.com/luongnv89/pi-extensions) (opencode-pi, statusline-pi, themes)
- **[herdr](https://herdr.dev/)** — herd manager for dev tools (`/usr/local/bin/herdr`)

Build from repo root:

```bash
docker build -t u2604dev -f u2604dev/Dockerfile .
```

### Other Features

- JetBrains Mono Nerd Font pre-installed
- Welcome message on shell startup showing installed versions
- Development-friendly shell aliases configured

## Installed Packages

- **CLI Tools**: git, vim, wget, curl, zsh, unzip, fontconfig
- **Build Tools**: build-essential, ninja-build, cmake, gettext
- **Utilities**: btop, ripgrep, bat, ca-certificates, gnupg, lsb-release

## Build

```bash
# Build locally
docker build -t my-u2604dev -f u2604dev/Dockerfile u2604dev

# Run locally built image
docker run --rm -it -v "$PWD":/workspace my-u2604dev zsh
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
| SHELL | zsh |

## Image Details

| Property | Value |
|----------|-------|
| Base Image | ubuntu:26.04 |
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

1. Edit `u2604dev/Dockerfile`
2. Update this README if adding/removing features
3. Test with: `docker build -t test-u2604dev -f u2604dev/Dockerfile u2604dev`
4. Submit a PR

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for full guidelines.

## Related

- **Main Repository**: [docker-dev](https://github.com/luongnv89/docker-dev)
- **Other Images**: [u2404dev](../u2404dev/README.md), [u2204dev](../u2204dev/README.md)
- **Security Policy**: [SECURITY.md](../../SECURITY.md)
