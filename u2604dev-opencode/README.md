# u2604dev-opencode (deprecated)

**Decision (issue #15):** The `u2604dev-opencode` image name is **deprecated**. It was a thin `FROM u2604dev:latest` layer with no extra packages; OpenCode, Pi, Claude Code, Codex, pi-extensions, and herdr are already in [`u2604dev`](../u2604dev/README.md) via [`common/install-ai-tools.sh`](../../common/install-ai-tools.sh).

## Migration path

Use **`u2604dev`** (or `u2204dev` / `u2404dev`) with `cdev` mounts:

```bash
cdev run --image u2604dev --workspace "$PWD" \
  --mount-ssh --mount-opencode --mount-pi
```

Legacy scripts may pass `--image u2604dev-opencode`; `cdev` resolves that to `u2604dev` and prints a deprecation notice.

## Optional local tag (not published to GHCR)

If you still need a distinct Docker tag for local workflows, build from this directory after `u2604dev:latest` exists:

```bash
docker build -t u2604dev -f u2604dev/Dockerfile .
docker build -t u2604dev-opencode:latest -f u2604dev-opencode/Dockerfile .
```

Prefer building only `u2604dev` and using `cdev run --image u2604dev`.

## Legacy helper

[`run.sh`](run.sh) wraps `docker run` against **`u2604dev:latest`**. Prefer **`cdev run --image u2604dev`**.

## Related

- [u2604dev/README.md](../u2604dev/README.md) — primary Ubuntu 26.04 dev image
- [cli/README.md](../../cli/README.md) — `cdev` launcher
- [CHANGELOG.md](../../CHANGELOG.md)