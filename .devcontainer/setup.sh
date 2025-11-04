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

# ===== 6) Patch or_floorplan.tcl (your combined fix) =====
OR_FP_FILE="${OPENLANE_ROOT}/scripts/openroad/or_floorplan.tcl"
if [ -f "${OR_FP_FILE}" ]; then
  echo "[INFO] Patching ${OR_FP_FILE} for read_tracks + [WARN] escaping…"

  # Backup
  ts="$(date +%Y%m%d-%H%M%S)"
  cp -f "${OR_FP_FILE}" "${OR_FP_FILE}.bak.${ts}"
  echo "[INFO] Backup: ${OR_FP_FILE}.bak.${ts}"

  # 6.1 add safe wrapper at the very top (if missing)
  if ! grep -q "proc vsd_read_tracks_safe" "${OR_FP_FILE}"; then
    tmp="${OR_FP_FILE}.new.${ts}"
    {
      cat <<'TCL'
proc vsd_read_tracks_safe {file} {
  if {[llength [info commands read_tracks]]} {
    read_tracks $file
  } else {
    puts "\[WARN] OpenROAD has no read_tracks; skipping explicit tracks load."
  }
}
TCL
      echo ""
      cat "${OR_FP_FILE}"
    } > "${tmp}"
    mv "${tmp}" "${OR_FP_FILE}"
  else
    echo "[INFO] vsd_read_tracks_safe already present."
  fi

  # 6.2 replace direct calls with wrapper (idempotent)
  if grep -q 'read_tracks \$::env(TRACKS_INFO_FILE)' "${OR_FP_FILE}"; then
    sed -i 's/read_tracks \$::env(TRACKS_INFO_FILE)/vsd_read_tracks_safe $::env(TRACKS_INFO_FILE)/g' "${OR_FP_FILE}"
  fi

  # 6.3 escape any [WARN] → \[WARN] to avoid Tcl command substitution issues
  if grep -q '\[WARN\]' "${OR_FP_FILE}"; then
    sed -i 's/\[WARN\]/\\[WARN]/g' "${OR_FP_FILE}"
  fi

  echo "[INFO] or_floorplan.tcl patch complete."
else
  echo "[WARN] ${OR_FP_FILE} not found; skipping floorplan patch."
fi

# ===== 7) (Optional but recommended) Make PDN step tolerant across OR versions =====
# If you saw pdngen CLI mismatches earlier, force positional form inside the catch block.
OR_PDN_FILE="${OPENLANE_ROOT}/scripts/openroad/or_pdn.tcl"
if [ -f "${OR_PDN_FILE}" ]; then
  echo "[INFO] Normalizing pdngen invocation in ${OR_PDN_FILE} to positional form…"
  ts2="$(date +%Y%m%d-%H%M%S)"
  cp -f "${OR_PDN_FILE}" "${OR_PDN_FILE}.bak.${ts2}"
  # Replace wrapper calls or -cfg forms with simple positional
  sed -i \
    -e 's/{vsd_pdngen_safe \$::env(PDN_CFG)}/{pdngen $::env(PDN_CFG) -verbose}/g' \
    -e 's/vsd_pdngen_safe \$::env(PDN_CFG)/pdngen $::env(PDN_CFG) -verbose/g' \
    -e 's/pdngen[[:space:]]\+-cfg[[:space:]]\+\$::env(PDN_CFG)[[:space:]]\+-verbose/pdngen $::env(PDN_CFG) -verbose/g' \
    -e 's/pdngen[[:space:]]\+-cfg[[:space:]]\+\$::env(PDN_CFG)/pdngen $::env(PDN_CFG)/g' \
    "${OR_PDN_FILE}"

  # If our older wrapper proc exists at the top, comment it out to avoid confusion
  if grep -q "^proc vsd_pdngen_safe" "${OR_PDN_FILE}"; then
    awk '
      BEGIN{inproc=0}
      /^proc vsd_pdngen_safe / { inproc=1; print "# " $0; next }
      inproc==1 {
        if ($0 ~ /^\}/) { print "# " $0; inproc=0; next }
        print "# " $0; next
      }
      { print }
    ' "${OR_PDN_FILE}" > "${OR_PDN_FILE}.new" && mv "${OR_PDN_FILE}.new" "${OR_PDN_FILE}"
  fi
else
  echo "[WARN] ${OR_PDN_FILE} not found; skipping PDN normalization."
fi

echo "[VSD-INFO] setup.sh completed successfully."
