FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

ENV DEBIAN_FRONTEND=noninteractive

# Base deps + Tcl + archive tools + GUI stack + supervisor + Podman
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git make jq \
    python3-venv python3-pip \
    tcl tcllib \
    unzip zstd tar rsync \
    xvfb x11vnc novnc websockify fluxbox xterm xfonts-base \
    supervisor \
    uidmap slirp4netns fuse-overlayfs podman \
 && rm -rf /var/lib/apt/lists/*

# --- Make a docker shim that calls podman ---
RUN printf '#!/usr/bin/env bash\nexec podman "$@"\n' > /usr/local/bin/docker && \
    chmod +x /usr/local/bin/docker

# Rootless Podman defaults: use slirp4netns & fuse-overlayfs for stability in containers
RUN mkdir -p /etc/containers && \
    printf '[engine]\nevents_logger="file"\n' > /etc/containers/containers.conf

# log dir for supervisor
RUN mkdir -p /var/log/supervisor

WORKDIR /workspaces
