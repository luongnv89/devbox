# Development setup

Contributor workflow for this repository. Validate: `./scripts/validate-dev-environment.sh --check`.

## Prerequisites

- **Docker** — engine or Desktop; required for image build tests (`scripts/tasks/test.sh:6-10` skips if missing).
- **Git** — clone, branch, PR workflow (`CONTRIBUTING.md`).
- **Shell tooling** — `shfmt`, `shellcheck`, `hadolint` used by `scripts/tasks/lint.sh` and `format.sh` (invoked from `scripts/pre-commit.sh:20-21`).

Optional: GitHub PAT with `read:packages` to pull from GHCR (`README.md` authentication section).

## Clone and branch

```bash
git clone https://github.com/YOUR-USERNAME/docker-dev.git
cd docker-dev
git remote add upstream https://github.com/luongnv89/docker-dev.git
git checkout -b feat/my-change
```

(`CONTRIBUTING.md` fork/upstream steps.)

## Pre-commit checks

Install the hook:

```bash
ln -sf ../../scripts/pre-commit.sh .git/hooks/pre-commit
```

Or run manually:

```bash
./scripts/pre-commit.sh
```

Pipeline (`scripts/pre-commit.sh:20-23`): **Format** → **Lint** → **Test** → **Cleanup**.

- **Test** builds `u2204dev:pre-commit` from repo root and runs `scripts/tasks/test-docker-dev-cli.sh` (`scripts/tasks/test.sh:11-18`).
- **Oh My Zsh regression:** `./scripts/validate-ohmyzsh-plugins.sh` (also covered by dev-environment validator).

## Build images locally

Always use repo root as context:

```bash
docker build -t test-u2604dev -f u2604dev/Dockerfile .
docker build --build-arg DEV_IMAGE_PROFILE=minimal -t test-u2604dev:minimal -f u2604dev/Dockerfile .
docker build --build-arg AI_VERIFY_MODE=strict -f u2604dev/Dockerfile .
docker build --build-arg DEV_IMAGE_PROFILE=standard \
  -t test-devbox:latest-standard -f devbox/Dockerfile .
```

Non-root image (`common/setup-dev-user.sh:3-7`):

```bash
docker build \
  --build-arg DEV_CREATE_NONROOT_USER=1 \
  --build-arg DEV_UID="$(id -u)" --build-arg DEV_GID="$(id -g)" \
  -t test-u2604dev:nonroot -f u2604dev/Dockerfile .
```

## `cdev` from a clone

```bash
export CDEV_REPO="$PWD"
./cli/bin/cdev list
./cli/bin/cdev run --image u2604dev -w "$PWD" --build
```

Or `./install.sh` then `cdev` on `PATH` (`install.sh:54-61` local checkout path).

CLI tests:

```bash
./scripts/tasks/test-docker-dev-cli.sh
```

(`cli/README.md` development section.)

## CI parity

Workflow: `.github/workflows/build-images.yml` — four images × three profiles, `linux/amd64` + `linux/arm64`, `DEV_IMAGE_PROFILE` + `AI_VERIFY_MODE=strict` on build (`.github/workflows/build-images.yml`).

CI and `cdev build` pass `AI_TOOLS_CACHEBUST` so AI CLIs install at npm `@latest`. In a running container, `update-ai-tools` upgrades the same set.

## Documentation

When changing behavior, update root `README.md`, the affected image `README.md`, `cli/README.md`, and `CHANGELOG.md`. Architecture overview: [architecture.md](architecture.md).
