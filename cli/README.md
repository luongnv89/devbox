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
| `cdev run` | Build/pull and start interactive zsh session |
| `cdev build` | Build image locally |
| `cdev list` | Show image names (`--format json`) |
| `cdev config` | Show repo root and mount paths |

## Global flags

- `--version`, `-h` / `--help`
- `-v` / `--verbose`, `-q` / `--quiet`, `--no-color`
- `--repo PATH` or `CDEV_REPO`

## Development

```bash
export CDEV_REPO="$PWD"
./cli/bin/cdev list
./scripts/tasks/test-docker-dev-cli.sh
```