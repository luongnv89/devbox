<p align="center"><img src="logo.png" alt="docker-dev logo" width="400"></p>

[![Build and Publish](https://github.com/luongnv89/docker-dev/actions/workflows/build-images.yml/badge.svg)](https://github.com/luongnv89/docker-dev/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/luongnv89/docker-dev)](https://github.com/luongnv89/docker-dev/stargazers)

# Disposable devbox for AI coding

A single Docker image — **devbox** — that ships Claude Code, Codex, OpenCode, Pi, herdr, and a full development toolkit inside a disposable Ubuntu 26.04 container. Drop into it, code, exit, and the container disappears.

## Quick start

```bash
# Pull the published image and start a disposable shell with your project mounted
docker run --rm -it -v "$PWD":/workspace ghcr.io/luongnv89/devbox:latest zsh
```

That's it. Open an AI coding tool, edit files on the host, and exit when done.

## Building locally

Build from the repository root (the Dockerfile is at the root):

```bash
docker build -t devbox -f Dockerfile .
```

Then run the locally built image:

```bash
docker run --rm -it -v "$PWD":/workspace devbox zsh
```

## What is included

| Category | Contents |
|---|---|
| OS | Ubuntu 26.04, zsh + Oh My Zsh + Starship prompt |
| Languages | Node.js LTS + Corepack, Python 3.13 + uv |
| Editors | Vim with NERDTree, fzf, gitgutter |
| CLI tools | Git, GitHub CLI, jq, fd, ripgrep, bat, fzf, btop |
| Docker | Docker CLI client (connect to host socket for full access) |
| AI tools | Claude Code, Codex, OpenCode, Pi, herdr, agent-skill-manager |
| Skills | Baked-in skills from [idd](https://github.com/luongnv89/idd) and [skills](https://github.com/luongnv89/skills) |

## Running containers

### Ephemeral (default)

Each `docker run --rm` creates a disposable container that is removed when you exit:

```bash
docker run --rm -it -v "$PWD":/workspace ghcr.io/luongnv89/devbox:latest zsh
```

### Named (persistent)

Give a container a name so you can re-enter it later:

```bash
# Start a named container (no --rm)
docker run -it -v "$PWD":/workspace --name my-dev ghcr.io/luongnv89/devbox:latest zsh

# Re-enter later
docker exec -it my-dev zsh

# Remove when done
docker rm my-dev
```

## Workspace mount

The host project directory is mounted at **`/workspace`** inside the container:

```bash
-v "$PWD":/workspace
```

All files created or edited inside the container appear on the host. The workspace is owned by **root** inside the container, so files you create will be root-owned on the host. To avoid this, build and run with a non-root user (see below).

## Agent configuration mounts

Mount your host AI-agent configuration directories so the tools inside the container can authenticate and find your skills:

| Mount flag | Host path | Container path |
|---|---|---|
| `--mount-claude` | `~/.claude` | `/root/.claude` |
| `--mount-codex` | `~/.codex` | `/root/.codex` |
| `--mount-opencode` | `~/.config/opencode` | `/root/.config/opencode` |
| `--mount-pi` | `~/.pi` | `/root/.pi` |

Agent skills directory:

| Mount flag | Host path | Container path |
|---|---|---|
| `--mount-agents` | `~/.agents` | `/root/.agents` |

SSH keys (read-only):

| Mount flag | Host path | Container path |
|---|---|---|
| `--mount-ssh` | `~/.ssh` | `/root/.ssh` (read-only) |

Example with all mounts:

```bash
docker run --rm -it \
  -v "$PWD":/workspace \
  -v "$HOME/.claude":/root/.claude \
  -v "$HOME/.codex":/root/.codex \
  -v "$HOME/.config/opencode":/root/.config/opencode \
  -v "$HOME/.pi":/root/.pi \
  -v "$HOME/.agents":/root/.agents \
  -v "$HOME/.ssh":/root/.ssh:ro \
  ghcr.io/luongnv89/devbox:latest zsh
```

> **Security note:** Never commit API keys or credentials into the image. Mount them at runtime from the host only when needed.

## Development ports

When running a web or API server inside the container, publish ports to the host:

```bash
docker run --rm -it -p 3000:3000 -v "$PWD":/workspace ghcr.io/luongnv89/devbox:latest zsh
```

The service inside the container must listen on **`0.0.0.0`** (not `127.0.0.1`) to be reachable from the host:

```bash
# Inside the container — correct
node server.js        # if server binds to 0.0.0.0
python -m http.server 3000 -b 0.0.0.0

# Inside the container — wrong (host cannot reach)
python -m http.server 3000   # binds to 127.0.0.1 only
```

## Non-root containers

By default the container runs as **root**. To avoid root-owned files in your workspace, build with a non-root user and pass the host UID/GID:

```bash
# Build with non-root support
docker build --build-arg DEV_CREATE_NONROOT_USER=1 \
             --build-arg DEV_UID=$(id -u) \
             --build-arg DEV_GID=$(id -g) \
             -t devbox -f Dockerfile .

# Run as the host user
docker run --rm -it -v "$PWD":/workspace -u $(id -u):$(id -g) devbox zsh
```

## Docker socket access

The image includes the Docker CLI but not a daemon. Mounting the host socket lets the container control the host Docker daemon:

```bash
docker run --rm -it \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$PWD":/workspace \
  ghcr.io/luongnv89/devbox:latest zsh
```

> **Warning:** Docker socket access grants full control over the host Docker daemon — it can start privileged containers, mount host paths, and escalate to root. Only enable this for trusted projects.

## Updating AI tools

Inside a running container, upgrade all baked-in AI CLIs to their latest versions:

```bash
update-ai-tools
```

Run as root or with `sudo`. This stops in-app "install new version" prompts.

## Authentication

Pass API keys via environment variables without storing them in the image:

```bash
docker run --rm -it \
  -e ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY}" \
  -e OPENAI_API_KEY="${OPENAI_API_KEY}" \
  -v "$PWD":/workspace \
  ghcr.io/luongnv89/devbox:latest zsh
```

## Python and Node environments

Create a Python virtual environment with uv:

```bash
uv venv && source .venv/bin/activate
```

Install with corepack for project-managed package managers:

```bash
corepack enable
pnpm install
# or
yarn install
```

## GitHub Container Registry

Authenticate to GHCR if your Docker setup requires it:

```bash
echo "${GH_PAT}" | docker login ghcr.io -u <github-username> --password-stdin
```

Pull a specific image version:

```bash
docker pull ghcr.io/luongnv89/devbox:latest
# or by commit SHA
docker pull ghcr.io/luongnv89/devbox:<git-sha>
```

---

[Contributing](CONTRIBUTING.md) · [Security policy](SECURITY.md) · [Troubleshooting](docs/troubleshooting.md) · [MIT licensed](LICENSE)
