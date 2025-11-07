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

# --- existing content above ---

# Ensure these are present (most likely already in your Dockerfile)
# xfce4, xvfb, x11vnc, novnc, websockify should be installed.

# Set a default display (used by Magic and the desktop)
ENV DISPLAY=:1

# Copy our startup script into the image
COPY start-vnc.sh /usr/local/bin/start-vnc.sh
RUN chmod +x /usr/local/bin/start-vnc.sh

# Expose noVNC port
EXPOSE 6080

# Start the noVNC desktop on container boot (devcontainer.json uses overrideCommand:false)
CMD ["/usr/local/bin/start-vnc.sh"]


