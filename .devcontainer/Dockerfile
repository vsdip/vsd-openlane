# Minimal working Dockerfile using efabless/openlane:v0.21
# - root user (no useradd/groupadd)
# - installs supervisor on CentOS 7 via Vault + EPEL archive
FROM efabless/openlane:v0.21
SHELL ["/bin/bash", "-lc"]

ENV LANG=C LC_ALL=C DISPLAY=:1
WORKDIR /openLANE_flow

# CentOS 7 EOL: repoint repos to vault + add EPEL archive, then install supervisor
RUN if command -v yum >/dev/null 2>&1; then \
      sed -i 's|^mirrorlist=|#mirrorlist=|g' /etc/yum.repos.d/CentOS-Base.repo; \
      sed -i 's|^#baseurl=http://mirror.centos.org/centos/\$releasever/os/\$basearch/|baseurl=http://vault.centos.org/7.9.2009/os/\$basearch/|g' /etc/yum.repos.d/CentOS-Base.repo; \
      sed -i 's|^#baseurl=http://mirror.centos.org/centos/\$releasever/updates/\$basearch/|baseurl=http://vault.centos.org/7.9.2009/updates/\$basearch/|g' /etc/yum.repos.d/CentOS-Base.repo; \
      sed -i 's|^#baseurl=http://mirror.centos.org/centos/\$releasever/extras/\$basearch/|baseurl=http://vault.centos.org/7.9.2009/extras/\$basearch/|g' /etc/yum.repos.d/CentOS-Base.repo; \
      printf "[epel]\nname=EPEL 7 (Archive)\nbaseurl=https://archives.fedoraproject.org/pub/archive/epel/7/\\$basearch/\nenabled=1\ngpgcheck=0\n" > /etc/yum.repos.d/epel.repo; \
      yum makecache fast; \
      yum install -y supervisor python-meld3 python-setuptools; \
      yum clean all; \
    fi

# Optional VNC supervisor
COPY supervisord.conf /etc/supervisor/conf.d/vnc.conf
EXPOSE 6080
CMD ["bash", "-lc", "supervisord -n"]
