FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

ENV DEBIAN_FRONTEND=noninteractive

# Keep small; GUI & Docker daemons are started later, not in build
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git make jq \
    python3-venv python3-pip \
    tcl tcllib \
    unzip zstd tar rsync \
    xvfb x11vnc novnc websockify fluxbox xterm xfonts-base \
    supervisor \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /workspaces
