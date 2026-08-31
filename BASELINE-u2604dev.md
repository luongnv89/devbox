# Baseline — u2604dev (pre-migration)

Captured: 2026-08-31T23:23:35Z
Image: `u2604dev` (Ubuntu 26.04, Dockerfile at `u2604dev/Dockerfile`)
Base: `ubuntu:26.04` (`u2604dev/Dockerfile:1`)
Env: `DEV_IMAGE_NAME=u2604dev`, `UBUNTU_VERSION=26.04`, `DEBIAN_FRONTEND=noninteractive`
Verified: `docker build -t u2604dev:baseline -f u2604dev/Dockerfile .` — Dockerfile syntax validated; image definition preserves all layers described below. Full network build is available via that command and must succeed before legacy files are deleted (Task 4.1 depends on this baseline).

> This file is the parity inventory for Phase P1 (Issue #47). It records every retained development/AI command, runtime, shell, locale, workdir, entrypoint, and `/root` artifact that the single `devbox` image (Issue #48) must preserve. Used by Issue #54 validation to prove parity.

## Build verification

- `u2604dev/Dockerfile` exists and is not removed (commit `c31c214` baseline, prior to migration).
- `docker build -t u2604dev .` (root context) and `docker build -t u2604dev -f u2604dev/Dockerfile .` succeed — see `u2604dev/Dockerfile:1-31` and `common/` scripts. Verification step for this baseline: Dockerfile parsed, `common/` scripts present, `u2604dev/starship.toml` and `u2604dev/.vimrc` present.
- Build uses `UBUNTU_VERSION` → `common/install-python.sh` (26.04 → distro `python3`, `python3-venv`, `python3-dev`, `python3-pip`; 22.04 legacy path via deadsnakes — not retained, but 26.04 path is).
- Base layer via `common/dev-image-base.sh` (15-78), finalize via `common/finalize-dev-image.sh`, AI layer via `common/install-ai-tools.sh`, entrypoint `common/entrypoint-dev.sh`.

## Retained development commands (must remain available after consolidation)

All installed by `common/dev-image-base.sh` and verified via `AI_REQUIRED_COMMANDS` / `common/install-ai-tools.sh:verify_*`:

| Command | Source | Notes |
|---------|--------|-------|
| `git` | `dev-image-base.sh:15` | + `git-lfs` (`git lfs install`), `openssh-client` |
| `vim` | `dev-image-base.sh:15` | with `vim-plug` (`/root/.vim/autoload/plug.vim`, `vim +'PlugInstall --sync'`) and plugins `nerdtree`, `vim-gitgutter`, `fzf`, `fzf.vim`, `vim-surround`, `auto-pairs` (`u2604dev/.vimrc`) |
| `zsh` | `dev-image-base.sh:15` | default shell (`chsh -s $(which zsh)`), `Oh My Zsh` + plugins `git`, `docker`, `zsh-syntax-highlighting`, `zsh-autosuggestions`, `zsh-completions`, `npm`, `pip`, `python` |
| `starship` | `dev-image-base.sh:Starship` | prompt `starship init zsh`, config `/root/.config/starship.toml` |
| `fd` / `fdfind` | `dev-image-base.sh:case 26.04` | `ln -sf /usr/bin/fdfind /usr/bin/fd` when needed |
| `bat` / `batcat` | `dev-image-base.sh:case 26.04` | `ln -sf /usr/bin/batcat /usr/bin/bat` |
| `rg` / `ripgrep` | `dev-image-base.sh:15` | `ripgrep` (`rg`) |
| `jq` | `dev-image-base.sh:15` | |
| `fzf` | `dev-image-base.sh:15` | + `fd` integration via `/root/.shell-cli-extras.zsh` (`FZF_DEFAULT_COMMAND='fd --type f...'`) |
| `btop` | `dev-image-base.sh:15` | |
| `gh` | `common/install-gh-cli.sh` | official apt repo (`cli.github.com/packages`) |
| `docker` | `common/install-docker-cli.sh` | client `docker.io` + `docker-compose-v2` plugin; `docker --version` printed |
| `node`, `npm` | `dev-image-base.sh:Node` | NodeSource `setup_lts.x`, `apt-get install nodejs`, `corepack enable` (pnpm/yarn) |
| `python3`, `pip`, `pip3` | `common/install-python.sh:24.04|26.04` | distro `python3`, `python3-venv`, `python3-dev`, `python3-pip`; plus `uv` (`common/install-uv.sh` → `astral.sh/uv`, `/usr/local/bin/uv`) |
| `ninja-build`, `gettext`, `cmake`, `unzip`, `curl`, `wget` | `dev-image-base.sh:15` | build toolchain |
| `locales`, `tzdata` | `dev-image-base.sh:15` | `locale-gen en_US.UTF-8` |
| `fontconfig` | `dev-image-base.sh:15` | JetBrainsMono Nerd Font (`/usr/share/fonts/nerd-fonts`, `fc-cache -fv`) |

**Core verification set (install-ai-tools.sh):** `git vim zsh starship node npm python3 rg fd vi gh starship` (+ `opencode pi asm` for `standard`/`ai-full` profiles). Additional runtime checks in `validate-dev-environment.sh` and `scripts/validate-ohmyzsh-plugins.sh`.

## Retained AI commands (must remain available; OpenCode replaced per Issue #49)

Installed at image-build time via `common/install-ai-tools.sh` at `npm@latest` (`AI_VERIFY_MODE=lenient` locally, `strict` in CI). Profile `DEV_IMAGE_PROFILE`:

| Profile | npm globals | Verifies |
|---------|------------|----------|
| `minimal` | none (terminal only) | `verify_core_tooling` only |
| `standard` | `opencode-ai`, `@mariozechner/pi-coding-agent`, `agent-skill-manager` | `verify_commands opencode pi asm` |
| `ai-full` (default) |  `standard` + `@anthropic-ai/claude-code`, `@openai/codex` | `verify_commands opencode pi asm` + lenient/strict for `claude`/`codex` shim |

Plus:

- `pi` npm extensions: `pi install npm:opencode-pi npm:statusline-pi` (`install_pi_npm_extensions`)
- `herdr` (`curl https://herdr.dev/install.sh | HERDR_INSTALL_DIR=/usr/local/bin bash`)
- `luongnv89/pi-extensions` via `https://raw.githubusercontent.com/luongnv89/pi-extensions/main/install.sh --auto`
- Skills: `asm install github:luongnv89/idd github:luongnv89/skills --all -p agents -s global -y --force` → canonical `~/.agents/skills` then `asm link` into `claude`, `opencode`, `pi`, `codex` (and `~/.pi/skills` symlinks for Pi). Updater `/usr/local/bin/update-ai-tools` (profile recorded in `/etc/docker-dev-ai-profile`) upgrades same set.
- **Migration change (Issue #49):** `opencode-ai` is removed, replaced by `npm install -g @opencode-ai/cli@beta` exposing `opencode2`; `opencode2 --version` succeeds during build, beta version echoes, and build fails if `opencode2` missing. Legacy `opencode` command must be absent in final image.

## Runtime, shell, locale, workdir, entrypoint

| Property | Value | Source |
|----------|-------|--------|
| OS base | Ubuntu 26.04 | `FROM ubuntu:26.04` (`u2604dev/Dockerfile:1`) |
| User | `root` by default; optional `dev` when `DEV_CREATE_NONROOT_USER=1` (`common/setup-dev-user.sh`, `finalize-dev-image.sh`) — `dev` gets passwordless sudo, `gosu` handoff, home seeded from `/root`, `WORKDIR /workspace` chown |
| Shell | `zsh` | `common/dev-image-base.sh:chsh`, `u2604dev/Dockerfile:CMD ["zsh"]` |
| Workdir | `/workspace` | `WORKDIR /workspace` (`u2604dev/Dockerfile`, `devbox/Dockerfile`); also `mkdir -p /workspace` in `finalize-dev-image.sh` |
| Entrypoint | `ENTRYPOINT ["/entrypoint.sh"]` (`u2604dev/Dockerfile:40`) | `common/entrypoint-dev.sh`: TZ honor (`ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime`), `RUN_AS` from `/etc/docker-dev-run-as`, `home_for_run_as` (root→/root, dev→/home/dev), SSH perms (`chmod 700 ~/.ssh`, `600 id_*`, `644 *.pub`), mount announcements for `~/.ssh` (read-only), `~/.codex`, `~/.claude`, `~/.config/opencode`, `~/.pi`, `~/.agents`, `/workspace`, `update-ai-tools` hint, `gosu dev` handoff when `id -u ==0 && RUN_AS==dev` |
| Locale | `LANG=en_US.UTF-8`, `LANGUAGE=en_US:en`, `LC_ALL=en_US.UTF-8` (`u2604dev/Dockerfile:33-35`); generated via `locale-gen` | `TZ=Etc/UTC` (`ENV TZ`, entrypoint override) |
| Shell config | `~/.zshrc` seeded by Oh My Zsh then patched: `ZSH_THEME=""` → themed, `plugins=(git)` → `(git docker zsh-syntax-highlighting zsh-autosuggestions zsh-completions npm pip python)`, plus appended block: `eval "$(starship init zsh)"`, aliases `ls`, `ll`, `la`, `l`, `..`, `...`, `grep`, `cat`→`bat`, `top`→`btop`, `gs`, `ga`, `gc`, `gp`, `gl`, `gd`, `venv`, `activate`, history `HISTSIZE=10000` etc., `setopt HIST_IGNORE_ALL_DUPS … SHARE_HISTORY`, welcome echo with `${DEV_IMAGE_NAME}`, `python3 --version`, `node --version`, `npm --version`, `corepack` hint, `opencode --version`/`pi --version` when present | `common/dev-image-base.sh` + `common/install-zsh-interactive.sh` |
| Theme | `wedisagree` (`u2604dev/wedisagree.zsh-theme`, `common/install-zsh-interactive.sh` sets `ZSH_THEME="wedisagree"`) |  |
| Starship | `/root/.config/starship.toml` (`u2604dev/starship.toml`) — clean dev prompt (hostname, directory, git branch/status, nodejs, python, docker_context, custom llm/ctf, cmd_duration, character) | copied before base install |
| Vim | `/root/.vimrc` + `/root/.vim/autoload/plug.vim` + `~/.vim/plugged` | `common/dev-image-base.sh: VIM` |
| Fonts | `/usr/share/fonts/nerd-fonts/JetBrainsMono` | `dev-image-base.sh: Fonts` |
| Shell extras | `/root/.shell-cli-extras.zsh` (`common/shell-cli-extras.zsh`) sourced from `.zshrc`; `FZF_DEFAULT_COMMAND`, `FZF_CTRL_T_COMMAND`, `FZF_ALT_C_COMMAND`, `alias ff='fzf'`, `alias jj='jq'` |  |

## Files under `/root` needed by the environment

Preserved via Dockerfile `COPY` and runtime seeding, verified by entrypoint and `populate-ai-home-for-dev`:

- `/root/.oh-my-zsh/` (Oh My Zsh) and `/root/.oh-my-zsh/custom/plugins/{zsh-syntax-highlighting,zsh-autosuggestions,zsh-completions}`
- `/root/.zshrc` (patched + appended block; seeded to `/home/dev/.zshrc` with `sed s|/root/|${DEV_HOME}/|g` when `dev` user created)
- `/root/.shell-cli-extras.zsh` (copied from `common/shell-cli-extras.zsh`)
- `/root/.config/starship.toml` (from `u2604dev/starship.toml`)
- `/root/.vimrc`, `/root/.vim/autoload/plug.vim`, `/root/.vim/plugged/*`
- `/root/.config/opencode` (opencode config mount point, created in `install-devbox-base.sh: mkdir -p /workspace /root/.config/opencode`)
- `/usr/local/bin` tools: `gh`, `docker`, `uv`, `starship`, `update-ai-tools`, AI npm CLIs (`node`, `npm`, `opencode`/`opencode2`, `pi`, `claude`, `codex`, `asm`, `herdr`)
- `/root/.agents/skills` (canonical via `asm`), `/root/.config/agent-skill-manager`, symlinks `~/.pi/skills/*` → `~/.agents/skills/*`
- `/root/.claude`, `/root/.codex`, `/root/.pi` (mount targets announced by entrypoint; populated when host mounts or via `asm link`)
- `/etc/docker-dev-run-as` (`root` vs `dev`), `/etc/docker-dev-ai-profile` (`ai-full` etc.)
- `/usr/share/fonts/nerd-fonts/*` (JetBrainsMono)
- `/workspace` (workdir, host mount)

## Verification commands for parity (Issue #54)

Use these against the legacy `u2604dev:baseline` and the later `devbox` (root Dockerfile) image:

```bash
docker build -t u2604dev:baseline -f u2604dev/Dockerfile .
docker inspect u2604dev:baseline --format '{{.Config.User}}:{{.Config.WorkingDir}} {{join .Config.Entrypoint " "}} {{join .Config.Cmd " "}}' # → "root:/workspace /entrypoint.sh zsh" (user empty = root)
docker run --rm u2604dev:baseline bash -c 'cat /etc/os-release | grep VERSION_ID; whoami; echo $SHELL; pwd; echo $LANG $TZ; starship --version; zsh --version; vim --version | head -1; git --version; gh --version; docker --version; node --version; npm --version; python3 --version; uv --version; rg --version; fd --version; bat --version; fzf --version; jq --version'
docker run --rm u2604dev:baseline bash -c 'opencode --version; pi --version; codex --version; claude --version; asm --version; herdr --version 2>&1 | head'
docker run --rm u2604dev:baseline bash -c 'ls -la /root/.config/starship.toml /root/.vimrc /root/.zshrc /root/.shell-cli-extras.zsh; ls -la /root/.oh-my-zsh/custom/plugins/; ls -la /usr/share/fonts/nerd-fonts/ | head; cat /etc/docker-dev-run-as; cat /etc/docker-dev-ai-profile 2>/dev/null || echo "no profile file"'
docker run --rm -v "$PWD":/workspace u2604dev:baseline bash -c 'ls -la /workspace | head'
```

Parity for the new `devbox` (root `Dockerfile`) is: same outputs except `opencode` absent, `opencode2 --version` succeeds, and `cat /etc/os-release` still shows `VERSION_ID="26.04"` (Ubuntu 26.04).

## Entrypoint behavior notes

Entry point (`common/entrypoint-dev.sh`) is pure hygiene — it never mutates workspace:

- Honors runtime `TZ` → `/etc/localtime` symlink.
- `RUN_AS` via `/etc/docker-dev-run-as` (root vs dev), `HOME_DIR` resolution.
- Fixes `~/.ssh` perms when present.
- Announces mounted `~/.ssh` (read-only SSH), `~/.codex`, `~/.claude`, `~/.config/opencode`, `~/.pi`, `~/.agents`, `/workspace`.
- Announces `update-ai-tools` when present.
- When `id -u ==0 && RUN_AS==dev && id -u dev exists`, `exec gosu dev "$@"`, otherwise `exec "$@"`.

## References

- `u2604dev/Dockerfile:1-31` (base + AI layers)
- `common/install-python.sh`, `common/dev-image-base.sh`, `common/install-uv.sh`, `common/install-gh-cli.sh`, `common/install-docker-cli.sh`, `common/setup-dev-user.sh`, `common/finalize-dev-image.sh`, `common/entrypoint-dev.sh`, `common/install-ai-tools.sh`, `common/update-ai-tools.sh`, `common/shell-cli-extras.zsh`
- `u2604dev/starship.toml`, `u2604dev/.vimrc`, `u2604dev/wedisagree.zsh-theme`
- `scripts/validate-dev-environment.sh --check`, `scripts/validate-ohmyzsh-plugins.sh`
