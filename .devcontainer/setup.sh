#!/usr/bin/env bash
set -euo pipefail

echo "[setup] START"

# --------- Config (explicit) ----------
OPENLANE_DIR="${OPENLANE_DIR:-/workspaces/OpenLane}"
PDK_ROOT="${PDK_ROOT:-/workspaces/.pdk}"
PDK="${PDK:-sky130A}"
STD_CELL_LIBRARY="${STD_CELL_LIBRARY:-sky130_fd_sc_hd}"

# ciel needs a home/cache; make them explicit to avoid NoneType issues
export CIEL_HOME="${CIEL_HOME:-$OPENLANE_DIR/.ciel}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$OPENLANE_DIR/.cache}"

mkdir -p "$OPENLANE_DIR" "$PDK_ROOT" "$CIEL_HOME" "$XDG_CACHE_HOME"

# --------- Optional: host OpenSTA (OFF by default) ----------
if [[ "${INSTALL_OPENSTA:-0}" == "1" ]]; then
  echo "[setup] Installing OpenSTA (host)"
  sudo apt-get update && sudo apt-get install -y --no-install-recommends opensta || true
  sudo rm -rf /var/lib/apt/lists/*
fi

# --------- OpenLane clone (superstable) ----------
if [[ ! -d "$OPENLANE_DIR/.git" ]]; then
  echo "[setup] Cloning OpenLane (superstable)"
  git clone --depth=1 --branch superstable https://github.com/The-OpenROAD-Project/OpenLane.git "$OPENLANE_DIR"
else
  echo "[setup] Updating OpenLane (superstable)"
  (cd "$OPENLANE_DIR" && git fetch --depth=1 origin superstable && git checkout superstable && git pull --ff-only)
fi

# --------- Python venv ----------
echo "[setup] Creating Python venv"
python3 -m venv "$OPENLANE_DIR/venv"
"$OPENLANE_DIR/venv/bin/pip" install --upgrade pip
"$OPENLANE_DIR/venv/bin/pip" install --no-cache-dir -r "$OPENLANE_DIR/requirements.txt"

# --------- Enable MATCHED PDK via ciel (explicit paths) ----------
echo "[setup] Enabling PDK '$PDK' into $PDK_ROOT"
set +e
PDK_ROOT="$PDK_ROOT" CIEL_HOME="$CIEL_HOME" XDG_CACHE_HOME="$XDG_CACHE_HOME" \
  "$OPENLANE_DIR/venv/bin/ciel" enable --pdk "$PDK" --pdk-root "$PDK_ROOT" --ciel-home "$CIEL_HOME"
rc=$?
set -e

if [[ $rc -ne 0 ]]; then
  echo "[setup] ciel enable failed once; cleaning broken links and retrying"
  find "$PDK_ROOT" -xtype l -exec rm -f {} + || true
  rm -rf "$PDK_ROOT/$PDK" 2>/dev/null || true
  PDK_ROOT="$PDK_ROOT" CIEL_HOME="$CIEL_HOME" XDG_CACHE_HOME="$XDG_CACHE_HOME" \
    "$OPENLANE_DIR/venv/bin/ciel" enable --pdk "$PDK" --pdk-root "$PDK_ROOT" --ciel-home "$CIEL_HOME"
fi

# --------- Pull the tested OpenLane container ----------
echo "[setup] Pulling OpenLane image (cached in devcontainer volume)"
make -C "$OPENLANE_DIR" pull-openlane || true

# --------- Shell helpers ----------
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

echo "[VSD-OPENLANE Codespace setup] DONE"
echo
echo "Run OpenLane:"
echo "  1) Container shell (recommended):  ol-mount    # then: ./flow.tcl -design spm -overwrite -tag test"
echo "  2) Host (non-interactive):         cd \"$OPENLANE_DIR\" && ./flow.tcl -design spm -overwrite -tag test"
