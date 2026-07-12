# Troubleshooting

Symptoms and fixes discovered while validating runbooks (`scripts/validate-*.sh --check`). Do not treat this as exhaustive product support.

## `cdev` not found after install

- **Cause:** `install.sh` installs the wrapper to `${DOCKER_DEV_PREFIX:-$HOME/.local}/bin` (`install.sh:7-8`, `install.sh:38-43`); that directory may not be on `PATH`.
- **Fix:** `export PATH="${HOME}/.local/bin:$PATH"` (or your custom `DOCKER_DEV_PREFIX/bin`). Re-run `install.sh` from a clone if `cli/bin/cdev` is missing (`install.sh:24-27`).
- **Seen during:** `validate-cdev-install.sh --check`

## Pre-commit Docker build fails: wrong build context

- **Cause:** `docker build -f u2604dev/Dockerfile u2604dev` omits `common/` at context root; Dockerfiles `COPY` from `common/` (`u2604dev/Dockerfile:9-14`).
- **Fix:** `docker build -t test-u2604dev -f u2604dev/Dockerfile .` from repo root (matches `scripts/tasks/test.sh:15-16`).
- **Seen during:** doc reconciliation / local builds

## validate-ohmyzsh-plugins.sh fails: plugins= not in Dockerfile

- **Cause:** Oh My Zsh `plugins=(…)` is applied in `common/dev-image-base.sh` via `sed` on `/root/.zshrc` (`common/dev-image-base.sh:115-116`), not duplicated in each image Dockerfile.
- **Fix:** Run validator that checks `dev-image-base.sh` (updated `scripts/validate-ohmyzsh-plugins.sh`). Ensure thin Dockerfiles still call `dev-image-base.sh`.
- **Seen during:** `validate-dev-environment.sh --check`

## Oh My Zsh `docker` plugin without Docker CLI

- **Cause:** `plugins=(… docker …)` requires the Docker CLI on PATH; images install it via `install-docker-cli.sh` (`scripts/validate-ohmyzsh-plugins.sh:17-19`).
- **Fix:** Ensure each dev `Dockerfile` invokes `dev-image-base.sh` (which runs `install-docker-cli.sh`). Run `./scripts/validate-ohmyzsh-plugins.sh`.
- **Seen during:** `validate-ohmyzsh-plugins.sh` (referenced from dev-environment validation)
