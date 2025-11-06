#!/usr/bin/env bash
set -euo pipefail

OPENLANE_DIR="${OPENLANE_DIR:-/workspaces/OpenLane}"
WORKSHOP_HOME="${WORKSHOP_HOME:-/home/vscode/Desktop/work}"

# Create workshop path and link OpenLane there (target created later)
mkdir -p "$WORKSHOP_HOME"
if [[ ! -e "$WORKSHOP_HOME/OpenLane" ]]; then
  ln -s "$OPENLANE_DIR" "$WORKSHOP_HOME/OpenLane" || true
fi

# Add helpers now; heavy things will come from init script
PROFILE_SNIPPET="# OpenLane helpers
export OPENLANE_DIR=\"$OPENLANE_DIR\"
export PDK_ROOT=\"${PDK_ROOT:-/workspaces/.pdk}\"
export PDK=\"${PDK:-sky130A}\"
export STD_CELL_LIBRARY=\"${STD_CELL_LIBRARY:-sky130_fd_sc_hd}\"
alias ol-mount='cd \"$OPENLANE_DIR\" && make mount'
alias ol-run='cd \"$OPENLANE_DIR\" && ./flow.tcl -design spm -overwrite -tag quick'
"
if ! grep -q 'OpenLane helpers' /home/vscode/.bashrc 2>/dev/null; then
  echo "$PROFILE_SNIPPET" >> /home/vscode/.bashrc
fi

echo "[postcreate] Minimal setup done. Next run: bash .devcontainer/init_openlane.sh"
