# u2604dev-opencode

Docker development environment based on `u2604dev` with opencode installed.

## Features

- Based on Ubuntu 26.04 development environment (u2604dev)
- OpenCode CLI installed: https://opencode.ai/
- SSH credentials shared from host for GitHub operations
- Workspace folder shared from host at `~/workspace`
- OpenCode configuration synced from host

## Quick Start

### Build the image

```bash
cd u2604dev-opencode
docker compose build opencode-dev
```

### Run container interactively

```bash
docker compose run --rm -it opencode-dev
```

### Inside the container

```bash
# Check opencode is installed
opencode --version

# Run opencode
opencode
```

## Volume Mounts

| Host Path | Container Path | Description |
|-----------|----------------|-------------|
| `~/workspace` | `/workspace` | Shared workspace folder |
| `~/.ssh` | `/root/.ssh` (read-only) | SSH credentials for GitHub |
| `~/.config/opencode` | `/root/.config/opencode` | OpenCode configuration |

## SSH Permissions

The container automatically fixes SSH permissions at runtime:
- `.ssh` directory: 700
- Private keys: 600
- Public keys: 644

## Seamless Switching

To switch from your host machine to this container:

1. **On host**: Ensure your work is saved
2. **Start container**: `docker compose run --rm -it opencode-dev`
3. **In container**: Your workspace (`~/workspace`), SSH credentials, and opencode config are all available

This allows you to:
- Continue working in the same files
- Use GitHub with your existing SSH keys
- Use opencode with your existing configuration