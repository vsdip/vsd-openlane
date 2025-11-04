#!/usr/bin/env bash
set -euo pipefail

# ===== Basics & paths =====
ME="${USER:-vscode}"
HOME_DIR="/home/${ME}"
DESKTOP_DIR="${HOME_DIR}/Desktop"
WORK_PARENT="${DESKTOP_DIR}"
WORK_DIR="${WORK_PARENT}/work"
OPENLANE_ROOT="${HOME_DIR}/Desktop/work/tools/openlane_working_dir/openlane"

echo "[INFO] setup.sh: user=${ME} home=${HOME_DIR}"

mkdir -p "${WORK_PARENT}"

# ===== 1) Fetch & unpack work.zip (3.5GB) =====
cd "${WORK_PARENT}"
if [ ! -d "${WORK_DIR}" ]; then
  echo "[INFO] Downloading work.zip…"
  wget -O work.zip "https://vsd-labs.sgp1.cdn.digitaloceanspaces.com/vsd-labs/work.zip"
  echo "[INFO] Unzipping work.zip…"
  unzip -q work.zip
  echo "[INFO] Removing work.zip to reclaim space…"
  rm -f work.zip
else
  echo "[INFO] ${WORK_DIR} already exists. Skipping."
fi

# ===== 2) Fetch & unpack OpenSTA and link =====
cd "${HOME_DIR}"
STA_DIR="${HOME_DIR}/OpenSTA"
if [ ! -x "${STA_DIR}/app/sta" ]; then
  echo "[INFO] Downloading OpenSTA.tar.gz…"
  wget -O OpenSTA.tar.gz "https://vsd-labs.sgp1.cdn.digitaloceanspaces.com/vsd-labs/OpenSTA.tar.gz"
  echo "[INFO] Extracting OpenSTA.tar.gz…"
  tar -xzf OpenSTA.tar.gz
  echo "[INFO] Removing OpenSTA.tar.gz…"
  rm -f OpenSTA.tar.gz
else
  echo "[INFO] OpenSTA already present. Skipping download."
fi
if [ -x "${STA_DIR}/app/sta" ]; then
  echo "[INFO] Linking /usr/bin/sta -> ${STA_DIR}/app/sta"
  sudo ln -sf "${STA_DIR}/app/sta" /usr/bin/sta
else
  echo "[WARN] OpenSTA binary not found at ${STA_DIR}/app/sta"
fi

# ===== 3) Persistent environment =====
PDK_ROOT_PATH="${WORK_DIR}/tools/openlane_working_dir/pdks"
# Export for future shells
{
  echo "export PDK_ROOT=${PDK_ROOT_PATH}"
  echo "export LANG=C.UTF-8"
  echo "export LC_ALL=C.UTF-8"
  echo 'export ABC_EXEC="/opt/oss-cad-suite/bin/yosys-abc"'
  echo 'unset TMPDIR || true'
  echo 'export SYNTH_STRATEGY="DELAY 0"'
} >> "${HOME_DIR}/.bashrc"

# Export for current run
export PDK_ROOT="${PDK_ROOT_PATH}"
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
export ABC_EXEC="/opt/oss-cad-suite/bin/yosys-abc"
unset TMPDIR || true
export SYNTH_STRATEGY="DELAY 0"

# ===== 4) Place scripts/libtrim.pl =====
if [ -d "${OPENLANE_ROOT}" ]; then
  echo "[INFO] Installing scripts/libtrim.pl…"
  mkdir -p "${OPENLANE_ROOT}/scripts"
  cat > "${OPENLANE_ROOT}/scripts/libtrim.pl" <<'PERL'
#!/usr/bin/perl
use warnings;
use strict;

open (CELLS,'<', $ARGV[1]) or die("Couldn't open $ARGV[1]");

my @cells = ();
while(<CELLS>){
  next if (/\#/);
  chomp;
  push @cells, $_ if length $_;
}
close(CELLS);

my $state = 0; my $count = 0;

for ($ARGV[0]) {
  for (split) {
    open (LIB, $_) or die("Couldn't open $_");
    while (my $line = <LIB>) {
      if ($state == 0) {
        if ($line =~ /cell\s*\(\"?(.*?)\"?\)/) {
          if (grep { $_ eq $1 } @cells) { $state = 2; print "/* removed $1 */\n"; }
          else { $state = 1; print $line; }
          $count = 1;
        } else { print $line; }
      } elsif ($state == 1) {
        $count++ if ($line =~ /\{/); $count-- if ($line =~ /\}/);
        $state = 0 if ($count == 0); print $line;
      } else {
        $count++ if ($line =~ /\{/); $count-- if ($line =~ /\}/);
        $state = 0 if ($count == 0);
      }
    }
    close(LIB);
  }
}
exit 0;
PERL
  chmod +x "${OPENLANE_ROOT}/scripts/libtrim.pl"
else
  echo "[WARN] OPENLANE_ROOT not found at ${OPENLANE_ROOT}; skipping libtrim.pl"
fi

# ===== 5) Inject 3 synthesis settings into scripts/synth.tcl =====
SYNTH_TCL="${OPENLANE_ROOT}/scripts/synth.tcl"
if [ -f "${SYNTH_TCL}" ]; then
  if ! grep -q "VSD AUTOINJECT BEGIN" "${SYNTH_TCL}"; then
    echo "[INFO] Patching ${SYNTH_TCL} with autosettings…"
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
    echo "[INFO] ${SYNTH_TCL} already contains autosettings."
  fi
else
  echo "[WARN] ${SYNTH_TCL} not found; skipping synth patch."
fi


# ===== 6) Patch scripts/openroad/or_floorplan.tcl for newer OpenROAD =====
if [ -d "${OPENLANE_ROOT}" ]; then
  echo "[INFO] Patching OpenROAD floorplan script for track handling…"
  cd "${OPENLANE_ROOT}"

  if [ -f scripts/openroad/or_floorplan.tcl ]; then
    # Backup
    cp scripts/openroad/or_floorplan.tcl scripts/openroad/or_floorplan.tcl.bak

    # Remove the deprecated -tracks flag (appears twice)
    perl -0777 -pe 's/\s*-tracks\s+\$::env\(TRACKS_INFO_FILE\)\s*\\?\n//g' \
      scripts/openroad/or_floorplan.tcl > scripts/openroad/or_floorplan.tcl.tmp && \
    mv scripts/openroad/or_floorplan.tcl.tmp scripts/openroad/or_floorplan.tcl

    # Inject a tiny helper proc + calls to read_tracks after initialize_floorplan
    perl -0777 -pe '
      BEGIN{$h=qq{
# --- compatibility wrapper for newer OpenROAD (no -tracks on initialize_floorplan)
proc __ol_read_tracks_if_supported {tracks_file} {
  if {[llength [info commands read_tracks]] && [file exists $tracks_file]} {
    puts "[INFO] Reading tracks from $tracks_file";
    read_tracks $tracks_file
  } else {
    puts "[INFO] Skipping read_tracks (command missing or file not found)";
  }
}
};}
      s/(foreach lib .*?set right_margin \[expr.*?\]\n\n)/$1$h/s;
      s/(initialize_floorplan[^\n]*\n(?:\s+-[^\n]*\n)*\s*-site[^\n]*\n\n)/$1    __ol_read_tracks_if_supported \$::env(TRACKS_INFO_FILE)\n\n/sg;
    ' -i scripts/openroad/or_floorplan.tcl

    echo "[INFO] or_floorplan.tcl patched successfully."
  else
    echo "[WARN] scripts/openroad/or_floorplan.tcl not found; skipping floorplan patch."
  fi
else
  echo "[WARN] OPENLANE_ROOT not found at ${OPENLANE_ROOT}; skipping floorplan patch."
fi

# ===== 7) Patch scripts/openroad/or_pdn.tcl for newer OpenROAD (remove positional PDN_CFG) =====
if [ -d "${OPENLANE_ROOT}" ]; then
  echo "[INFO] Patching or_pdn.tcl to remove deprecated pdngen positional argument..."
  cd "${OPENLANE_ROOT}"

  if [ -f scripts/openroad/or_pdn.tcl ]; then
    cp scripts/openroad/or_pdn.tcl scripts/openroad/or_pdn.tcl.bak

    # Remove "$::env(PDN_CFG)" argument while keeping optional flags like -verbose
    perl -0777 -pe 's/pdngen\s+\$::env\(PDN_CFG\)(\s+-verbose)?/pdngen\1/g' \
      -i scripts/openroad/or_pdn.tcl

    echo "[INFO] or_pdn.tcl patched successfully (pdngen positional argument removed)."
  else
    echo "[WARN] or_pdn.tcl not found; skipping PDN patch."
  fi
fi


echo "[VSD-INFO] setup.sh completed successfully."
