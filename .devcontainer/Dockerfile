FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

ENV DEBIAN_FRONTEND=noninteractive

# Keep this tiny: only what we need to run OpenLane helper scripts and extract PDK packs
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git make jq \
    python3-venv python3-pip gedit vim less \
    tcl tcllib \
    unzip zstd tar rsync \
 && rm -rf /var/lib/apt/lists/*

# workspace mount point
WORKDIR /workspaces
