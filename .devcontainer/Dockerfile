# Stage 1: pull OpenLane files from the original image
FROM efabless/openlane:v0.21 AS openlane_src

# Stage 2: modern, supported base for Codespaces
FROM ubuntu:22.04
SHELL ["/bin/bash", "-lc"]
ENV DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 LC_ALL=C.UTF-8 DISPLAY=:1

# Minimal tools for Codespaces + supervisor (if you need VNC)
RUN apt-get update && apt-get install -y --no-install-recommends \
      sudo ca-certificates locales supervisor python3 python3-venv \
      git curl bash make tcl \
  && sed -i 's/^# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && locale-gen \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy OpenLane stack from the CentOS image
# (These paths cover OpenLane flow + common tool installs; adjust if needed)
COPY --from=openlane_src /openlane /openlane
COPY --from=openlane_src /usr/local /usr/local
# If the source image has other critical bins/libs, copy them similarly.

# Create vscode user
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=${USER_UID}
RUN groupadd -g ${USER_GID} ${USERNAME} && useradd -m -s /bin/bash -u ${USER_UID} -g ${USER_GID} ${USERNAME} \
 && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} && chmod 0440 /etc/sudoers.d/${USERNAME}

# Codespaces defaults
WORKDIR /workspaces
ENV PDK_ROOT=/workspaces/pdks
RUN chown -R ${USERNAME}:${USERNAME} /workspaces
USER ${USERNAME}

# Optional VNC supervisor
COPY supervisord.conf /etc/supervisor/conf.d/vnc.conf
EXPOSE 6080
CMD ["bash", "-lc", "supervisord -n"]
