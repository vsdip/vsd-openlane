# .devcontainer/Dockerfile
FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

ENV DEBIAN_FRONTEND=noninteractive

# Just what we need on the host: python venv, Tcl bits, archive tools, GUI stack, supervisord
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git make jq \
    python3-venv python3-pip \
    tcl tcllib less gedit vim \
    unzip zstd tar rsync \
    xvfb x11vnc novnc websockify fluxbox xterm xfonts-base \
    supervisor \
  && rm -rf /var/lib/apt/lists/*

# Folders for logs
RUN mkdir -p /var/log/supervisor
WORKDIR /workspaces
