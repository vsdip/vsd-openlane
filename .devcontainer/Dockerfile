# ------------------------------------------------------------
# Minimal working Dockerfile using efabless/openlane:v0.21
# (root user, same behavior as local docker run)
# ------------------------------------------------------------

FROM efabless/openlane:v0.21

# Environment setup
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    DISPLAY=:1

# Default working directory (OpenLane expects /openLANE_flow)
WORKDIR /openLANE_flow

# ------------------------------------------------------------
# Optional VNC supervisor support
# ------------------------------------------------------------
# Place your supervisord.conf (for VNC/XFCE/noVNC) next to this Dockerfile
COPY supervisord.conf /etc/supervisor/conf.d/vnc.conf

# Open default noVNC port
EXPOSE 6080

# Launch Supervisor as default process
CMD ["bash", "-lc", "supervisord -n"]
