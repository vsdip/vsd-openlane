#!/usr/bin/env bash
set -euo pipefail

# Install minimal GUI stack only when you want it
sudo apt-get update
sudo apt-get install -y --no-install-recommends xvfb x11vnc novnc websockify fluxbox xterm xfonts-base
sudo rm -rf /var/lib/apt/lists/*

export DISPLAY="${DISPLAY:-:0}"
PORT="${NOVNC_PORT:-6080}"

# Kill leftovers if any
pkill -f "Xvfb :0"     || true
pkill -f "x11vnc"      || true
pkill -f "novnc_proxy" || true
pkill -f "fluxbox"     || true

# Start Xvfb + WM + VNC + noVNC
Xvfb :0 -screen 0 1920x1080x24 -nolisten tcp &
sleep 0.5
fluxbox &
x11vnc -display :0 -nopw -forever -shared -rfbport 5900 -rfbwait 120000 >/tmp/x11vnc.log 2>&1 &
/usr/share/novnc/utils/novnc_proxy --listen "$PORT" --vnc localhost:5900 >/tmp/novnc.log 2>&1 &

echo
echo "noVNC ready → open this URL:"
echo "  https://localhost:${PORT}/vnc.html   (or via the Codespaces Ports panel)"
echo
echo "Then, inside OpenLane’s container or host, run GUI apps targeting DISPLAY=:0"
echo "Examples: openroad -gui   |   klayout"
