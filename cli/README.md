# cdev CLI

**C**oding **dev** containers — launcher for docker-dev images.

## Install

> Validate: `./scripts/validate-cdev-install.sh --check` (from repo root).

Installs **cdev** on the host. **[herdr](https://herdr.dev/)** is baked into container images (`common/install-ai-tools.sh`).

```bash
curl -fsSL https://raw.githubusercontent.com/luongnv89/docker-dev/main/install.sh | bash
```

From a repository checkout:

```bash
./install.sh
```

## Commands

| Command | Description |
|---------|-------------|
| `cdev run` | Build/pull and start interactive zsh session (`--preset`, optional `--mount-docker-socket`) |
| `cdev build` | Build image locally |
| `cdev list` | Show image names (`--format json`) |
| `cdev config` | Show repo root and mount paths |

## Global flags

- `--version`, `-h` / `--help`
- `-v` / `--verbose`, `-q` / `--quiet`, `--no-color`
- `--repo PATH` or `CDEV_REPO`

## Run presets

`cdev run --preset NAME` applies a common mount bundle before starting the container. List presets in `cdev run --help`.

| Preset | Mounts enabled |
|--------|----------------|
| `ai` | SSH, Claude (`.claude`), Codex (`.codex`), OpenCode, Pi (when host dir exists) |
| `full` | Same as `ai` plus host Docker socket |

**Precedence:** the preset sets defaults; explicit `--mount-*` flags on the CLI **add** mounts (they do not cancel a preset). Workspace is always set with `-w` / `--workspace` (default: current directory). Combine preset + extra flags, e.g. `cdev run --preset ai --mount-docker-socket`.

```bash
cdev run --preset ai -w "$PWD" --build
```

## Authentication (AI CLIs in the sandbox)

Images include the CLIs; you supply credentials via **bind mounts** and/or **environment variables**. Do not commit secrets.

| Mount flag | Host path | Container path (root) |
|------------|-----------|------------------------|
| `--mount-claude` | `~/.claude` | `/root/.claude` |
| `--mount-codex` | `~/.codex` | `/root/.codex` |
| `--mount-opencode` | `~/.config/opencode` | `/root/.config/opencode` |
| `--mount-pi` | `~/.pi` (optional) | `/root/.pi` |
| `--mount-ssh` | `~/.ssh` (ro) | `/root/.ssh` |

Common env vars (examples use placeholders): `ANTHROPIC_API_KEY` (Claude), `OPENAI_API_KEY` (Codex/OpenAI). Pass with `docker run -e` or your orchestrator. With `--nonroot`, container paths are under `/home/dev`.

Full table and examples: [../README.md#authentication-for-ai-clis-in-the-sandbox](../README.md#authentication-for-ai-clis-in-the-sandbox).

Inside a running container, `update-ai-tools` (root or sudo) upgrades the baked-in AI CLIs to npm `@latest` and refreshes `asm` skill repos (`idd`, `skills`).

## Host Docker socket (optional)

Dev images ship the Docker **client** only. Pass `--mount-docker-socket` to bind `/var/run/docker.sock` so `docker` / `docker compose` inside the container use the host daemon. This is **privileged**: processes in the container can administer Docker on the host. Default interactive prompt answers **no**; pass the flag explicitly in scripts.

```bash
cdev run --image u2604dev -w "$PWD" --mount-docker-socket --build
```

## Development

```bash
export CDEV_REPO="$PWD"
./cli/bin/cdev list
./scripts/tasks/test-docker-dev-cli.sh
./scripts/validate-ohmyzsh-plugins.sh
./scripts/validate-cdev-install.sh --check
```
