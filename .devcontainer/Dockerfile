# .devcontainer/Dockerfile
FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git make \
    python3-venv python3-pip \
    tcl tcllib vim gedit less \
    unzip zstd tar rsync jq \
    # headless GUI stack for browser access
    xvfb x11vnc novnc websockify fluxbox xterm xfonts-base \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Folders for OpenLane, PDKs and logs
RUN mkdir -p /opt/openlane /var/log/supervisor
WORKDIR /workspaces
