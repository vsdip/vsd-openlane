#!/usr/bin/env bash
set -euo pipefail

echo "[setup] START"

OPENLANE_DIR="${OPENLANE_DIR:-/workspaces/OpenLane}"
PDK_ROOT="${PDK_ROOT:-/workspaces/.pdk}"
PDK="${PDK:-sky130A}"
STD_CELL_LIBRARY="${STD_CELL_LIBRARY:-sky130_fd_sc_hd}"

mkdir -p "$PDK_ROOT"

# 0) Optional: tiny host OpenSTA install (OFF by default to save space)
if [[ "${INSTALL_OPENSTA:-0}" == "1" ]]; then
  echo "[setup] Installing OpenSTA (host) - optional"
  sudo apt-get update && sudo apt-get install -y --no-install-recommends opensta || true
  sudo rm -rf /var/lib/apt/lists/*
fi

# 1) Get OpenLane (superstable)
if [[ ! -d "$OPENLANE_DIR/.git" ]]; then
  echo "[setup] Cloning OpenLane (superstable)"
  git clone --depth=1 --branch superstable https://github.com/The-OpenROAD-Project/OpenLane.git "$OPENLANE_DIR"
else
  echo "[setup] OpenLane repo already present, pulling latest superstable"
  (cd "$OPENLANE_DIR" && git fetch --depth=1 origin superstable && git checkout superstable && git pull --ff-only)
fi

# 2) Python venv for OpenLane helper scripts
echo "[setup] Creating Python venv"
python3 -m venv "$OPENLANE_DIR/venv"
"$OPENLANE_DIR/venv/bin/pip" install --upgrade pip
"$OPENLANE_DIR/venv/bin/pip" install --no-cache-dir -r "$OPENLANE_DIR/requirements.txt"

# 3) Enable MATCHED PDK via ciel (idempotent)
echo "[setup] Enabling PDK '$PDK' into $PDK_ROOT"
PDK_ROOT="$PDK_ROOT" "$OPENLANE_DIR/venv/bin/ciel" enable --pdk "$PDK" || {
  echo "[setup] ciel enable returned non-zero; re-trying after cleaning dead symlinks"
  find "$PDK_ROOT" -xtype l -exec rm -f {} +
  PDK_ROOT="$PDK_ROOT" "$OPENLANE_DIR/venv/bin/ciel" enable --pdk "$PDK"
}

# 4) Pull tested OpenLane Docker image (cached in ol-docker-cache volume)
echo "[setup] Pulling OpenLane image"
make -C "$OPENLANE_DIR" pull-openlane || true

# 5) Helper aliases (optional)
PROFILE_SNIPPET="# OpenLane helpers
export PDK_ROOT=\"$PDK_ROOT\"
export PDK=\"$PDK\"
export STD_CELL_LIBRARY=\"$STD_CELL_LIBRARY\"
export OPENLANE_DIR=\"$OPENLANE_DIR\"
alias ol-mount='cd \"$OPENLANE_DIR\" && make mount'
alias ol-run='cd \"$OPENLANE_DIR\" && ./flow.tcl -design spm -overwrite -tag quick'
"
if ! grep -q 'OpenLane helpers' /home/vscode/.bashrc 2>/dev/null; then
  echo "$PROFILE_SNIPPET" >> /home/vscode/.bashrc
fi

echo "[setup] DONE"
echo
echo "How to run:"
echo "  1) Container (recommended):"
echo "     ol-mount"
echo "     # then inside container: ./flow.tcl -design spm -overwrite -tag test"
echo
echo "  2) Non-interactive (container from host):"
echo "     cd \"$OPENLANE_DIR\" && ./flow.tcl -design spm -overwrite -tag test"
echo
