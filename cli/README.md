# docker-dev CLI

Subcommand-based launcher for coding-ready containers.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/luongnv89/docker-dev/main/install.sh | bash
```

## Commands

| Command | Description |
|---------|-------------|
| `docker-dev run` | Build/pull and start interactive zsh session |
| `docker-dev build` | Build image locally |
| `docker-dev list` | Show image names (`--format json`) |
| `docker-dev config` | Show repo root and mount paths |

## Global flags

- `--version`, `-h` / `--help`
- `-v` / `--verbose`, `-q` / `--quiet`, `--no-color`
- `--repo PATH` or `DOCKER_DEV_REPO`

## Exit codes

- `0` success
- `1` runtime error (Docker, missing paths)
- `2` usage error (unknown flags/commands)

## Development

From repository root:

```bash
export DOCKER_DEV_REPO="$PWD"
./cli/bin/docker-dev list
./scripts/tasks/test-docker-dev-cli.sh
```