---
name: opencode-docker-dev
description: "Run OpenCode in a disposable luongnv89/docker-dev container; never mounts SSH keys or GH tokens. Use to isolate OpenCode or dodge rate limits. Don't use for opencode.ai (opencode-runner), Herdr (herdr-agent-comms), or the project's app (run)."
license: MIT
compatibility: "Requires Docker (Desktop or Engine) on PATH and running. Interactive mode additionally needs `cdev` (auto-installable from luongnv89/docker-dev) plus a pane-management skill (herdr-agent-comms or tmux-agent-comms)."
effort: medium
metadata:
  version: 1.1.0
  author: "Luong NGUYEN <luongnv89@gmail.com>"
---

# OpenCode Docker Dev

Run OpenCode sandboxed inside a disposable [luongnv89/docker-dev](https://github.com/luongnv89/docker-dev)
container for a local project — isolating it from host SSH keys and GitHub
tokens by construction, not by discipline. **The redline: this skill never
mounts `~/.ssh` and never injects a `GH_TOKEN` or `gh auth token`.** Design
every task to stop before the step that would need push/publish credentials;
see `references/mounts-and-credentials.md` for why and what to do if a task
genuinely needs them anyway.

## When to Use

- Run OpenCode against a project without exposing the host's `~/.ssh` or
  `GH_TOKEN` to it
- OpenCode keeps hitting provider rate limits and the task needs a fresh,
  disposable session
- Confirm a task finished cleanly before letting anything ship — this skill's
  workflow ends at "verify the host diff," never at "push"

## Repo Sync Before Edits (mandatory)

The container only sees whatever is on disk at `docker run` time — sync the
host repo *before* launching, not after:

```bash
branch="$(git -C "$PROJECT_DIR" rev-parse --abbrev-ref HEAD)"
git -C "$PROJECT_DIR" fetch origin && git -C "$PROJECT_DIR" pull --rebase origin "$branch"
```

If the tree is dirty: stash (`-u`), sync, pop. If `origin` is missing or the
rebase conflicts, stop and ask the user before continuing.

## Choose a mode

| Mode | Use when | Go to |
|---|---|---|
| **One-shot** (default) | Single task, no need to watch it work | "One-shot mode" below |
| **Interactive** | User wants to watch live or steer mid-task | `references/interactive-mode.md` |

Default to one-shot — it needs no pane-management skill, has no TUI-timing
gotchas, and its completion signal is a plain process exit code. Reach for
interactive mode only when the task genuinely needs a human in the loop
mid-run.

## One-shot mode

`scripts/run_opencode.sh` runs `opencode run --auto` inside `docker run --rm`:
one process, one exit code, output on stdout — no polling, no TUI, no
permission dialogs to click through (`--auto` handles them; see
`references/mounts-and-credentials.md` → _Why `--auto` is safe here_).

### Step 1 — Decide mounts

Every run mounts the project directory (`/workspace`) and `~/.config/opencode`
(OpenCode's own auth). Add flags only for what the task needs:

- `--with-claude-skills` — task must read/follow a **user-level** Claude Code
  skill living under `~/.claude/skills/` (mounts `~/.claude` **and**
  `~/.agents`, read-only — see the symlink gotcha in
  `references/mounts-and-credentials.md` before assuming one mount is
  enough). Skip this flag for a **project-local** skill/convention doc
  (e.g. `AGENTS.md`, `.claude/skills/` inside the repo itself, a
  CONTRIBUTING.md) — it's already inside `/workspace` via the project mount,
  no extra flag needed.
- `--with-git-identity` — task will `git commit` and needs correct author
  identity (mounts `~/.gitconfig`, read-only)

OpenCode has no native "skill" concept — mounting a directory only makes a
file *readable*, not *followed*. When using `--with-claude-skills`, the
`--message` must explicitly point OpenCode at it, e.g.: `"Read
/root/.claude/skills/<name>/SKILL.md and follow it as your playbook for this
task."`

Never add a flag or workaround for SSH/GH access — that's the redline above.

### Step 2 — Run it

```bash
bash scripts/run_opencode.sh --project /path/to/project \
  --message "<task text>" \
  [--with-claude-skills] [--with-git-identity]
```

For task text too long or complex for a shell argument, write it to a file
and attach it instead, with a short message pointing at it:

```bash
bash scripts/run_opencode.sh --project /path/to/project \
  --message "Follow the attached file's instructions exactly." \
  --file /path/to/task.txt
```

`preflight.sh` (called automatically) checks the Docker daemon is running —
starting it on macOS if not — and pulls the image on first use. Both scripts
print a specific error with a fix on failure; read the message before
retrying blind. Common failures and fixes: `references/troubleshooting.md`.

### Step 3 — Verify before anything ships

**Completion criterion: exit code 0 from `run_opencode.sh`, and the printed
transcript shows the task actually finished** (not a mid-task rate-limit
retry loop — see `references/troubleshooting.md` if it stalls). Exit 0 means
the container ran without error; it does **not** mean the change is correct
or safe to push.

Before treating the run as done:

1. `git -C "$PROJECT_DIR" status --short` and `git diff` — review every
   changed file, not just the ones the task description mentioned.
2. If the task touched dependency files (`package.json`, lockfiles, etc.),
   diff them specifically for container-architecture leakage — a Linux
   binary promoted into a real (non-optional) dependency has shipped from
   this exact setup before. See `references/troubleshooting.md`.
3. Anything beyond a local commit (push, release, publish) is a **separate,
   human-reviewed step on the host** — never something the container did
   itself, by construction (the redline above).

## Interactive mode

For watching OpenCode work live or steering it mid-task. Needs a real
pane/terminal the agent can repeatedly read and write — pair this skill with
**herdr-agent-comms** or **tmux-agent-comms** for the pane mechanics. Read
`references/interactive-mode.md` for what's specific to OpenCode-in-a-container
on top of those primitives: TUI readiness timing (sending too early drops the
message, or worse, a second premature send exits OpenCode entirely),
permission-dialog handling, and completion detection (container processes are
invisible to host-level agent-status tracking — poll the transcript or use a
sentinel string instead).

## Example

```bash
bash scripts/run_opencode.sh --project ~/code/my-app \
  --message "Add input validation to the signup form and run the test suite." \
  --with-git-identity
```

Expected output: `preflight.sh` reports the Docker daemon running and the
image present, `run_opencode.sh` streams OpenCode's task transcript, and the
process exits `0`. Back on the host, `git -C ~/code/my-app diff` shows the
validation change and its test — nothing else. If the transcript instead
shows a rate-limit retry loop, treat the run as unfinished (see
`references/troubleshooting.md`), not as a pass.

## Acceptance Criteria

- [ ] `run_opencode.sh` exits `0`, and the transcript shows the task actually
      completed (not a stalled rate-limit retry)
- [ ] `git -C "$PROJECT_DIR" status --short` and `git diff` were reviewed on
      the host before anything is committed or pushed
- [ ] No `~/.ssh` mount and no `GH_TOKEN`/`gh auth token` injection appear in
      the `docker run` invocation, in either mode
- [ ] Dependency-file diffs (`package.json`, lockfiles) were checked for
      container-only binaries before treating the run as safe to merge

**Edge cases this skill accounts for:** a dirty host repo before sync (stash
`-u`, sync, pop); an already-running container from a prior task (name
collision — see `references/troubleshooting.md`); a TUI message sent before
the interactive pane finishes booting, which drops the message or exits
OpenCode entirely (see `references/interactive-mode.md`).

## Step Completion Report

```
◆ OpenCode Docker Dev (one-shot run)
··································································
  Docker daemon:        √ pass (docker info)
  Image ready:          √ pass (ghcr.io/luongnv89/u2604dev:latest)
  Mounts:                √ workspace, opencode config [+ claude skills] [+ git identity]
  Credential redline:    √ no SSH key, no GH token mounted
  Task exit code:        √ 0 | × <N> — <error from output>
  Host diff reviewed:    √ pass (git status/diff checked) | — n/a (no changes)
  ____________________________
  Result:               PASS | FAIL
```

Adapt for interactive mode: replace `Task exit code` with `Sentinel/transcript
completion` and add `Permission dialogs handled` if any appeared.
