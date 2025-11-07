# Simple, fast base for Codespaces
FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

USER root
ENV DEBIAN_FRONTEND=noninteractive

# Core deps: Python venv for setup.sh, VNC stack, desktop, build deps, Magic deps
RUN apt-get update && apt-get install -y \
    python3 python3-pip python3-venv \
    xvfb x11vnc novnc websockify xfce4 dbus-x11 xterm \
    build-essential wget ca-certificates \
    tcl-dev tk-dev libcairo2-dev \
    libx11-dev libxpm-dev libxext-dev libxrender-dev libx11-xcb-dev \
    libreadline-dev libncurses-dev \
 && rm -rf /var/lib/apt/lists/*

# (Optional) Build/install Magic once in the image
#RUN set -eux; \
#    cd /tmp; \
#    wget http://opencircuitdesign.com/magic/archive/magic-8.3.573.tgz; \
#    tar xf magic-8.3.573.tgz; \
#    cd magic-8.3.573; \
 #   ./configure; \
 #   make -j"$(nproc)"; \
 #   make install; \
 #   cd /; rm -rf /tmp/magic-8.3.573 /tmp/magic-8.3.573.tgz

# Pre-create the X socket dir with correct perms; avoids Xvfb euid!=0 warning
RUN mkdir -p /tmp/.X11-unix && chmod 1777 /tmp/.X11-unix

# Copy the VNC starter (adjust path if your script lives under .devcontainer/)
COPY --chmod=0755 start-vnc.sh /usr/local/bin/start-vnc.sh

# Environment for X apps
ENV DISPLAY=:1

# noVNC port (Codespaces will auto-forward and label via devcontainer.json)
EXPOSE 6080

# Switch back to the devcontainer user
USER vscode
ENV PATH="/home/vscode/.local/bin:${PATH}"
