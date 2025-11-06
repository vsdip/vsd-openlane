#!/usr/bin/env bash
set -euo pipefail

echo "[setup_openlane] START"

OPENLANE_DIR="${OPENLANE_DIR:-/workspaces/OpenLane}"
PDK_ROOT="${PDK_ROOT:-/workspaces/.pdk}"
PDK="${PDK:-sky130A}"
STD_CELL_LIBRARY="${STD_CELL_LIBRARY:-sky130_fd_sc_hd}"

# ciel helper paths
export CIEL_HOME="${CIEL_HOME:-$OPENLANE_DIR/.ciel}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$OPENLANE_DIR/.cache}"
mkdir -p "$OPENLANE_DIR" "$PDK_ROOT" "$CIEL_HOME" "$XDG_CACHE_HOME"

# ---- Get OpenLane (superstable) ----
if [[ -d "$OPENLANE_DIR/.git" ]]; then
  echo "[setup_openlane] Updating OpenLane @ superstable"
  ( cd "$OPENLANE_DIR" && git fetch --depth=1 origin superstable && git checkout superstable && git reset --hard origin/superstable )
else
  if [[ -d "$OPENLANE_DIR" && -n "$(ls -A "$OPENLANE_DIR" 2>/dev/null)" ]]; then
    echo "[setup_openlane] Non-git dir present; moving aside."
    mv "$OPENLANE_DIR" "${OPENLANE_DIR}.bak_$(date +%s)"
  fi
  echo "[setup_openlane] Cloning OpenLane (superstable)"
  git clone --depth=1 --branch superstable https://github.com/The-OpenROAD-Project/OpenLane.git "$OPENLANE_DIR"
fi

# ---- Python venv for OpenLane helper scripts ----
echo "[setup_openlane] Creating venv"
python3 -m venv "$OPENLANE_DIR/venv"
"$OPENLANE_DIR/venv/bin/pip" install --upgrade pip
"$OPENLANE_DIR/venv/bin/pip" install --no-cache-dir -r "$OPENLANE_DIR/requirements.txt"

# ---- Install the MATCHED PDK into /workspaces/.pdk ----
echo "[setup_openlane] Installing PDK into $PDK_ROOT (this downloads packs only once)"
export PDK_ROOT CIEL_HOME XDG_CACHE_HOME
( cd "$OPENLANE_DIR" && make pdk )

# Helpful aliases
PROFILE_SNIPPET="# OpenLane helpers
export OPENLANE_DIR=\"$OPENLANE_DIR\"
export PDK_ROOT=\"$PDK_ROOT\"
export PDK=\"$PDK\"
export STD_CELL_LIBRARY=\"$STD_CELL_LIBRARY\"
export CIEL_HOME=\"$CIEL_HOME\"
export XDG_CACHE_HOME=\"$XDG_CACHE_HOME\"
alias ol-run='cd \"$OPENLANE_DIR\" && ./flow.tcl -design spm -overwrite -tag quick'
"
if ! grep -q 'OpenLane helpers' /home/vscode/.bashrc 2>/dev/null; then
  echo "$PROFILE_SNIPPET" >> /home/vscode/.bashrc
fi

echo "[setup_openlane] DONE"
echo "Next: run 'cd \"$OPENLANE_DIR\" && ./flow.tcl -design spm -overwrite -tag run1'"
