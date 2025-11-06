#!/usr/bin/env bash
set -euo pipefail

OPENLANE_DIR="${OPENLANE_DIR:-/workspaces/OpenLane}"
WORKSHOP_HOME="${WORKSHOP_HOME:-/home/vscode/Desktop/work}"

mkdir -p "$WORKSHOP_HOME" "$OPENLANE_DIR" /home/vscode/.cache/supervisor
if [[ ! -e "$WORKSHOP_HOME/OpenLane" ]]; then
  ln -s "$OPENLANE_DIR" "$WORKSHOP_HOME/OpenLane" || true
fi

# helpful aliases only; no heavy work here
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

echo "[postcreate] Ready. Next step:"
echo "  bash .devcontainer/init_openlane_dind.sh"
