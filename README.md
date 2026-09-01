<p align="center"><img src="logo.png" alt="devbox logo" width="400"></p>

[![Build and Publish devbox](https://github.com/luongnv89/docker-dev/actions/workflows/devbox.yml/badge.svg)](https://github.com/luongnv89/docker-dev/actions/workflows/devbox.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

# devbox — single Ubuntu 26.04 dev container

One Ubuntu 26.04 image that replaces the former `u2604dev` / `devbox` / `cdev` matrix with a single `Dockerfile` at the repository root. It preserves the `u2604dev` development and AI tooling verified in `BASELINE-u2604dev.md`, runs as `root` with `zsh` at `/workspace`, and is published as `ghcr.io/luongnv89/devbox`.

## Included environment

- **Base:** Ubuntu 26.04 (`FROM ubuntu:26.04`), `LANG=en_US.UTF-8`, `TZ=Etc/UTC`, `WORKDIR /workspace`
- **Shell + editor:** `zsh`, Oh My Zsh (plugins `git`, `docker`, `zsh-syntax-highlighting`, `zsh-autosuggestions`, `zsh-completions`, `npm`, `pip`, `python`), Starship (`starship.toml`), Vim with `vim-plug` (`nerdtree`, `vim-gitgutter`, `fzf`, `fzf.vim`, `vim-surround`, `auto-pairs`), JetBrainsMono Nerd Font, `.shell-cli-extras.zsh` (`fzf`/`fd`/`jq`/`gh` helpers)
- **Dev CLI:** `git` + `git-lfs` + `openssh-client`, `vim`, `curl`/`wget`, `jq`, `tzdata`, `btop`, `ripgrep` (`rg`), `bat`, `fzf`/`fd`, `ninja-build`/`gettext`/`cmake`/`build-essential`, `locales`, `fontconfig`
- **Runtimes:** `Node.js LTS` + `corepack` (`pnpm`/`yarn`), `python3`/`pip`/`venv` + `uv`, `docker.io` client + `docker-compose-v2` plugin, `gh` CLI
- **AI tools (ai-full default, via `npm install -g` at `@latest` except opencode2):** `claude` (`@anthropic-ai/claude-code`), `codex` (`@openai/codex`), `opencode2` (`@opencode-ai/cli@beta` — legacy `opencode-ai`/`opencode` is absent), `pi` (`@mariozechner/pi-coding-agent`) + `pi` extensions `opencode-pi`/`statusline-pi` + `luongnv89/pi-extensions`, `herdr`, `asm` (`agent-skill-manager`) with baked skills `luongnv89/idd` + `luongnv89/skills` linked into `claude`/`pi`/`codex` (`~/.agents/skills` → `~/.pi/skills`)
- **Entrypoint:** `common/entrypoint-dev.sh` behavior inlined (`TZ` honor, `RUN_AS` root vs `dev`, SSH perms, mount announcements for `~/.ssh`/`~/.codex`/`~/.claude`/`~/.config/opencode`/`~/.pi`/`~/.agents`/`/workspace`, `update-ai-tools` hint, `gosu dev` when `DEV_CREATE_NONROOT_USER=1`)
- **Profiles:** the single image builds at `ai-full` by default; `standard`/`minimal` remain buildable locally via `--build-arg DEV_IMAGE_PROFILE=standard|minimal` (same verify modes: `lenient` local, `strict` in CI)

See `BASELINE-u2604dev.md` for the full parity inventory and verification commands.

## Build and pull

Build locally (context is repository root — `Dockerfile` is self-contained, no `COPY` from legacy dirs; `.dockerignore` keeps the context minimal):

```bash
docker build -t devbox .
```

Pull the published image (requires `read:packages` on first pull if the package is private; otherwise anonymous):

```bash
docker pull ghcr.io/luongnv89/devbox:latest
# immutable SHA tag (per push to main)
docker pull ghcr.io/luongnv89/devbox:sha-<git-sha>
```

All published images are `linux/amd64` + `linux/arm64` and built from `.` with `AI_VERIFY_MODE=strict` and `AI_TOOLS_CACHEBUST=$GITHUB_RUN_ID` in CI.

## Running containers

### Ephemeral (disposable — removed on exit)

```bash
docker run --rm -it -v "$PWD":/workspace ghcr.io/luongnv89/devbox:latest zsh
# or from a local build
docker run --rm -it -v "$PWD":/workspace devbox zsh
```

Exit the shell to remove the container; the host project at `/workspace` remains.

### Named (re-enterable)

```bash
docker run -d --name my-dev -v "$PWD":/workspace ghcr.io/luongnv89/devbox:latest sleep infinity
docker exec -it my-dev zsh
```

Inside either container, start an AI tool:

```bash
opencode2   # OpenCode2 beta (note: `opencode` legacy command is absent)
pi
claude      # mount ~/.claude first (see below) or use npx fallback in lenient mode
codex
herdr
asm
```

Refresh AI CLIs inside a running container (as `root` or via `sudo`):

```bash
update-ai-tools
```

## Mounts — workspace and AI / SSH configuration

### Workspace

The container's `WORKDIR` is `/workspace`. Mount the host project there:

```bash
docker run --rm -it -v "$PWD":/workspace ghcr.io/luongnv89/devbox:latest zsh
# named variant uses the same -v
```

Pass only the project directory — mounting the entire home directory is not needed.

### AI configuration and skills

Credentials are **not** stored in the image. Mount only the config your tool needs. Host → container paths are under the container's home (`/root` by default, `/home/dev` with `--nonroot`):

| Host path | Container path | Used by |
|-----------|---------------|---------|
| `~/.agents` | `/root/.agents` | `asm` skills (`~/.agents/skills`) |
| `~/.claude` | `/root/.claude` | `claude` |
| `~/.codex` | `/root/.codex` | `codex` |
| `~/.pi` | `/root/.pi` | `pi` (`~/.pi/skills` is symlinked from `~/.agents/skills`) |
| `~/.config/opencode` | `/root/.config/opencode` | `opencode2` |

Examples (plain `docker run` — no `cdev` wrapper):

```bash
# Claude Code with your login state
docker run --rm -it -v "$PWD":/workspace -v "$HOME/.claude":/root/.claude ghcr.io/luongnv89/devbox:latest zsh

# OpenCode2 beta
docker run --rm -it -v "$PWD":/workspace -v "$HOME/.config/opencode":/root/.config/opencode ghcr.io/luongnv89/devbox:latest zsh
# inside: opencode2

# Pi
docker run --rm -it -v "$PWD":/workspace -v "$HOME/.pi":/root/.pi ghcr.io/luongnv89/devbox:latest zsh
# inside: pi

# All AI configs at once
docker run --rm -it \
  -v "$PWD":/workspace \
  -v "$HOME/.agents":/root/.agents \
  -v "$HOME/.claude":/root/.claude \
  -v "$HOME/.codex":/root/.codex \
  -v "$HOME/.pi":/root/.pi \
  -v "$HOME/.config/opencode":/root/.config/opencode \
  ghcr.io/luongnv89/devbox:latest zsh
```

### SSH — read-only mount

Mount host SSH keys read-only when you need `git+ssh` inside the container:

```bash
docker run --rm -it -v "$PWD":/workspace -v "$HOME/.ssh":/root/.ssh:ro ghcr.io/luongnv89/devbox:latest zsh
```

Entrypoint fixes perms (`700 ~/.ssh`, `600 ~/.ssh/id_*`, `644 ~/.ssh/*.pub`) when the mount is non-empty. Use `:ro` so a compromised container cannot rewrite keys. With `--nonroot` the path is `/home/dev/.ssh:ro`.

## Ports — development servers

Publish the host port and make the service inside the container **listen on `0.0.0.0`** (not `127.0.0.1`), or the mapped port will be unreachable:

```bash
# app inside container: python3 -m http.server 8000 --bind 0.0.0.0
docker run --rm -it -v "$PWD":/workspace -p 8000:8000 ghcr.io/luongnv89/devbox:latest zsh
# then in another host shell: curl http://localhost:8000

# Vite / Next.js example (already binds 0.0.0.0 via --host)
docker run --rm -it -v "$PWD":/workspace -p 5173:5173 ghcr.io/luongnv89/devbox:latest zsh
# inside: npm run dev -- --host 0.0.0.0 --port 5173
```

The entrypoint does not publish ports for you — `docker run -p` is the only mechanism. No `EXPOSE` in `Dockerfile` implies a default port.

## Warnings

- **Root-owned workspace files.** Containers run as `root` by default (`/etc/docker-dev-run-as` contains `root`). Files created in the bind-mounted `/workspace` are owned by `root` on the host. Fix with `sudo chown -R "$(id -u):$(id -g)" .` after exit, or build a non-root image locally (`--build-arg DEV_CREATE_NONROOT_USER=1 --build-arg DEV_UID="$(id -u)" --build-arg DEV_GID="$(id -g)"`) and run with `--user "$(id -u):$(id -g)"` (host `$HOME/.ssh` etc. then mount at `/home/dev/...`).
- **Credential mounts.** `~/.claude`, `~/.codex`, `~/.config/opencode`, `~/.pi`, `~/.agents` contain bearer tokens. Mount only the one you need, never commit them, and prefer `:ro` where the entrypoint tolerates it. The entrypoint only announces mounts; it does not scrub or rotate secrets.
- **Docker socket.** The image ships the Docker client only. Mounting `/var/run/docker.sock` (`-v /var/run/docker.sock:/var/run/docker.sock`) gives the container control of the host daemon (can start privileged containers and mount host paths). Enable only for trusted projects.
- **Floating beta dependency.** `opencode2` comes from `npm install -g @opencode-ai/cli@beta` at build time; `update-ai-tools` upgrades to `@latest`/`@beta` again. Pin to a SHA-published image (`ghcr.io/luongnv89/devbox:sha-...`) for reproducible CI.
- **Build context.** The Dockerfile is self-contained (no `COPY` from `common/`/`u2604dev/` etc.); `.dockerignore` excludes legacy directories so `docker build -t devbox .` sends a minimal context.

## Documentation

| Topic | File |
|---|---|
| Contributing (single Dockerfile workflow) | [CONTRIBUTING.md](CONTRIBUTING.md) |
| Security policy (mounts, socket, root, pinning) | [SECURITY.md](SECURITY.md) |
| Baseline inventory (pre-migration) | [BASELINE-u2604dev.md](BASELINE-u2604dev.md) |
| License | [LICENSE](LICENSE) |
| Code of Conduct | [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) |

CI: `.github/workflows/devbox.yml` — verifies `opencode2 --version`, publishes `latest` + `sha` on pushes to `main`, builds pull requests without publishing, supports `workflow_dispatch`, `linux/amd64` + `linux/arm64`, `permissions: contents: read, packages: write` only.
