FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1

# --- Create vscode user (Codespaces expects this)
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=${USER_UID}
RUN groupadd --gid ${USER_GID} ${USERNAME} \
  && useradd -m -s /bin/bash --uid ${USER_UID} --gid ${USER_GID} ${USERNAME} \
  && apt-get update && apt-get install -y --no-install-recommends sudo \
  && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
  && chmod 0440 /etc/sudoers.d/${USERNAME}

# --- Base packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget curl unzip zip git make ca-certificates gnupg lsb-release pkg-config \
    python3 python3-pip python3-numpy python3-pandas python3-matplotlib python3-jinja2 python3-xlsxwriter \
    xvfb xfce4 xfce4-session xfce4-panel xfdesktop4 xfwm4 xfce4-terminal thunar dbus-x11 x11vnc novnc websockify supervisor \
    magic ngspice gtkwave verilator iverilog \
    build-essential autoconf automake libtool m4 cmake ninja-build clang \
    tcl tcl-dev tcllib tcl-trf tclx tk tk-dev locales \
    perl libfile-which-perl \
    libcairo2-dev libgl1-mesa-dev libglu1-mesa-dev freeglut3-dev \
    libx11-dev libxext-dev libxrender-dev libxpm-dev libxaw7-dev libfontconfig1-dev \
    libreadline-dev libncurses-dev flex bison gawk tcsh time bc vim \
    libqt5charts5 libyaml-cpp0.7 \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# --- OSS CAD Suite (Yosys, etc.)
RUN set -eux; \
  curl -L https://github.com/YosysHQ/oss-cad-suite-build/releases/download/2025-10-31/oss-cad-suite-linux-x64-20251031.tgz \
    -o /tmp/oss-cad.tgz; \
  mkdir -p /opt && tar -xzf /tmp/oss-cad.tgz -C /opt; \
  ln -s /opt/oss-cad-suite /opt/oss-cad; \
  rm /tmp/oss-cad.tgz
ENV PATH="/opt/oss-cad/bin:${PATH}"

# --- KLayout
RUN set -eux; \
  curl -L -o /tmp/klayout.deb \
    https://www.klayout.org/downloads/Ubuntu-22/klayout_0.29.0-1_amd64.deb; \
  apt-get update && apt-get install -y --no-install-recommends /tmp/klayout.deb; \
  rm -rf /var/lib/apt/lists/* /tmp/klayout.deb

# --- OpenROAD from your custom .deb
ARG OPENROAD_DEB_URL="https://vsd-labs.sgp1.cdn.digitaloceanspaces.com/vsd-labs/openroad_2.0+custom+20251027_amd64.deb"
RUN set -eux; \
  apt-get update && apt-get install -y --no-install-recommends wget ca-certificates; \
  wget -O /tmp/openroad.deb "$OPENROAD_DEB_URL"; \
  apt-get install -y /tmp/openroad.deb || apt-get -f install -y; \
  rm -rf /var/lib/apt/lists/* /tmp/openroad.deb

RUN set -eux; \
  install -d /usr/local/bin; \
  ln -sf /opt/openroad/bin/openroad /usr/local/bin/openroad || true; \
  chmod +x /opt/openroad/bin/openroad || true; \
  true

ENV OPENROAD_EXE="/opt/openroad/bin/openroad"
ENV PATH="/usr/local/bin:${PATH}"
ENV YOSYS_EXE="/opt/oss-cad-suite/bin/yosys"
ENV YOSYS_PLUGIN_PATH="/opt/oss-cad-suite/share/yosys/plugins"
ENV PATH="/opt/oss-cad-suite/bin:/usr/local/bin:${PATH}"

# --- Pull your OpenLane bundle (work.zip) and unpack to Desktop
# Make the URL overridable so future rebuilds can point to a new zip.
ARG WORK_ZIP_URL="https://vsd-labs.sgp1.cdn.digitaloceanspaces.com/vsd-labs/work.zip"
ENV WORK_DEST_DIR="/home/vscode/Desktop"
RUN set -eux; \
  mkdir -p "${WORK_DEST_DIR}"; \
  wget -O /tmp/work.zip "${WORK_ZIP_URL}"; \
  unzip -o /tmp/work.zip -d "${WORK_DEST_DIR}"; \
  rm -f /tmp/work.zip; \
  chown -R ${USERNAME}:${USERNAME} "${WORK_DEST_DIR}/work"

# --- Export PDK_ROOT exactly where you keep the PDKs
ENV PDK_ROOT="/home/vscode/Desktop/work/tools/openlane_working_dir/pdks"

# --- Make PDK_ROOT available in interactive shells for all users
RUN echo 'export PDK_ROOT="/home/vscode/Desktop/work/tools/openlane_working_dir/pdks"' > /etc/profile.d/pdk_root.sh

# --- noVNC desktop environment
COPY supervisord.conf /etc/supervisor/conf.d/vnc.conf
EXPOSE 6080
CMD ["/usr/bin/supervisord", "-n"]
