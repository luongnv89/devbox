# cdev CLI

**C**oding **dev** containers — launcher for docker-dev images.

## Install

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
| `cdev run` | Build/pull and start interactive zsh session (optional `--mount-docker-socket`) |
| `cdev build` | Build image locally |
| `cdev list` | Show image names (`--format json`) |
| `cdev config` | Show repo root and mount paths |

## Global flags

- `--version`, `-h` / `--help`
- `-v` / `--verbose`, `-q` / `--quiet`, `--no-color`
- `--repo PATH` or `CDEV_REPO`

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
```