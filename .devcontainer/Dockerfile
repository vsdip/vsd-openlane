# Simple base (same as bandgap)
FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04
ENV DEBIAN_FRONTEND=noninteractive

# --- System + GUI/VNC + build deps (mirrors bandgap) ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    git build-essential autoconf automake libtool m4 \
    tcl tcl-dev tk tk-dev libcairo2-dev libgl1-mesa-dev libglu1-mesa-dev freeglut3-dev \
    libx11-dev libxext-dev libxrender-dev libxpm-dev libxaw7-dev libcairo2-dev libfontconfig1-dev \
    libreadline-dev libncurses-dev flex bison gawk tcsh \
    python3 python3-pip python3-venv pkg-config curl ca-certificates \
    xfce4 xfce4-terminal x11vnc xvfb novnc websockify supervisor dbus-x11 gedit vim \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# --- Build and install MAGIC (requested) ---
#WORKDIR /tmp/build
#RUN git clone https://github.com/RTimothyEdwards/magic && \
#    cd magic && \
#    ./configure && \
#    make -j"$(nproc)" && \
#    make install && \
#    cd / && rm -rf /tmp/build

# --- noVNC desktop via supervisord (same pattern as bandgap) ---
COPY supervisord.conf /etc/supervisor/conf.d/vnc.conf
# Ensure X socket dir exists at runtime even if non-root runs Xvfb
RUN mkdir -p /tmp/.X11-unix && chmod 1777 /tmp/.X11-unix

# Codespaces discovers this
EXPOSE 6080

# Run the supervisor (keeps container alive)
CMD ["/usr/bin/supervisord", "-n"]
