# Security Policy

## Supported Versions

The following versions of docker-dev are currently being supported with security
updates:

| Version | Supported |
|---------|-----------|
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

We take the security of docker-dev seriously. If you believe you have found a
security vulnerability, please report it responsibly.

### How to Report

1. **Do NOT** open a public issue
2. Email your report to: **luongnv89@outlook.com**
3. Include as much detail as possible:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Any proposed fixes (if you have them)

### What to Expect

After submitting your report:

1. **Acknowledgment**: You will receive an acknowledgment within 24-48 hours
2. **Assessment**: We will assess the vulnerability and its severity
3. **Update**: We will keep you informed of the progress
4. **Credit**: With your permission, you will be credited in the security advisory

## Security Best Practices

### Credential Mounts

API keys and credentials are **never** baked into the image. They are mounted
from the host at runtime:

| Flag | Host path | Container path |
|---|---|---|
| `--mount-claude` | `~/.claude` | `/root/.claude` |
| `--mount-codex` | `~/.codex` | `/root/.codex` |
| `--mount-opencode` | `~/.config/opencode` | `/root/.config/opencode` |
| `--mount-pi` | `~/.pi` | `/root/.pi` |
| `--mount-ssh` | `~/.ssh` | `/root/.ssh` (read-only) |

- Never commit API keys or credential files to the repository.
- Use environment variables or host mounts to supply secrets.
- The `ai` preset mounts SSH, Claude, Codex, OpenCode, and Pi config together;
  use it only when all those directories exist on the host.

### SSH Keys

SSH keys are mounted read-only via `--mount-ssh` (`~/.ssh` → `/root/.ssh`).

- Keep host SSH keys secure; the container can read them while running.
- Use `ssh-agent` forwarding instead of key files when possible.
- Never store SSH private keys inside the image or in build context.

### Docker Socket Exposure

The image contains the Docker **client**, not a daemon. Mounting the host socket
enables the container to control the host Docker daemon:

```bash
cdev run --pull --workspace "$PWD" --mount-docker-socket
```

Access to `/var/run/docker.sock` can start privileged containers and mount host
paths. **Enable it only for trusted projects.** The `full` preset enables this
mount in addition to all `ai` mounts.

### Root Execution

Containers run as **root** by default. This is intentional — most AI tools and
package installers expect root privileges.

- If you need non-root operation, build with `--build-arg DEV_CREATE_NONROOT_USER=1`
  and run with `--nonroot` to map the workspace to `/home/dev`.
- Published GHCR images remain root-by-default; non-root support requires a local
  or custom build.
- Be aware that root-owned workspace files can affect host permissions.

### Floating Beta Dependencies

This project installs AI CLIs at **npm `@latest`** at build time. Package
versions are **not pinned** — every build fetches the newest release.

- This ensures you always have the latest features but means builds can break
  on upstream regressions.
- CI passes `AI_TOOLS_CACHEBUST` to prevent stale Docker cache from serving
  older versions.
- Inside a running container, run `update-ai-tools` to upgrade CLIs without
  rebuilding.
- Pin specific versions in your own fork if you need reproducibility.

### Image Pinning

Always pin to specific image tags instead of `latest`:

```bash
# Pull a specific tag
docker pull ghcr.io/luongnv89/u2604dev:v1.2.3

# Or pin to a commit SHA
docker pull ghcr.io/luongnv89/u2604dev:<git-sha>
```

Published images include `latest`, `:sha`, branch, and semver tags. The CI
workflow builds and publishes images on every push to `main`.

## Scope

This policy applies to:

- The Docker images published in this repository
- CI/CD workflows
- GitHub Actions configurations
- Shell scripts in the repository

## Out of Scope

- Vulnerabilities in third-party base images (Ubuntu, Debian, Node.js, Python,
  etc.)
- Vulnerabilities in upstream packages (report to respective maintainers)
- Social engineering attacks

## Related Resources

- [GitHub Security Advisories](https://docs.github.com/en/code-security/security-advisories/working-with-repository-security-advisories)
- [Docker Security](https://docs.docker.com/engine/security/)
- [Trivy Scanner](https://github.com/aquasecurity/trivy)
