#!/usr/bin/env bash
set -euo pipefail

# --- Config you can tweak ---
OPENLANE_DIR="$HOME/Desktop/OpenLane"
PDK_ROOT_DEFAULT="$HOME/.ciel"
PDK_NAME="sky130A"
STD_LIB="sky130_fd_sc_hd"
# ----------------------------

echo "[setup] Ensuring docker CLI is present (feature provides daemon + group)"
if ! command -v docker >/dev/null 2>&1; then
  sudo apt-get update && sudo apt-get install -y docker.io
fi

# The Dev Container feature already handles docker group; just verify:
if ! groups | grep -q docker; then
  echo "[setup] Adding $(whoami) to docker group"
  sudo usermod -aG docker "$(whoami)" || true
fi

echo "[setup] Cloning OpenLane (if missing) into $OPENLANE_DIR"
if [ ! -d "$OPENLANE_DIR" ]; then
  mkdir -p "$(dirname "$OPENLANE_DIR")"
  git clone https://github.com/The-OpenROAD-Project/OpenLane.git "$OPENLANE_DIR"
else
  echo "[setup] OpenLane already present, pulling latest..."
  git -C "$OPENLANE_DIR" pull --rebase || true
fi

cd "$OPENLANE_DIR"

echo "[setup] Creating Python venv and installing requirements"
python3 -m venv venv
./venv/bin/pip install --upgrade pip
./venv/bin/pip install -r requirements.txt

echo "[setup] Installing a *matched* PDK via CIEL (this may take a while)"
# make pdk invokes ./venv/bin/ciel to fetch the correct commits/tooling
make pdk

echo "[setup] Exporting canonical OpenLane env to your shell defaults"
# Persist to .bashrc so interactive terminals inherit the right PDK automatically
if ! grep -q "### OPENLANE-ENV-BEGIN" "$HOME/.bashrc" 2>/dev/null; then
cat >> "$HOME/.bashrc" <<EOF

### OPENLANE-ENV-BEGIN
export PDK_ROOT="$PDK_ROOT_DEFAULT"
export PDK="$PDK_NAME"
export STD_CELL_LIBRARY="$STD_LIB"
# Convenience alias to jump into OpenLane
alias ol='cd "$HOME/Desktop/OpenLane"'
# Fast launcher for interactive flow
alias openlane='cd "$HOME/Desktop/OpenLane" && ./flow.tcl -interactive'
### OPENLANE-ENV-END
EOF
fi

# Export for current non-login shell too
export PDK_ROOT="$PDK_ROOT_DEFAULT"
export PDK="$PDK_NAME"
export STD_CELL_LIBRARY="$STD_LIB"

echo "[setup] Verifying docker is reachable inside the devcontainer"
docker --version || { echo "[setup][warn] docker CLI not found"; true; }
docker info >/dev/null 2>&1 || echo "[setup][note] Docker daemon will be ready after container restart (Devcontainer feature handles it)."

echo "[VSD OPENLANE CODESPACE SETUP] Done. To start OpenLane:"
echo "  1) Open a new terminal (to load .bashrc), then run:"
echo "       openlane"
echo "     or:"
echo "       cd \"$HOME/Desktop/OpenLane\" && ./flow.tcl -interactive"

# --- Sync/link user designs into OpenLane ---
WS="${REMOTE_CONTAINERS_WORKSPACE_FOLDER:-$PWD}"
DESIGN_SRC="$WS/.openlane-designs/picorv32a"
DESIGN_DST="$OPENLANE_DIR/designs/picorv32a"

if [ -d "$DESIGN_SRC" ]; then
  echo "[setup] Linking picorv32a into OpenLane designs"
  mkdir -p "$(dirname "$DESIGN_DST")"
  # Use a symlink so your repo remains the source of truth
  rm -rf "$DESIGN_DST"
  ln -s "$DESIGN_SRC" "$DESIGN_DST"
  ls -l "$DESIGN_DST"
else
  echo "[setup] Skip: $DESIGN_SRC not found (create it in your repo to enable)"
fi

