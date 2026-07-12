FROM ubuntu:26.04

LABEL maintainer="luongnv89"

ENV DEBIAN_FRONTEND=noninteractive
ENV DEV_IMAGE_NAME=u2604dev
ENV UBUNTU_VERSION=26.04

COPY common/install-python.sh common/dev-image-base.sh \
  common/install-gh-cli.sh common/install-docker-cli.sh \
  common/install-ai-tools.sh common/shell-cli-extras.zsh \
  /opt/common/
COPY u2604dev/starship.toml /root/.config/starship.toml
COPY u2604dev/.vimrc /root/.vimrc

ARG DEV_IMAGE_PROFILE=ai-full
RUN chmod +x /opt/common/*.sh && \
    bash /opt/common/install-python.sh "${UBUNTU_VERSION}" && \
    DEV_IMAGE_NAME="${DEV_IMAGE_NAME}" UBUNTU_VERSION="${UBUNTU_VERSION}" \
    DEV_IMAGE_PROFILE="${DEV_IMAGE_PROFILE}" \
      bash /opt/common/dev-image-base.sh

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV TZ=Etc/UTC

COPY common/entrypoint-dev.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["zsh"]