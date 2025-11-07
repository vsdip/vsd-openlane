#!/usr/bin/env bash
set -euo pipefail

export DISPLAY="${DISPLAY:-:1}"

# Make sure the X socket dir exists (Xvfb won’t create it as non-root)
mkdir -p /tmp/.X11-unix && chmod 1777 /tmp/.X11-unix || true

# Xvfb virtual display
pgrep Xvfb >/dev/null || Xvfb :1 -screen 0 1600x900x24 &

# Lightweight desktop session (so noVNC shows a desktop)
pgrep -f xfce4-session >/dev/null || (nohup startxfce4 >/tmp/xfce.log 2>&1 &)

# VNC server on :5901, listen on all interfaces so websockify can reach it
pgrep x11vnc >/dev/null || x11vnc -display :1 -forever -shared -rfbport 5901 -nopw -listen 0.0.0.0 &

# noVNC via websockify on :6080 serving the noVNC static files
pgrep -f "websockify .*6080" >/dev/null || websockify --web=/usr/share/novnc 0.0.0.0:6080 localhost:5901 &

# Do not block the shell; postStartCommand runs this in background.
exit 0
