# u2604dev – Ubuntu 26.04 Development Image

[![Docker Pulls](https://img.shields.io/docker/pulls/ghcr.io/luongnv89/u2604dev)](https://github.com/luongnv89/docker-dev/pkgs/container/u2604dev)
[![GitHub Release](https://img.shields.io/github/v/release/luongnv89/docker-dev?filter=u2604dev)](https://github.com/luongnv89/docker-dev/releases)

This image bundles a productive CLI environment for day-to-day development on Ubuntu 26.04.

## Quick Start

**Recommended:** use the [`cdev` CLI](../../cli/README.md) from the repo root or after [install](../../README.md#using-the-cdev-cli-recommended):

```bash
cdev run --image u2604dev --workspace "$PWD"

# With host Git + AI config when present
cdev run --image u2604dev --workspace "$PWD" \
  --mount-ssh --mount-opencode --mount-pi \
  --mount-codex --mount-claude --build
```

Plain `docker` (no optional mounts):

```bash
docker pull ghcr.io/luongnv89/u2604dev:latest
docker run --rm -it ghcr.io/luongnv89/u2604dev:latest zsh
docker run --rm -it -v "$PWD":/workspace ghcr.io/luongnv89/u2604dev:latest zsh
```

## Features

### Shell

- **Oh My Zsh** with custom configuration
- **Starship** prompt for a fast, cross-shell experience
- Oh My Zsh plugins (built-in + custom): `git`, `docker`, `npm`, `pip`, `python`, plus custom plugins zsh-syntax-highlighting, zsh-autosuggestions, zsh-completions
- **Docker CLI** (client only, no in-image daemon) via `common/install-docker-cli.sh` (`common/dev-image-base.sh:59`). **kubectl** is not installed; themes show k8s context only if `kubectl` exists on PATH (`u2604dev/wedisagree.zsh-theme:129-130`).

### Editor

- **Vim** configured with vim-plug
- Plugins: fzf, NERDTree, GitGutter, vim-surround, auto-pairs

### Languages & Tooling

| Tool | Version |
|------|---------|
| Node.js | LTS |
| npm | Latest |
| pnpm / Yarn | via Corepack (Node LTS) |
| Python | 3.13 |
| uv | Latest (Astral; `/usr/local/bin`) |
| git | Latest |
| ripgrep | Latest |
| bat | Latest |
| btop | Latest |
| jq | apt |
| fzf | apt |
| fd | apt (`fd-find` → `fd`) |
| gh | GitHub CLI (apt) |

### AI / coding agents (baked in)

- **OpenCode**, **Pi** (`@mariozechner/pi-coding-agent`)
- **Claude Code** and **Codex** (npm globals; use `cdev run --mount-claude` / `--mount-codex` for host login state)
- **pi-extensions** from [`luongnv89/pi-extensions`](https://github.com/luongnv89/pi-extensions) (opencode-pi, statusline-pi, themes)
- **[herdr](https://herdr.dev/)** — herd manager for dev tools (`/usr/local/bin/herdr`)
- **[asm](https://github.com/luongnv89/agent-skill-manager)** (`agent-skill-manager`) plus baked skills from [`luongnv89/idd`](https://github.com/luongnv89/idd) and [`luongnv89/skills`](https://github.com/luongnv89/skills) in `~/.agents/skills`

CLIs install at npm `@latest` at image build. In a running container, run `update-ai-tools` (root or sudo) to upgrade the same set (including `asm` skill repos) and silence in-app update nags.

Build from repo root:

```bash
docker build -t u2604dev -f u2604dev/Dockerfile .
```

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
docker build -t my-u2604dev -f u2604dev/Dockerfile .

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

# Python (stdlib venv or uv)
alias venv='python3 -m venv venv'
alias activate='source venv/bin/activate'
# uv: uv venv && source .venv/bin/activate
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
| Base Image | ubuntu:26.04 |
| Default Shell | zsh |
| Non-root User | root |
| Port | 22 (SSH, if enabled) |

## Published Tags

GHCR tags per profile (`.github/workflows/build-images.yml:130-136`, `cli/lib/profiles.sh:17-24`):

| Tag | Profile |
|-----|---------|
| `latest` | `ai-full` (default) |
| `latest-standard` | `standard` |
| `latest-minimal` | `minimal` |
| `sha-{git-sha}` | `ai-full` commits on `main` |
| Semver tags | `ai-full` when released |

## CI/CD

This image is built and published by GitHub Actions:

- **Workflow**: [`.github/workflows/build-images.yml`](../../.github/workflows/build-images.yml)
- **Registry**: GitHub Container Registry (ghcr.io)
- **Multi-platform**: linux/amd64, linux/arm64

## Contributing

To modify this image:

1. Edit `u2604dev/Dockerfile`
2. Update this README if adding/removing features
3. Test with: `docker build -t test-u2604dev -f u2604dev/Dockerfile .` (repo root context; `scripts/tasks/test.sh:15-16`)
4. Submit a PR

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for full guidelines.

## Related

- **Main Repository**: [docker-dev](https://github.com/luongnv89/docker-dev)
- **Other Images**: [u2404dev](../u2404dev/README.md), [u2204dev](../u2204dev/README.md)
- **Security Policy**: [SECURITY.md](../../SECURITY.md)
