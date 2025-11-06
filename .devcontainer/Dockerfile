# .devcontainer/Dockerfile
FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    make \
    python3-venv \
    python3-pip \
    tcl \
    tcllib \
    unzip \
    zstd \
    jq \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Create a place for OpenLane and logs
RUN mkdir -p /opt/openlane /var/log/supervisor
WORKDIR /workspaces
