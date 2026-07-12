# u2604dev-opencode

**Compatibility image** — thin alias of [`u2604dev`](../u2604dev/README.md). OpenCode, Pi, Claude Code, Codex, pi-extensions, and herdr are already baked into `u2604dev` via [`common/install-ai-tools.sh`](../../common/install-ai-tools.sh). This directory only adds default workspace/config directories and a distinct image name for workflows that still reference `u2604dev-opencode`.

> **Prefer `u2604dev` + `cdev`.** For day-to-day use, run `cdev run --image u2604dev` (or `u2204dev` / `u2404dev`) with `--mount-opencode`, `--mount-pi`, and related flags — see [root README](../../README.md#using-the-cdev-cli-recommended). Building `u2604dev-opencode` requires a local `u2604dev:latest` base (`FROM u2604dev:latest` in the Dockerfile).

## What the Dockerfile does

| Step | Effect |
|------|--------|
| `FROM u2604dev:latest` | Inherits full dev + AI tooling from `u2604dev` |
| `RUN mkdir -p /workspace /root/.config/opencode` | Ensures mount targets exist |
| `CMD ["zsh"]` | Same interactive shell as `u2604dev` |

No extra OpenCode install layer — the README previously described a separate install; that no longer matches the image.

## Quick Start

**Recommended** (no separate opencode image):

```bash
cdev run --image u2604dev --workspace "$PWD" --mount-ssh --mount-opencode --mount-pi
```

If you still need the `u2604dev-opencode` tag (CI, legacy scripts):

```bash
# From repo root — build u2604dev first
docker build -t u2604dev -f u2604dev/Dockerfile .
docker build -t u2604dev-opencode:latest -f u2604dev-opencode/Dockerfile .

cdev run --image u2604dev-opencode --workspace "$PWD" --mount-ssh --mount-opencode
```

Or plain `docker run` with the same mounts as `cdev` documents in [cli/README.md](../../cli/README.md).

## Legacy helper

[`run.sh`](run.sh) wraps `docker run` with optional workspace, SSH, and OpenCode config paths. Prefer **`cdev run --image u2604dev-opencode`** (or `u2604dev`) when the CLI is installed.

## Related

- [u2604dev/README.md](../u2604dev/README.md) — primary Ubuntu 26.04 dev image
- [cli/README.md](../../cli/README.md) — `cdev` launcher
- [CHANGELOG.md](../../CHANGELOG.md) — `scripts/docker-dev` deprecated in favor of `cdev`