# Mounts and credentials

## The redline: never mount `~/.ssh`, never inject a GitHub token

`run_opencode.sh` has no flag for either, on purpose. OpenCode running inside
the container is a fully autonomous agent with arbitrary code execution
inside whatever it can reach. An SSH private key or a `GH_TOKEN` reaches
**every repo and org that credential is scoped to** — far past the one
project directory you mounted. Claude Code's own permission classifier blocks
both of these when attempted directly, and that verdict is correct.

**Design tasks to stop before the step that needs them.** For a release-style
task: version bump, changelog, local commit, local tag — then stop. Push and
`gh release create` happen on the host afterward, after a human reviews the
diff. This is not a limitation to work around; it's the point — a bad or
compromised task run can, at worst, leave a mess in a disposable container
and an unpushed local commit, never a pushed commit, a force-push, or a
leaked credential.

If a task genuinely needs push/publish access inside the container, that is a
**separate, explicit, user-performed action** — the user runs their own
`docker run -v ~/.ssh:... -e GH_TOKEN=...` invocation outside this skill's
scripts. Don't add a flag that automates it, and don't work around a
classifier block by re-deriving the credential a different way (e.g. reading
`gh auth token` into a file the container can reach) — that's the same
exposure with extra steps.

## Standard mounts

| Mount | Container path | When |
|---|---|---|
| project directory | `/workspace` | always — the task's target |
| `~/.config/opencode` | `/root/.config/opencode-host` (ro) + `opencode-config` volume → `/root/.config/opencode` | always — host config mounted read-only, copied to writable volume at startup to isolate usage tracking |
| `~/.claude` (ro) | `/root/.claude` | `--with-claude-skills` — task needs to read/follow a specific Claude Code skill |
| `~/.agents` (ro) | `/root/.agents` | auto-added alongside `~/.claude` when it exists — see the symlink gotcha below |
| `~/.gitconfig` (ro) | `/root/.gitconfig` | `--with-git-identity` — task will `git commit` and needs correct author identity |
| task file (ro) | `/scratch/<name>` | `--file PATH` — see SKILL.md → One-shot mode |

### Usage tracking isolation

`~/.config/opencode` is mounted read-only at `/root/.config/opencode-host`, then
copied into a writable named volume (`opencode-config`) at `/root/.config/opencode`
at container startup. This keeps usage tracking and state writes isolated from the
host — the container gets a fresh local database while still using your full config.

The `run_opencode.sh` script handles this automatically; you don't need to manage
the named volume yourself.

`run_opencode.sh` builds these automatically from its flags — read it before
reimplementing the logic by hand.

## The `~/.claude` symlink gotcha

Skills installed under `~/.claude/skills/<name>` are frequently symlinks to
`~/.agents/skills/<name>` (e.g. `~/.claude/skills/release-manager ->
../../.agents/skills/release-manager`). Mount `~/.claude` alone and the
symlink still shows up in `ls`, but resolving it inside the container fails —
the target lives outside every mounted path. The failure mode is confusing
because it looks like a permissions issue, not a missing mount:

```
$ ls /root/.claude/skills/release-manager/SKILL.md
ls: cannot access '/root/.claude/skills/release-manager/': No such file or directory
```

Fix: mount `~/.agents` read-only alongside `~/.claude` whenever both exist.
`run_opencode.sh --with-claude-skills` does this automatically — it's the
reason the flag checks for `~/.agents` at all, not just `~/.claude`. If a task
still can't read a skill file after both are mounted, the skill likely lives
somewhere else entirely (a plugin directory, a project-local
`.claude/skills/`) — check the real symlink target on the host with
`readlink ~/.claude/skills/<name>` before assuming the mount is wrong.

## Why `--auto` is safe here specifically

`opencode run` requires `--auto` to run non-interactively — without it,
OpenCode blocks on a permission dialog with nothing attached to answer it,
and the container hangs until the process is killed. OpenCode's own `--help`
labels `--auto` "dangerous," and outside this setup it would be: it
auto-approves every action the agent wants to take, including ones you'd
normally want to review.

Inside this skill's containers, `--auto` is safe **because the mounts already
enforce the boundary** — auto-approving actions inside a sandbox that
physically cannot reach `~/.ssh`, a GitHub token, or any directory besides
`/workspace`, `/root/.config/opencode`, and (optionally) read-only config
bounds the blast radius to "OpenCode did something wrong inside the mounted
project directory," which `git status`/`git diff` on the host catches before
anything ships. The safety property comes from the mount list, not from
`--auto` itself — get the mount list wrong (e.g. add `~/.ssh` "just for this
one task") and `--auto` stops being safe.
