#!/usr/bin/env bash
set -euo pipefail

export DISPLAY=${DISPLAY:-:1}
RES=${RES:-1600x900x24}

# Ensure X socket dir exists (works whether we have sudo or not)
if [ ! -d /tmp/.X11-unix ]; then
  if command -v sudo >/dev/null 2>&1; then
    sudo mkdir -p /tmp/.X11-unix && sudo chmod 1777 /tmp/.X11-unix || true
  else
    mkdir -p /tmp/.X11-unix && chmod 1777 /tmp/.X11-unix || true
  fi
fi

# Start Xvfb
pgrep Xvfb >/dev/null || Xvfb "$DISPLAY" -screen 0 "$RES" &

# Start a simple desktop (XFCE), optional but nice for Magic
pgrep -f xfce4-session >/dev/null || (nohup startxfce4 >/tmp/xfce.log 2>&1 &)

# VNC server on :5901
pgrep x11vnc >/dev/null || x11vnc -display "$DISPLAY" -forever -shared -rfbport 5901 -nopw &

# noVNC on :6080 (serve UI from /usr/share/novnc)
pgrep -f 'websockify .*6080' >/dev/null || \
  websockify --web=/usr/share/novnc 0.0.0.0:6080 localhost:5901 &

echo "noVNC → http://localhost:6080/vnc.html?autoconnect=1&resize=remote"
# Keep script alive if run as CMD
wait -n || true
