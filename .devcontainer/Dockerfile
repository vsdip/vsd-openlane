# Simple, fast base for Codespaces
FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-lc"]

# Core deps: git, build tools, python venv, tcl for flow.tcl, plus quality-of-life tools
RUN apt-get update && apt-get install -y \
    git make curl ca-certificates \
    python3 python3-venv python3-pip \
    tcl xfce4 xfce4-terminal x11vnc xvfb novnc websockify supervisor dbus-x11 \
    && rm -rf /var/lib/apt/lists/*

# Create Desktop folder (matches your path expectations)
RUN mkdir -p /home/vscode/Desktop && chown -R vscode:vscode /home/vscode/Desktop

# Default environment (also re-exported in setup.sh after CIEL finishes)
ENV PDK_ROOT=/home/vscode/.ciel
ENV PDK=sky130A
ENV STD_CELL_LIBRARY=sky130_fd_sc_hd

# Keep using the vscode user
USER vscode

# Helpful PATH for venvs you create in setup.sh
ENV PATH="/home/vscode/.local/bin:${PATH}"

# -----------------------------
# noVNC desktop environment
# -----------------------------
COPY supervisord.conf /etc/supervisor/conf.d/vnc.conf

EXPOSE 6080
CMD ["/usr/bin/supervisord", "-n"]
