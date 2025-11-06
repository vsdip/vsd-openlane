#!/usr/bin/env bash
set -euo pipefail

echo "[setup] START"

OPENLANE_DIR="${OPENLANE_DIR:-/workspaces/OpenLane}"
PDK_ROOT="${PDK_ROOT:-/workspaces/.pdk}"
PDK="${PDK:-sky130A}"
STD_CELL_LIBRARY="${STD_CELL_LIBRARY:-sky130_fd_sc_hd}"

# ciel needs a home & cache; keep them inside the workspace
export CIEL_HOME="${CIEL_HOME:-$OPENLANE_DIR/.ciel}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$OPENLANE_DIR/.cache}"

mkdir -p "$OPENLANE_DIR" "$PDK_ROOT" "$CIEL_HOME" "$XDG_CACHE_HOME"

# ---- OpenLane repo (superstable) ----
if [[ -d "$OPENLANE_DIR/.git" ]]; then
  echo "[setup] Updating existing OpenLane repo at $OPENLANE_DIR"
  ( set -e
    cd "$OPENLANE_DIR"
    git fetch --depth=1 origin superstable
    git checkout superstable
    git reset --hard origin/superstable
  )
else
  if [[ -d "$OPENLANE_DIR" && -n "$(ls -A "$OPENLANE_DIR" 2>/dev/null)" ]]; then
    echo "[setup] Found non-git dir at $OPENLANE_DIR; moving aside."
    mv "$OPENLANE_DIR" "${OPENLANE_DIR}.bak_$(date +%s)"
  fi
  echo "[setup] Cloning OpenLane (superstable)"
  git clone --depth=1 --branch superstable https://github.com/The-OpenROAD-Project/OpenLane.git "$OPENLANE_DIR"
fi

# ---- Python venv for helper scripts ----
echo "[setup] Creating Python venv"
python3 -m venv "$OPENLANE_DIR/venv"
"$OPENLANE_DIR/venv/bin/pip" install --upgrade pip
"$OPENLANE_DIR/venv/bin/pip" install --no-cache-dir -r "$OPENLANE_DIR/requirements.txt"

# ---- Install matched PDK (into /workspaces/.pdk) ----
echo "[setup] Installing matched PDK into $PDK_ROOT"
export PDK_ROOT CIEL_HOME XDG_CACHE_HOME
( cd "$OPENLANE_DIR" && make pdk )

# ---- Pull tested OpenLane Docker image ----
echo "[setup] Pulling OpenLane image"
( cd "$OPENLANE_DIR" && make pull-openlane ) || true

# ---- Aliases ----
PROFILE_SNIPPET="# OpenLane helpers
export PDK_ROOT=\"$PDK_ROOT\"
export PDK=\"$PDK\"
export STD_CELL_LIBRARY=\"$STD_CELL_LIBRARY\"
export OPENLANE_DIR=\"$OPENLANE_DIR\"
export CIEL_HOME=\"$CIEL_HOME\"
export XDG_CACHE_HOME=\"$XDG_CACHE_HOME\"
alias ol-mount='cd \"$OPENLANE_DIR\" && make mount'
alias ol-run='cd \"$OPENLANE_DIR\" && ./flow.tcl -design spm -overwrite -tag quick'
"
if ! grep -q 'OpenLane helpers' /home/vscode/.bashrc 2>/dev/null; then
  echo "$PROFILE_SNIPPET" >> /home/vscode/.bashrc
fi

echo "[setup] DONE"
echo
echo "GUI via noVNC: https://localhost:${NOVNC_PORT:-6080}/vnc.html"
echo "Container shell:  ol-mount"
echo "Run (host, non-interactive):  cd \"$OPENLANE_DIR\" && ./flow.tcl -design spm -overwrite -tag run1"
