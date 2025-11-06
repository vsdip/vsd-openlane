[supervisord]
nodaemon=true
logfile=/var/log/supervisor/supervisord.log
logfile_maxbytes=5MB
logfile_backups=1
pidfile=/var/run/supervisord.pid
childlogdir=/var/log/supervisor

[program:xvfb]
command=/usr/bin/Xvfb :0 -screen 0 1920x1080x24 -nolisten tcp
autostart=true
autorestart=true
stdout_logfile=/var/log/supervisor/xvfb.out.log
stdout_logfile_maxbytes=1MB
stdout_logfile_backups=1
stderr_logfile=/var/log/supervisor/xvfb.err.log
stderr_logfile_maxbytes=1MB
stderr_logfile_backups=1
environment=DISPLAY=":0"

[program:fluxbox]
command=/usr/bin/fluxbox
autostart=true
autorestart=true
priority=10
stdout_logfile=/var/log/supervisor/fluxbox.out.log
stdout_logfile_maxbytes=1MB
stdout_logfile_backups=1
stderr_logfile=/var/log/supervisor/fluxbox.err.log
stderr_logfile_maxbytes=1MB
stderr_logfile_backups=1
environment=DISPLAY=":0",HOME="/home/vscode"

[program:x11vnc]
command=/usr/bin/x11vnc -display :0 -nopw -forever -shared -rfbport 5900 -rfbwait 120000
autostart=true
autorestart=true
priority=20
stdout_logfile=/var/log/supervisor/x11vnc.out.log
stdout_logfile_maxbytes=1MB
stdout_logfile_backups=1
stderr_logfile=/var/log/supervisor/x11vnc.err.log
stderr_logfile_maxbytes=1MB
stderr_logfile_backups=1

[program:novnc]
command=/usr/share/novnc/utils/novnc_proxy --listen 6080 --vnc localhost:5900
autostart=true
autorestart=true
priority=30
stdout_logfile=/var/log/supervisor/novnc.out.log
stdout_logfile_maxbytes=1MB
stdout_logfile_backups=1
stderr_logfile=/var/log/supervisor/novnc.err.log
stderr_logfile_maxbytes=1MB
stderr_logfile_backups=1
