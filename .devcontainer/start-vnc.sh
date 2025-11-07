#!/usr/bin/env bash
set -euo pipefail

export DISPLAY=${DISPLAY:-:1}

# 1) Virtual display
if ! pgrep -x Xvfb >/dev/null; then
  Xvfb "$DISPLAY" -screen 0 1600x900x24 &
fi

# 2) Desktop session (XFCE)
if ! pgrep -x xfce4-session >/dev/null; then
  nohup startxfce4 >/tmp/xfce.log 2>&1 &
fi

# 3) VNC server (no password)
if ! pgrep -x x11vnc >/dev/null; then
  x11vnc -display "$DISPLAY" -forever -shared -rfbport 5901 -nopw &
fi

# 4) noVNC proxy on :6080
NOVNC_PROXY=/usr/share/novnc/utils/novnc_proxy
if [ -x "$NOVNC_PROXY" ]; then
  if ! pgrep -f novnc_proxy >/dev/null; then
    "$NOVNC_PROXY" --vnc localhost:5901 --listen 6080 &
  fi
else
  # fallback
  /usr/share/novnc/utils/launch.sh --vnc localhost:5901 --listen 6080 &
fi

# Keep container in foreground (tail a log)
touch /var/log/novnc-supervisor.log
tail -f /var/log/novnc-supervisor.log

