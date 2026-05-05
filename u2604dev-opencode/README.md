# u2604dev-opencode

Docker development environment based on `u2604dev` with opencode installed.

## Features

- Based on Ubuntu 26.04 development environment (u2604dev)
- OpenCode CLI installed: https://opencode.ai/
- SSH credentials shared from host for GitHub operations (optional)
- Workspace folder shared from host at `~/workspace` (optional)
- OpenCode configuration synced from host (optional)
- Works with **Dockerfile only** - no docker-compose required

## Quick Start

### Build the image

```bash
cd u2604dev-opencode
docker build -t u2604dev-opencode:latest .
```

### Run container

```bash
# Default: all volumes mounted
docker run -it --rm \
  -v ~/workspace:/workspace \
  -v ~/.ssh:/root/.ssh:ro \
  -v ~/.config/opencode:/root/.config/opencode \
  u2604dev-opencode:latest

# Or use the helper script (see below)
./run.sh
```

### Inside the container

```bash
# Check opencode is installed
opencode --version

# Run opencode
opencode
```

## Volume Mounts

Volumes are optional. Adjust the `docker run` command to customize:

| Volume | Default Host Path | Container Path | Required |
|--------|-----------------|--------------|----------|
| workspace | `~/workspace` | `/workspace` | No |
| SSH | `~/.ssh` | `/root/.ssh:ro` | No |
| opencode config | `~/.config/opencode` | `/root/.config/opencode` | No |

### Examples

**Workspace only (no SSH, no config):**
```bash
docker run -it --rm -v ~/workspace:/workspace u2604dev-opencode:latest
```

**Custom paths:**
```bash
docker run -it --rm \
  -v /my/workspace:/workspace \
  -v /my/ssh:/root/.ssh:ro \
  -v /my/opencode:/root/.config/opencode \
  u2604dev-opencode:latest
```

**No volumes at all:**
```bash
docker run -it --rm u2604dev-opencode:latest
```

## Helper Script

A `run.sh` script is provided for convenience. Edit it to customize paths:

```bash
# Edit these paths:
WORKSPACE="/Users/you/workspace"
SSH_PATH="$HOME/.ssh"
OPENCODE_CONFIG="$HOME/.config/opencode"

# Then run:
./run.sh
```

## SSH Permissions

The container automatically fixes SSH permissions at runtime (only if SSH volume is present):
- `.ssh` directory: 700
- Private keys: 600
- Public keys: 644

## Seamless Switching

To switch from your host machine to this container:

1. **On host**: Ensure your work is saved
2. **Start container**: `./run.sh` or the docker run command above
3. **In container**: Your workspace, SSH credentials, and opencode config are all available

This allows you to:
- Continue working in the same files
- Use GitHub with your existing SSH keys
- Use opencode with your existing configuration

## First-run agent setup

When you first run opencode inside the container, paste this prompt to configure the agent's persistent memory:

```
Please save the following to your persistent memory:

1. SSH-based GitHub authentication is preconfigured via /root/.ssh (mounted read-only from the host). Use this for all GitHub operations (clone, push, pull). Do not generate new SSH keys or prompt for credentials.

2. All project work must live under /workspace/ (the host's ~/workspace mounted as a shared volume). New projects should be cloned or created there. Existing projects are already there.

3. The opencode configuration at /root/.config/opencode is shared with the host (~/.config/opencode). Changes persist across container restarts.
```

This ensures the agent uses the shared SSH credentials, works in the correct workspace, and understands the shared configuration.