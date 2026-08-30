#!/usr/bin/env bash
# Optional non-root interactive user for bind-mount sandboxes (issue #16).
# Invoked at image build when DEV_CREATE_NONROOT_USER=1.
set -euo pipefail

if [ "${DEV_CREATE_NONROOT_USER:-0}" != "1" ]; then
    echo "[dev-user] Skipping non-root user (DEV_CREATE_NONROOT_USER != 1)"
    exit 0
fi

DEV_USERNAME="${DEV_USERNAME:-dev}"
DEV_UID="${DEV_UID:-1000}"
DEV_GID="${DEV_GID:-1000}"

echo "[dev-user] Creating ${DEV_USERNAME} (uid=${DEV_UID}, gid=${DEV_GID}) with sudo"

apt-get update
apt-get install -y sudo gosu
rm -rf /var/lib/apt/lists/*

if id -u ubuntu >/dev/null 2>&1 && [ "$(id -u ubuntu)" -eq "${DEV_UID}" ]; then
    echo "[dev-user] Reusing ubuntu account (uid ${DEV_UID}) as ${DEV_USERNAME}"
    usermod -l "${DEV_USERNAME}" ubuntu
    if getent group ubuntu >/dev/null 2>&1; then
        groupmod -n "${DEV_USERNAME}" ubuntu
    fi
    usermod -d "/home/${DEV_USERNAME}" -m "${DEV_USERNAME}" 2>/dev/null || true
    usermod -g "${DEV_USERNAME}" -s /usr/bin/zsh "${DEV_USERNAME}"
elif ! id -u "${DEV_USERNAME}" >/dev/null 2>&1; then
    if getent group "${DEV_GID}" >/dev/null 2>&1; then
        groupadd -o -g "${DEV_GID}" "${DEV_USERNAME}" 2>/dev/null || true
    else
        groupadd -g "${DEV_GID}" "${DEV_USERNAME}"
    fi
    useradd -m -u "${DEV_UID}" -g "${DEV_GID}" -s /usr/bin/zsh "${DEV_USERNAME}"
fi

echo "${DEV_USERNAME} ALL=(ALL) NOPASSWD:ALL" >"/etc/sudoers.d/${DEV_USERNAME}"
chmod 0440 "/etc/sudoers.d/${DEV_USERNAME}"

DEV_HOME="$(getent passwd "${DEV_USERNAME}" | cut -d: -f6)"

echo "[dev-user] Seeding ${DEV_HOME} from /root"
for item in .oh-my-zsh .vim .zshrc .shell-cli-extras.zsh .config; do
    if [ -e "/root/${item}" ]; then
        cp -a "/root/${item}" "${DEV_HOME}/"
    fi
done

if [ -f "${DEV_HOME}/.zshrc" ]; then
    sed -i "s|/root/|${DEV_HOME}/|g" "${DEV_HOME}/.zshrc"
fi

chown -R "${DEV_USERNAME}:${DEV_USERNAME}" "${DEV_HOME}"

mkdir -p /workspace
chown "${DEV_USERNAME}:${DEV_USERNAME}" /workspace

echo "dev" >/etc/docker-dev-run-as
echo "[dev-user] Runtime will drop to ${DEV_USERNAME} via entrypoint when started as root"
