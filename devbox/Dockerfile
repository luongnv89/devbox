FROM debian:13-slim

LABEL maintainer="luongnv89"
LABEL description="Lean Debian 13 development image for sandboxed OpenCode tasks"

ENV DEBIAN_FRONTEND=noninteractive
ENV DEV_IMAGE_NAME=devbox
ENV DEBIAN_VERSION=13

COPY common/install-devbox-base.sh common/setup-dev-user.sh \
  common/finalize-dev-image.sh /opt/common/
COPY devbox/.zshrc /root/.zshrc

ARG DEV_IMAGE_PROFILE=standard
ARG DEV_CREATE_NONROOT_USER=0
ARG DEV_UID=1000
ARG DEV_GID=1000

RUN chmod +x /opt/common/*.sh && \
    bash /opt/common/install-devbox-base.sh && \
    DEV_CREATE_NONROOT_USER="${DEV_CREATE_NONROOT_USER}" DEV_UID="${DEV_UID}" DEV_GID="${DEV_GID}" \
      bash /opt/common/finalize-dev-image.sh

# Keep AI tooling in its own layer so version changes do not invalidate the
# Debian package layer above.
COPY common/install-ai-tools.sh common/update-ai-tools.sh /opt/common/
ARG AI_VERIFY_MODE=lenient
ARG AI_TOOLS_CACHEBUST=0
ARG AI_REQUIRED_COMMANDS="git zsh node npm python3 rg fd vi"
RUN chmod +x /opt/common/install-ai-tools.sh /opt/common/update-ai-tools.sh && \
    echo "AI_TOOLS_CACHEBUST=${AI_TOOLS_CACHEBUST}" && \
    DEV_IMAGE_PROFILE="${DEV_IMAGE_PROFILE}" AI_VERIFY_MODE="${AI_VERIFY_MODE}" \
      AI_REQUIRED_COMMANDS="${AI_REQUIRED_COMMANDS}" \
      bash /opt/common/install-ai-tools.sh

ENV LANG=C.UTF-8
ENV LANGUAGE=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV TZ=Etc/UTC

COPY common/entrypoint-dev.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /workspace

ENTRYPOINT ["/entrypoint.sh"]
CMD ["zsh"]
