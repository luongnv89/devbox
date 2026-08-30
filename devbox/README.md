# devbox – Lean Debian 13 OpenCode Image

`devbox` is a small, glibc-based development image intended for the
`opencode-docker-dev` skill. It keeps the tools needed to run OpenCode against
a mounted project. Interactive zsh matches the host setup: Oh My Zsh
(`wedisagree`), zsh-users plugins, and Starship (shared `u2604dev/starship.toml`).

## Quick start

The skill uses the `standard` profile, which includes OpenCode, Pi, and the shared `asm` skill tooling:

```bash
bash ~/.agents/skills/opencode-docker-dev/scripts/run_opencode.sh \
  --project "$PWD" \
  --image ghcr.io/luongnv89/devbox:latest-standard \
  --start-only
```

For a normal interactive shell with `cdev`:

```bash
cdev run --image devbox --profile standard --pull \
  --workspace "$PWD" --mount-opencode
```

Plain Docker (the bundled skill script is preferred because it handles
startup, attach, and cleanup):

```bash
docker pull ghcr.io/luongnv89/devbox:latest-standard
docker run --rm -it \
  -v "$PWD":/workspace \
  --mount "type=bind,src=$HOME/.config/opencode,dst=/root/.config/opencode-host,readonly" \
  --mount "type=volume,dst=/root/.config/opencode" \
  ghcr.io/luongnv89/devbox:latest-standard \
  sh -c '
    set -eu
    marker=/root/.config/.docker-dev-opencode-config-copied
    if [ ! -e "$marker" ]; then
      cp -a /root/.config/opencode-host/. /root/.config/opencode/
      touch "$marker"
    fi
    exec zsh'
```

The host OpenCode config is mounted read-only and copied into an anonymous
writable volume so usage state and credentials never flow back to the host.
OpenCode credentials are supplied at runtime; they are not baked into the
image.

## Included

- Debian 13 slim with glibc
- Node.js LTS (NodeSource) and npm, compatible with Debian 13
- Python 3.13, pip, venv, and development headers
- Git, Git LFS, GitHub CLI (`gh`), build-essential, pkg-config
- zsh as the login shell, with Oh My Zsh (`ZSH_THEME=wedisagree`), plugins
  `git`, `zsh-syntax-highlighting`, `zsh-autosuggestions`, `zsh-completions`,
  Starship, and JetBrainsMono Nerd Font
- OpenCode, Pi, `asm`, and baked skills in the `standard` and `ai-full` profiles
- ripgrep (`rg`), fd (`fd`), jq, less, unzip, and `vi`
- `sleep infinity` support for the skill's keep-alive container
- `/workspace` and `/root/.config/opencode` directories

The image still omits Docker CLI, fzf, and the full Ubuntu utility stack
(btop, bat, vim-plug, extra Oh My Zsh plugins). Use an Ubuntu `*dev` image
when those tools are required.

## Profiles

| Profile | Tag | AI tools |
|---|---|---|
| `ai-full` | `latest` | Claude Code, Codex, OpenCode, Pi, herdr, pi-extensions, asm, idd + skills |
| `standard` | `latest-standard` | OpenCode, Pi, asm, idd + skills |
| `minimal` | `latest-minimal` | No global AI CLIs |

`latest-standard` is the recommended tag for `opencode-docker-dev`.

In a running container, `update-ai-tools` upgrades the profile’s AI CLIs to npm `@latest`.

## Build locally

Run from the repository root so `common/` is available to Docker:

```bash
docker build \
  --build-arg DEV_IMAGE_PROFILE=standard \
  -t devbox:latest-standard \
  -f devbox/Dockerfile .
```

Optional non-root image:

```bash
docker build \
  --build-arg DEV_IMAGE_PROFILE=standard \
  --build-arg DEV_CREATE_NONROOT_USER=1 \
  --build-arg DEV_UID="$(id -u)" \
  --build-arg DEV_GID="$(id -g)" \
  -t devbox:nonroot \
  -f devbox/Dockerfile .
```

The default for a direct `docker build` is `standard`; `cdev` selects the
profile explicitly and follows the repository-wide profile tag convention.
