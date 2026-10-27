FROM ubuntu:24.04

ENV container=docker
ENV DEBIAN_FRONTEND=noninteractive

# Set container hostname in environment and /etc/hostname
ENV HOSTNAME=cryzoncloud

# Install core packages, systemd dependencies, and utilities
RUN apt-get update && \
    apt-get install -y \
        systemd \
        systemd-sysv \
        dbus \
        dbus-user-session \
        supervisor \
        openssh-server \
        sudo \
        curl \
        wget \
        iproute2 \
        nano \
        tmate \
        neofetch \
        gnupg \
        lsb-release \
        ca-certificates && \
    mkdir -p /run/sshd /etc/cloudflare /dev/net /var/log/supervisor && \
    echo "root:root" | chpasswd && \
    echo "cryzoncloud" > /etc/hostname && \
    printf '#!/bin/sh\nexit 0\n' > /usr/sbin/policy-rc.d && \
    chmod +x /usr/sbin/policy-rc.d && \
    systemctl enable ssh && \
    printf "\nsystemctl start systemd-logind\n" >> /etc/profile && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add startup script to ensure /dev/net/tun exists at runtime
RUN printf '#!/bin/sh\n[ -c /dev/net/tun ] || (mkdir -p /dev/net && mknod /dev/net/tun c 10 200 && chmod 666 /dev/net/tun)\n' > /usr/local/bin/setup-tun.sh && \
    chmod +x /usr/local/bin/setup-tun.sh

# Install Cloudflared
RUN mkdir -p --mode=0755 /usr/share/keyrings && \
    curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | \
    gpg --dearmor -o /usr/share/keyrings/cloudflare-main.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared noble main" > /etc/apt/sources.list.d/cloudflared.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends cloudflared && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Playit.gg
RUN curl -SsL https://playit-cloud.github.io/ppa/key.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/playit.gpg && \
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/playit.gpg] https://playit-cloud.github.io/ppa/data ./" > /etc/apt/sources.list.d/playit-cloud.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends playit && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Configure Supervisor to manage TUN, SSH, and auto-run sshx as root
RUN printf '[supervisord]\nnodaemon=true\nuser=root\n\n\
[program:tun]\n\
command=/usr/local/bin/setup-tun.sh\n\
priority=1\n\
autorestart=false\n\
startretries=1\n\n\
[program:sshd]\n\
command=/usr/sbin/sshd -D\n\
autorestart=true\n\
priority=10\n\n\
[program:sshx]\n\
user=root\n\
directory=/root\n\
environment=HOME="/root",USER="root"\n\
command=/bin/sh -c "curl -sSf https://sshx.io/get | sh -s run"\n\
autorestart=true\n\
priority=20\n\
stdout_logfile=/dev/stdout\n\
stdout_logfile_maxbytes=0\n\
stderr_logfile=/dev/stderr\n\
stderr_logfile_maxbytes=0\n' > /etc/supervisor/conf.d/supervisord.conf

EXPOSE 22

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
