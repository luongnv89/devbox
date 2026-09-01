# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.0.x (devbox — `ghcr.io/luongnv89/devbox:latest` + `sha-*`) | :white_check_mark: |

The only published artifact is the single `devbox` image from the root `Dockerfile` (Ubuntu 26.04). Legacy images (`u2204dev`/`u2404dev`/`u2604dev`/`devbox` Debian variant) and the `cdev` helper are removed.

## Reporting a Vulnerability

We take the security of devbox seriously. If you believe you have found a security vulnerability, please report it responsibly.

### How to Report

1. **Do NOT** open a public issue
2. Email your report to: **luongnv89@outlook.com**
3. Include as much detail as possible:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Any proposed fixes (if you have them)

### What to Expect

1. **Acknowledgment** within 24–48 hours
2. **Assessment** of severity
3. **Update** on progress
4. **Credit** with your permission in the advisory

### Scope

- The `devbox` Docker image (`ghcr.io/luongnv89/devbox`) and its `Dockerfile`
- CI workflow `.github/workflows/devbox.yml`
- Entrypoint and shell/tooling installed in the image

### Out of Scope

- Vulnerabilities in third-party base images (Ubuntu, Node.js, Python, etc.)
- Upstream npm packages (report to respective maintainers)
- Social engineering attacks

## Security Model for devbox

devbox runs as `root` by default with a developer-trusted entrypoint (`/entrypoint.sh`, `TZ` honor, `RUN_AS` root vs `dev`, SSH perms, mount announcements). The model is **convenience for trusted local projects**, not sandboxing — do not run untrusted code without additional isolation.

### Credential mounts

- Credentials are **never** baked into the image. Mount only the config your tool needs at run time: `~/.agents` → `/root/.agents`, `~/.claude` → `/root/.claude`, `~/.codex` → `/root/.codex`, `~/.pi` → `/root/.pi`, `~/.config/opencode` → `/root/.config/opencode`.
- Host bearer tokens (`~/.claude`, `~/.codex`, `~/.config/opencode`, `~/.pi`) grant API access — mount the narrowest set, prefer `:ro` where the tool tolerates it, and never commit these directories.
- The entrypoint only announces mounts (`[dev] Mounted …`) — it does not scrub, rotate, or encrypt secrets.

### SSH keys — read-only mount

- When `git+ssh` is needed, mount `~/.ssh` **read-only**:

  ```bash
  docker run --rm -it -v "$PWD":/workspace -v "$HOME/.ssh":/root/.ssh:ro ghcr.io/luongnv89/devbox:latest zsh
  ```

- Entrypoint fixes perms when the mount is non-empty (`700 ~/.ssh`, `600 ~/.ssh/id_*`, `644 ~/.ssh/*.pub`).
- With a `:ro` mount a compromised container cannot overwrite host keys; without it, it can.

### Docker socket exposure

- The image ships the **Docker client only** (`docker.io` + `docker-compose-v2` plugin), not a daemon.
- Mounting `/var/run/docker.sock` (`-v /var/run/docker.sock:/var/run/docker.sock`) gives the container **control of the host daemon**: it can start privileged containers, mount arbitrary host paths, and escape the container boundary. Enable only for trusted projects and prefer project-scoped Docker contexts over socket mounting when possible.

### Root execution and workspace ownership

- Containers run as `root` (`/etc/docker-dev-run-as` contains `root`; `WORKDIR /workspace`). Files created in the bind-mounted `/workspace` are **owned by root on the host**. Fix after exit with `sudo chown -R "$(id -u):$(id -g)" .`, or build a non-root image locally:

  ```bash
  docker build --build-arg DEV_CREATE_NONROOT_USER=1 --build-arg DEV_UID="$(id -u)" --build-arg DEV_GID="$(id -g)" -t devbox:nonroot .
  docker run --rm -it --user "$(id -u):$(id -g)" -v "$PWD":/workspace devbox:nonroot zsh
  ```

  Then mount host configs under `/home/dev/...` (e.g., `-v "$HOME/.ssh":/home/dev/.ssh:ro`).
- Prefer `--user` and avoid `sudo` inside the container when handling untrusted inputs.

### Floating beta dependencies and image pinning

- `opencode2` comes from `npm install -g @opencode-ai/cli@beta` at **build time**; `update-ai-tools` inside the container upgrades to `@latest`/`@beta` again. A rebuild on a different date may pull a different beta.
- **For reproducible CI, pin to the immutable SHA tag** published on pushes to `main`:

  ```bash
  docker pull ghcr.io/luongnv89/devbox:sha-<git-sha>
  # not :latest (floating)
  ```

- Other AI CLIs (`claude`, `codex`, `pi`, `asm`) are installed at `npm @latest` via `AI_TOOLS_CACHEBUST=$GITHUB_RUN_ID` in CI; the same floating-vs-pinning trade-off applies.
- The `Dockerfile` is self-contained and has no `COPY` from legacy `common/` etc., so the only floating surface is the npm registry at build time — pin the **image SHA**, not the npm version, for deployment reproducibility.

## General Best Practices

1. **Pin the image SHA** for production CI (`ghcr.io/luongnv89/devbox:sha-...`), not `:latest`
2. **Scan images** (`trivy image ghcr.io/luongnv89/devbox:latest`) before deployment — CI publishes provenance attestations on pushes to `main`
3. **Minimal mounts** — mount only required AI configs and prefer `:ro` for `~/.ssh`
4. **Keep updated** — `docker pull ghcr.io/luongnv89/devbox:latest` regularly, or rebuild locally with `AI_VERIFY_MODE=strict`
5. **No secrets in Docker build args** — `AI_TOOLS_CACHEBUST` is a cache-bust integer, not a secret; pass API keys as runtime `-e` variables or mounts, never as `ARG`/`ENV` in the image

## Related Resources

- [GitHub Security Advisories](https://docs.github.com/en/code-security/security-advisories/working-with-repository-security-advisories)
- [Docker Security](https://docs.docker.com/engine/security/)
- [Trivy Scanner](https://github.com/aquasecurity/trivy)
