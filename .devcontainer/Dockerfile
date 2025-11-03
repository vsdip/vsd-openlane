
# ------------------------------------------------------------
# Drop-in Dockerfile for GitHub Codespaces using OpenLane v0.21
# ------------------------------------------------------------
# OS + tools come from efabless/openlane:v0.21 (Ubuntu-based)
FROM efabless/openlane:v0.21

# Noninteractive apt and UTF-8 everywhere
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV DISPLAY=:1

# -------- Create the 'vscode' user Codespaces expects --------
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=${USER_UID}
RUN groupadd --gid ${USER_GID} ${USERNAME} \
  && useradd -m -s /bin/bash --uid ${USER_UID} --gid ${USER_GID} ${USERNAME} \
  && apt-get update && apt-get install -y --no-install-recommends sudo locales ca-certificates \
  && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
  && chmod 0440 /etc/sudoers.d/${USERNAME} \
  && sed -i 's/^# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen \
  && locale-gen \
  && apt-get clean && rm -rf /var/lib/apt/lists/*


# -------- Workspace defaults --------------------------------
# Codespaces usually mounts your repo at /workspaces/<repo>.
# We'll set WORKDIR and a default PDK_ROOT there.
WORKDIR /workspace
ENV PDK_ROOT=/workspace/pdks

# Make sure the vscode user owns the workspace by default
RUN chown -R ${USERNAME}:${USERNAME} /workspace || true

# Use the non-root user from here on
USER ${USERNAME}

# -------- NOTES ----------------------------------------------
# - Do NOT override ENTRYPOINT/CMD; the base image is configured
#   for OpenLane usage already.
# - If your PDKs live elsewhere, either:
#     * change ENV PDK_ROOT above, or
#     * export PDK_ROOT at runtime.
# - Typical interactive session:
#     ./flow.tcl -interactive
#       % package require openlane 0.9
#       % prep -design spm -overwrite
#       % run_synthesis
#       % run_floorplan
# -------------------------------------------------------------


# -----------------------------
# noVNC desktop environment
# -----------------------------
COPY supervisord.conf /etc/supervisor/conf.d/vnc.conf
EXPOSE 6080
CMD ["/usr/bin/supervisord", "-n"]

