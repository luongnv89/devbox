# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
