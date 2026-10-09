# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **AI Coding Agents:** `claude` (Claude Code, `@anthropic-ai/claude-code`) and `codex` (OpenAI Codex CLI, `@openai/codex`) baked into the image, with MOTD version lines, `update-ai-tools` upgrade paths, entrypoint mount announcements (`~/.claude`, `~/.codex`), and e2e test coverage
- **Agent skills:** `asm` (agent-skill-manager) baked into the image; the curated collections `luongnv89/skills` and `luongnv89/idd` are installed at build time for Claude Code (`~/.claude/skills`) and the shared agents directory (`~/.agents/skills`), with build-time presence checks and e2e coverage
- **context-stats:** installed via pip with the Claude Code status line pre-wired (`~/.claude/settings.json` → `claude-statusline`), verified during the build by `context-stats doctor`, with a MOTD version line and e2e coverage

### Changed
- **opencode:** replaced the `@opencode-ai/cli@beta` community fork (`opencode2` binary) with the official release via the `opencode.ai/v2` install script → `opencode` (v2.x); the installer's legacy `opencode2` compat shim is removed from the image
- **update-ai-tools:** also upgrades `asm`, runs `asm update --yes` for the installed skill collections, and upgrades `context-stats`
- **devbox-launch.sh:** SSH config volume is now refreshed on every launch instead of created once; git identity is read from the host's `git config` instead of a hardcoded maintainer identity; interactive containers run with `--rm` (detached containers keep running via `sleep infinity`); new `-D/--dry-run` flag prints the docker command without executing it

### Fixed
- **devbox-launch.sh on macOS:** `sed -i` (GNU-only) crashed the script under `set -e` whenever `~/.ssh/config` existed and the SSH volume was absent; portable `sed -i.bak` + `$HOME`-based rewrites (previously hardcoded `/home/montimage`, which never matched `/Users/*` paths)
- **`-d/--detach`:** `-d` was appended after the image name so it reached the entrypoint instead of Docker — containers ran in the foreground and exited instantly; `sleep infinity` now runs inside the container via `exec sleep infinity`
- **`-e/--env`:** the env loop prepended a second `-e` per element (`docker run -e -e FOO=bar` → invalid invocation)
- **init script:** zsh `no matches found` noise on `chmod` lines for absent key types, silenced via `setopt NULL_GLOB`; socket files in `~/.ssh` no longer abort the volume copy (fatal under GNU `cp`)

## [1.0.0] — 2025-01-11

### 🎉 Initial Release

First release of **devbox** — a single, all-in-one development container for Node.js, Python, and AI Coding Agents.

#### Added
- **Base image:** Ubuntu 26.04 with UTF-8 locale, UTC timezone, `/workspace` as working directory
- **Shell & terminal:** zsh + Oh My Zsh (git, npm, pip, python, zsh-autosuggestions, zsh-completions, zsh-syntax-highlighting plugins), fzf key bindings (Ctrl-R, Ctrl-T, Alt-C) backed by fd
- **Editor & utilities:** Vim with vim-plug (nerdtree, vim-gitgutter, fzf, fzf.vim, vim-surround, auto-pairs), btop, ripgrep (rg), bat, fzf, fd, jq, sudo, gosu
- **Runtimes:** Node.js LTS + corepack (pnpm, yarn); Python 3 + uv (ultra-fast package manager)
- **AI Coding Agents:** opencode2 (OpenCode AI CLI beta), pi (Pi Coding Agent)
- **Management script:** `devbox-launch.sh` — streamlined container management
- **CI/CD:** GitHub Actions workflow for building and publishing to GHCR (`ghcr.io/luongnv89/devbox`)
- **Security:** Trivy vulnerability scanning in CI pipeline
- **Branding:** Custom logo (PNG + SVG)

#### Fixed
- BuildKit heredoc parse error in Dockerfile
- Broken shell integration
- Host AI configuration not mounting correctly
- Various CI workflow fixes (jq commands, context variables, permissions)

#### Changed
- Replaced starship prompt with Oh My Zsh default
- Streamlined image for Node/Python dev with focused AI tools
- Removed legacy images and project tooling
- Simplified to single-root Dockerfile

#### Documentation
- Comprehensive README with environment details and usage
- CONTRIBUTING.md, SECURITY.md, CODE_OF_CONDUCT.md
- OSS alignment and documentation rewrites

---
