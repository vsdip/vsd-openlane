#!/usr/bin/env bash
set -euo pipefail

# Run as the 'vscode' user where possible; use sudo only when needed.
ME="${USER:-vscode}"
HOME_DIR="/home/${ME}"
DESKTOP_DIR="${HOME_DIR}/Desktop"
WORK_PARENT="${DESKTOP_DIR}"
WORK_DIR="${WORK_PARENT}/work"
OPENLANE_ROOT="${HOME_DIR}/Desktop/work/tools/openlane_working_dir/openlane"

echo "[INFO] Starting setup…"
echo "[INFO] User: ${ME} | HOME: ${HOME_DIR}"

mkdir -p "${WORK_PARENT}"
cd "${WORK_PARENT}"

############################################
# 1) Fetch and unpack work.zip (3.5GB)
############################################
if [ ! -d "${WORK_DIR}" ]; then
  echo "[INFO] Downloading work.zip to ${WORK_PARENT}…"
  wget -O work.zip "https://vsd-labs.sgp1.cdn.digitaloceanspaces.com/vsd-labs/work.zip"
  echo "[INFO] Unzipping work.zip…"
  unzip -q work.zip
  echo "[INFO] Deleting work.zip to reclaim space…"
  rm -f work.zip
else
  echo "[INFO] ${WORK_DIR} already exists. Skipping work.zip download."
fi

############################################
# 2) Fetch and unpack OpenSTA and symlink
############################################
cd "${HOME_DIR}"
STA_DIR="${HOME_DIR}/OpenSTA"
if [ ! -x "${STA_DIR}/app/sta" ]; then
  echo "[INFO] Downloading OpenSTA.tar.gz…"
  wget -O OpenSTA.tar.gz "https://vsd-labs.sgp1.cdn.digitaloceanspaces.com/vsd-labs/OpenSTA.tar.gz"
  echo "[INFO] Extracting OpenSTA.tar.gz…"
  tar -xzf OpenSTA.tar.gz
  echo "[INFO] Deleting OpenSTA.tar.gz to reclaim space…"
  rm -f OpenSTA.tar.gz
else
  echo "[INFO] OpenSTA already present. Skipping download."
fi

if [ -x "${STA_DIR}/app/sta" ]; then
  echo "[INFO] Linking sta -> /usr/bin/sta (requires sudo)…"
  sudo ln -sf "${STA_DIR}/app/sta" /usr/bin/sta
else
  echo "[WARN] OpenSTA binary not found at ${STA_DIR}/app/sta"
fi

############################################
# 3) Environment variables (persistent)
############################################
PDK_ROOT_PATH="${WORK_DIR}/tools/openlane_working_dir/pdks"

# Ensure these are visible in every new shell and therefore inside OpenLane Tcl (::env)
{
  echo "export PDK_ROOT=${PDK_ROOT_PATH}"
  echo "export LANG=C.UTF-8"
  echo "export LC_ALL=C.UTF-8"
  # These three lines should appear inside OpenLane (::env) without manual entry:
  echo 'export ABC_EXEC="/opt/oss-cad-suite/bin/yosys-abc"'
  echo 'unset TMPDIR'
  echo 'export SYNTH_STRATEGY="DELAY 0"'
} >> "${HOME_DIR}/.bashrc"

# Also export into this one-time script run so current session has them too
export PDK_ROOT="${PDK_ROOT_PATH}"
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
export ABC_EXEC="/opt/oss-cad-suite/bin/yosys-abc"
unset TMPDIR || true
export SYNTH_STRATEGY="DELAY 0"

############################################
# 4) libtrim.pl drop-in
############################################
echo "[INFO] Installing scripts/libtrim.pl into OpenLane…"
mkdir -p "${OPENLANE_ROOT}/scripts"
cat > "${OPENLANE_ROOT}/scripts/libtrim.pl" <<'PERL'
#!/usr/bin/perl
use warnings;
use strict;

# This Script removes specified input cells ARGV[1] from the lib file input ARGV[0]

open (CELLS,'<', $ARGV[1]) or die("Couldn't open $ARGV[1]");

my @cells = ();
while(<CELLS>){ # cells to remove
  next if (/\#/);
  chomp;
  push @cells, $_ if length $_;
}
close(CELLS);

my $state = 0;   # 0: outside cell, 1: printing a kept cell, 2: skipping a removed cell
my $count = 0;

for ($ARGV[0]) {
  for (split) {
    open (LIB, $_) or die("Couldn't open $_");
    while (my $line = <LIB>) {
      if ($state == 0) {
        if ($line =~ /cell\s*\(\"?(.*?)\"?\)/) {
          if (grep { $_ eq $1 } @cells) {
            $state = 2;
            print "/* removed $1 */\n";
          } else {
            $state = 1;
            print $line;
          }
          $count = 1;
        } else {
          print $line;
        }
      }
      elsif ($state == 1) {
        $count++ if ($line =~ /\{/);
        $count-- if ($line =~ /\}/);
        $state = 0 if ($count == 0);
        print $line;
      }
      else { # $state == 2
        $count++ if ($line =~ /\{/);
        $count-- if ($line =~ /\}/);
        $state = 0 if ($count == 0);
      }
    }
    close(LIB);
  }
}
exit 0;
PERL
chmod +x "${OPENLANE_ROOT}/scripts/libtrim.pl"

##################################################################
### Inject VSD autosettings into synth.tcl (runs before synthesis)
##################################################################

SYNTH_TCL="${OPENLANE_ROOT}/scripts/synth.tcl"
if [ -f "${SYNTH_TCL}" ]; then
  if ! grep -q "VSD AUTOINJECT BEGIN" "${SYNTH_TCL}"; then
    echo "[INFO] Inserting VSD autosettings into scripts/synth.tcl…"
    awk '
      BEGIN { injected=0 }
      {
        print
        if (!injected && $0 ~ /^yosys -import/) {
          print ""
          print "# --- VSD AUTOINJECT BEGIN ---"
          print "set ::env(ABC_EXEC) \"/opt/oss-cad-suite/bin/yosys-abc\""
          print "catch { unset ::env(TMPDIR) }"
          print "set ::env(SYNTH_STRATEGY) \"DELAY 0\""
          print "# --- VSD AUTOINJECT END ---"
          injected=1
        }
      }
    ' "${SYNTH_TCL}" > "${SYNTH_TCL}.new" && mv "${SYNTH_TCL}.new" "${SYNTH_TCL}"
  else
    echo "[INFO] scripts/synth.tcl already contains VSD autosettings."
  fi
else
  echo "[WARN] ${SYNTH_TCL} not found; cannot inject autosettings."
fi


############################################
# 5) Floorplan fix (or_floorplan.tcl)
############################################
OR_FP_FILE="${OPENLANE_ROOT}/scripts/openroad/or_floorplan.tcl"
if [ -f "${OR_FP_FILE}" ]; then
  echo "[INFO] Patching ${OR_FP_FILE}…"
  # Remove obsolete -tracks usage
  sed -i '/-tracks \$::env(TRACKS_INFO_FILE)/d' "${OR_FP_FILE}"

  # Insert read_tracks after -site $::env(PLACE_SITE)
  awk '
    { print }
    /initialize_floorplan/ { seen_ifp=1 }
    seen_ifp && /-site[[:space:]]+\$::env\(PLACE_SITE\)/ {
      print ""
      print "if {[file exists $::env(TRACKS_INFO_FILE)]} {"
      print "  read_tracks $::env(TRACKS_INFO_FILE)"
      print "} else {"
      print "  puts \"[WARN] TRACKS_INFO_FILE not found: $::env(TRACKS_INFO_FILE)\""
      print "}"
      seen_ifp=0
    }
  ' "${OR_FP_FILE}" > "${OR_FP_FILE}.new" && mv "${OR_FP_FILE}.new" "${OR_FP_FILE}"
else
  echo "[WARN] ${OR_FP_FILE} not found; floorplan patch skipped."
fi

############################################
# 6) Friendly done
############################################
echo "[INFO] Setup completed."
