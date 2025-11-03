# ------------------------------------------------------------
# Drop-in Dockerfile for GitHub Codespaces using OpenLane v0.21
# ------------------------------------------------------------
FROM efabless/openlane:v0.21

# Use bash for RUNs where available
SHELL ["/bin/bash", "-lc"]

# Noninteractive + UTF-8
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV DISPLAY=:1

# -------- Create the 'vscode' user Codespaces expects --------
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

# Install minimal deps (sudo, certs, supervisor, locales where supported)
# Works on Debian/Ubuntu, RHEL/Fedora, and Alpine bases
RUN set -euo pipefail; \
    if command -v apt-get >/dev/null 2>&1; then \
      apt-get update && apt-get install -y --no-install-recommends \
        sudo ca-certificates locales supervisor \
      && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen || true \
      && (command -v locale-gen >/dev/null 2>&1 && locale-gen || true) \
      && apt-get clean && rm -rf /var/lib/apt/lists/*; \
    elif command -v dnf >/dev/null 2>&1; then \
      dnf install -y sudo ca-certificates glibc-langpack-en supervisor && dnf clean all; \
    elif command -v yum >/dev/null 2>&1; then \
      yum install -y sudo ca-certificates glibc-langpack-en supervisor || yum install -y sudo ca-certificates; \
      yum clean all; \
    elif command -v apk >/dev/null 2>&1; then \
      apk add --no-cache sudo ca-certificates bash shadow supervisor; \
    else \
      echo "No supported package manager found in base image." >&2; exit 1; \
    fi

# Create vscode user (supports Alpine and non-Alpine)
RUN set -e; \
    if command -v useradd >/dev/null 2>&1; then \
      groupadd -g ${USER_GID} ${USERNAME} || true; \
      useradd -m -s /bin/bash -u ${USER_UID} -g ${USER_GID} ${USERNAME} || true; \
    else \
      addgroup -g ${USER_GID} ${USERNAME} || true; \
      adduser -D -h /home/${USERNAME} -s /bin/bash -G ${USERNAME} -u ${USER_UID} ${USERNAME} || true; \
    fi && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} && \
    chmod 0440 /etc/sudoers.d/${USERNAME}

# -------- Workspace defaults --------------------------------
# Codespaces usually mounts your repo at /workspaces/<repo>
WORKDIR /workspaces
ENV PDK_ROOT=/workspaces/pdks

# Make sure the vscode user owns the workspace by default
RUN chown -R ${USERNAME}:${USERNAME} /workspaces || true

# Use the non-root user from here on
USER ${USERNAME}

# -----------------------------
# noVNC desktop environment
# (Assumes the base image already contains the GUI/VNC bits you need.
# If not, you'll need to install xfce/xvfb/x11vnc/websockify via the
# same package-manager pattern above.)
# -----------------------------
COPY supervisord.conf /etc/supervisor/conf.d/vnc.conf
EXPOSE 6080

# Don't override OpenLane entrypoint; just run supervisor for VNC
CMD ["supervisord", "-n"]
