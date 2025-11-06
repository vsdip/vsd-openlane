#!/usr/bin/env bash
set -euo pipefail

export DISPLAY="${DISPLAY:-:0}"
PORT="${NOVNC_PORT:-6080}"

# stop leftovers
pkill -f "Xvfb :0"     || true
pkill -f "x11vnc"      || true
pkill -f "novnc_proxy" || true
pkill -f "fluxbox"     || true

# start stack
Xvfb :0 -screen 0 1920x1080x24 -nolisten tcp &
sleep 0.5
fluxbox &
x11vnc -display :0 -nopw -forever -shared -rfbport 5900 -rfbwait 120000 >/tmp/x11vnc.log 2>&1 &
/usr/share/novnc/utils/novnc_proxy --listen "$PORT" --vnc localhost:5900 >/tmp/novnc.log 2>&1 &

echo "noVNC → https://localhost:${PORT}/vnc.html  (or use the Ports tab → 6080 → Open in Browser)"
echo "Then run GUI apps (e.g., 'openroad -gui') from the OpenLane container or host with DISPLAY=:0."
