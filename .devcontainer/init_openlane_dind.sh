#!/usr/bin/env bash
set -euo pipefail

OPENLANE_DIR="${OPENLANE_DIR:-/workspaces/OpenLane}"
PDK_ROOT="${PDK_ROOT:-/workspaces/.pdk}"
PDK="${PDK:-sky130A}"

# clone/update superstable + venv
if [[ -d "$OPENLANE_DIR/.git" ]]; then
  ( cd "$OPENLANE_DIR" && git fetch --depth=1 origin superstable && git checkout superstable && git reset --hard origin/superstable )
else
  git clone --depth=1 --branch superstable https://github.com/The-OpenROAD-Project/OpenLane.git "$OPENLANE_DIR"
fi
python3 -m venv "$OPENLANE_DIR/venv"
"$OPENLANE_DIR/venv/bin/pip" install --upgrade pip
"$OPENLANE_DIR/venv/bin/pip" install --no-cache-dir -r "$OPENLANE_DIR/requirements.txt"

# install matched PDK
export CIEL_HOME="$OPENLANE_DIR/.ciel"
export XDG_CACHE_HOME="$OPENLANE_DIR/.cache"
export PDK_ROOT
( cd "$OPENLANE_DIR" && make pdk )

# pull image via Docker (DiD feature)
( cd "$OPENLANE_DIR" && make pull-openlane )
echo "Done. Use:  ol-mount   (then inside container: ./flow.tcl -design spm -overwrite -tag run1)"
