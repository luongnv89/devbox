<p align="center"><img src="logo.png?raw=true" alt="devbox logo" width="400"></p>

[![Build and Publish devbox](https://github.com/luongnv89/devbox/actions/workflows/devbox.yml/badge.svg)](https://github.com/luongnv89/devbox/actions/workflows/devbox.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Release](https://img.shields.io/badge/release-1.0.0-informational.svg)](https://github.com/luongnv89/devbox/releases/tag/v1.0.0)

# devbox — single dev container

A fast, lightweight, all-in-one development container tailored for **Node.js**, **Python**, and **AI Coding Agents**. Plug your project workspace in and start developing immediately without polluting your host machine.

Published to GitHub Container Registry as `ghcr.io/luongnv89/devbox`.

---

## 🛠 Included Environment

- **Base OS:** Ubuntu 26.04 (`LANG=en_US.UTF-8`, `TZ=Etc/UTC`, `WORKDIR /workspace`, runs as `root` with `zsh`).
- **Shell & Terminal:** `zsh`, Oh My Zsh (plugins: `git`, `npm`, `pip`, `python`, `zsh-autosuggestions`, `zsh-completions`, `zsh-syntax-highlighting`), `fzf` key bindings (`Ctrl-R`, `Ctrl-T`, `Alt-C`) backed by `fd`.

  > Nerd Font glyphs are rendered by your **host** terminal, so no font is shipped inside the image. Install [JetBrainsMono Nerd Font](https://github.com/ryanoasis/nerd-fonts) on the host if you want icon glyphs.
- **Editor & Utilities:** Vim with `vim-plug` (`nerdtree`, `vim-gitgutter`, `fzf`, `fzf.vim`, `vim-surround`, `auto-pairs`), `btop`, `ripgrep` (`rg`), `bat`, `fzf`, `fd`, `jq`, `sudo`, `gosu`.
- **Runtimes:**
  - **Node.js LTS** + `corepack` (`pnpm`, `yarn`).
  - **Python 3** (`python3-venv`, `python3-pip`, `python3-dev`) + **`uv`** (ultra-fast package manager). `pip install` works directly against the system interpreter (`PIP_BREAK_SYSTEM_PACKAGES=1`, safe inside a disposable container); use `python3 -m venv` or `uv venv` for per-project isolation.
- **AI Coding Agents & Extensions:**
  - **`opencode`**: OpenCode AI CLI (installed via official `opencode.ai` installer).
  - **`claude`**: Claude Code (`@anthropic-ai/claude-code`).
  - **`codex`**: OpenAI Codex CLI (`@openai/codex`).
  - **`pi`**: Pi Coding Agent (installed via official `pi.dev` installer).
    - `npm:opencode-pi`
    - `npm:statusline-pi`
    - `npm:timestamp-pi`
    - `npm:pi-subagents`
  - **`herdr`**: AI agent orchestration tool.
  - **`asm`**: Agent Skill Manager (`agent-skill-manager`) — install, search, audit, and organize skills across every supported agent.
  - **Skill collections:** [`luongnv89/skills`](https://github.com/luongnv89/skills) and [`luongnv89/idd`](https://github.com/luongnv89/idd) are installed at build time by `asm` as real copies for both **Claude Code** (`~/.claude/skills`) and the **shared agents directory** (`~/.agents/skills`).
  - **`context-stats`**: Claude Code context/token analytics — the status line is pre-configured in `~/.claude/settings.json` (`claude-statusline`), with `context-stats graph`, `context-stats report`, and `context-stats sessions` for deep dives.
- **Developer Tools:** `git` + `git-lfs` + `openssh-client`, `gh` (GitHub CLI).

---

## 🚀 Quickstart

### Ephemeral Container (disposable — removed on exit)

```bash
docker run --rm -it -v "$PWD":/workspace ghcr.io/luongnv89/devbox:latest zsh
```

### Named Container (background / re-enterable)

```bash
# Start background container
docker run -d --name my-dev -v "$PWD":/workspace ghcr.io/luongnv89/devbox:latest sleep infinity

# Enter interactive shell
docker exec -it my-dev zsh
```

---

## 🤖 AI Tools & Configuration Mounts

Credentials are **not stored in the image**. The skill collections are baked in; mount your host configurations to override them:

| Host Path | Container Path | Purpose |
| :--- | :--- | :--- |
| `~/.config/opencode` | `/root/.config/opencode` | `opencode` config & auth token |
| `~/.claude` | `/root/.claude` | `claude` config & auth |
| `~/.codex` | `/root/.codex` | `codex` config & auth |
| `~/.pi` | `/root/.pi` | `pi` settings, auth, extensions & skills |
| `~/.agents` | `/root/.agents` | Shared agent skills |
| `~/.ssh` | `/root/.ssh:ro` | SSH keys for Git (mounted read-only) |

> Mounting `~/.claude` or `~/.agents` replaces the baked-in skill collections — and, for `~/.claude`, the pre-configured `context-stats` status line — with your host's content.

### Example with AI & SSH Mounts

```bash
docker run --rm -it \
  -v "$PWD":/workspace \
  -v "$HOME/.config/opencode":/root/.config/opencode \
  -v "$HOME/.claude":/root/.claude \
  -v "$HOME/.codex":/root/.codex \
  -v "$HOME/.pi":/root/.pi \
  -v "$HOME/.agents":/root/.agents \
  -v "$HOME/.ssh":/root/.ssh:ro \
  ghcr.io/luongnv89/devbox:latest zsh
```

### Refreshing AI CLIs

To upgrade `opencode`, `claude`, `codex`, `pi`, `pi extensions`, `herdr`, `asm` (plus every `asm`-managed skill via `asm update --yes`), and `context-stats` inside a running container:

```bash
update-ai-tools
```

Manage the baked-in skills directly with `asm`:

```bash
asm list                          # every installed skill, every agent
asm search "code review"          # search installed and catalog skills
asm install github:owner/repo --all -p claude -y
asm update --yes                  # update outdated skills
```

---

## 🌐 Port Forwarding (Dev Servers)

When running dev servers inside the container (e.g. Vite, Next.js, FastAPI), ensure the server listens on `0.0.0.0` and publish the port:

```bash
# Vite / Next.js
docker run --rm -it -v "$PWD":/workspace -p 5173:5173 ghcr.io/luongnv89/devbox:latest zsh
# inside: npm run dev -- --host 0.0.0.0 --port 5173

# FastAPI / Python
docker run --rm -it -v "$PWD":/workspace -p 8000:8000 ghcr.io/luongnv89/devbox:latest zsh
# inside: uvicorn main:app --host 0.0.0.0 --port 8000
```

---

## 📦 Bind-Mount Notes

The image sets `git config --global --add safe.directory '*'` to prevent "dubious ownership" errors when bind-mounting host repos (the host UID does not match the container's root UID). This disables Git's ownership verification for mounted directories — acceptable for disposable dev containers, but be aware that a malicious file in a bind mount will not trigger Git's usual safety warnings.

## 🔨 Building Locally

```bash
docker build -t devbox .
```

---

## 📄 License & Docs

- [LICENSE](LICENSE) (MIT)
- [CONTRIBUTING.md](CONTRIBUTING.md)
- [SECURITY.md](SECURITY.md)
test from devbox
