# Simple, fast base for Codespaces
FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

# Become root to install packages
USER root
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    xvfb x11vnc novnc websockify \
    xfce4 dbus-x11 xterm \
    magic \
 && rm -rf /var/lib/apt/lists/*

# Copy the starter and make it executable (BuildKit handles perms)
COPY --chmod=0755 start-vnc.sh /usr/local/bin/start-vnc.sh

# (Optional) If you want the container to run the VNC stack by default:
# CMD ["/usr/local/bin/start-vnc.sh"]

# Switch back to the devcontainer user
USER vscode

# Helpful PATH for venvs you create in setup.sh
ENV PATH="/home/vscode/.local/bin:${PATH}"

# --- existing content above ---

# Ensure these are present (most likely already in your Dockerfile)
# xfce4, xvfb, x11vnc, novnc, websockify should be installed.

# Set a default display (used by Magic and the desktop)
ENV DISPLAY=:1

# Expose noVNC port
EXPOSE 6080

# Start the noVNC desktop on container boot (devcontainer.json uses overrideCommand:false)
CMD ["/usr/local/bin/start-vnc.sh"]


