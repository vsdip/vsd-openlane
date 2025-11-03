# Minimal working Dockerfile using efabless/openlane:v0.21
# - Keep root user (no useradd/groupadd)
# - Install supervisor on CentOS 7 via Vault repos
FROM efabless/openlane:v0.21
SHELL ["/bin/bash", "-lc"]

# Environment
ENV LANG=C LC_ALL=C DISPLAY=:1
WORKDIR /openLANE_flow

# ---- Install supervisor (CentOS 7 is EOL: use Vault + EPEL archive) ----
RUN set -euo pipefail; \
  if command -v yum >/dev/null 2>&1; then \
    # Repoint to CentOS 7 vault
    sed -i 's|^mirrorlist=|#mirrorlist=|g' /etc/yum.repos.d/CentOS-Base.repo || true; \
    sed -i 's|^#baseurl=http://mirror.centos.org/centos/\$releasever/os/\$basearch/|baseurl=http://vault.centos.org/7.9.2009/os/\$basearch/|g' /etc/yum.repos.d/CentOS-Base.repo || true; \
    sed -i 's|^#baseurl=http://mirror.centos.org/centos/\$releasever/updates/\$basearch/|baseurl=http://vault.centos.org/7.9.2009/updates/\$basearch/|g' /etc/yum.repos.d/CentOS-Base.repo || true; \
    sed -i 's|^#baseurl=http://mirror.centos.org/centos/\$releasever/extras/\$basearch/|baseurl=http://vault.centos.org/7.9.2009/extras/\$basearch/|g' /etc/yum.repos.d/CentOS-Base.repo || true; \
    # EPEL archive
    cat >/etc/yum.repos.d/epel.repo <<'EOF' || true
[epel]
name=EPEL 7 (Archive)
baseurl=https://archives.fedoraproject.org/pub/archive/epel/7/$basearch/
enabled=1
gpgcheck=0
EOF
    yum makecache fast || true; \
    # Install supervisor + deps (python2-based on C7)
    yum install -y supervisor python-meld3 python-setuptools || yum install -y supervisor || true; \
    yum clean all || true; \
  fi

# ---- VNC supervisor hook (only if you have a matching config) ----
COPY supervisord.conf /etc/supervisor/conf.d/vnc.conf
EXPOSE 6080

# Default process
CMD ["bash", "-lc", "supervisord -n"]
