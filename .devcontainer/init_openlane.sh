#!/usr/bin/env bash
set -euo pipefail

echo "[init_openlane] START"

OPENLANE_DIR="${OPENLANE_DIR:-/workspaces/OpenLane}"
PDK_ROOT="${PDK_ROOT:-/workspaces/.pdk}"
PDK="${PDK:-sky130A}"
STD_CELL_LIBRARY="${STD_CELL_LIBRARY:-sky130_fd_sc_hd}"

# ciel paths
export CIEL_HOME="${CIEL_HOME:-$OPENLANE_DIR/.ciel}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$OPENLANE_DIR/.cache}"

mkdir -p "$OPENLANE_DIR" "$PDK_ROOT" "$CIEL_HOME" "$XDG_CACHE_HOME"

# 1) Clone/Update OpenLane superstable
if [[ -d "$OPENLANE_DIR/.git" ]]; then
  echo "[init_openlane] Updating OpenLane @ superstable"
  ( cd "$OPENLANE_DIR" && git fetch --depth=1 origin superstable && git checkout superstable && git reset --hard origin/superstable )
else
  if [[ -d "$OPENLANE_DIR" && -n "$(ls -A "$OPENLANE_DIR" 2>/dev/null)" ]]; then
    echo "[init_openlane] Found non-git dir; moving aside"
    mv "$OPENLANE_DIR" "${OPENLANE_DIR}.bak_$(date +%s)"
  fi
  echo "[init_openlane] Cloning OpenLane (superstable)"
  git clone --depth=1 --branch superstable https://github.com/The-OpenROAD-Project/OpenLane.git "$OPENLANE_DIR"
fi

# 2) Python venv
echo "[init_openlane] Creating venv"
python3 -m venv "$OPENLANE_DIR/venv"
"$OPENLANE_DIR/venv/bin/pip" install --upgrade pip
"$OPENLANE_DIR/venv/bin/pip" install --no-cache-dir -r "$OPENLANE_DIR/requirements.txt"

# 3) Install matched PDK (idempotent). This is the heavy step; keep it AFTER boot.
echo "[init_openlane] Installing PDK into $PDK_ROOT"
export PDK_ROOT CIEL_HOME XDG_CACHE_HOME
( cd "$OPENLANE_DIR" && make pdk )

# 4) Pull tested OpenLane image
echo "[init_openlane] Pulling OpenLane image"
( cd "$OPENLANE_DIR" && make pull-openlane ) || true

echo "[init_openlane] DONE"
echo "Use:  ol-mount   (then inside the container: ./flow.tcl -design spm -overwrite -tag run1)"
echo "GUI:  bash .devcontainer/start_novnc.sh  → open port 6080 → vnc.html"
