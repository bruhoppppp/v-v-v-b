FROM ubuntu:24.04

ENV container=docker
ENV DEBIAN_FRONTEND=noninteractive
ENV HOSTNAME=cryzoncloud

# Install systemd, ssh, cloudflared, playit, curl, and tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        systemd \
        systemd-sysv \
        dbus \
        dbus-user-session \
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
    mkdir -p /run/sshd /etc/cloudflare /dev/net && \
    echo "root:root" | chpasswd && \
    echo "cryzoncloud" > /etc/hostname && \
    printf '#!/bin/sh\nexit 0\n' > /usr/sbin/policy-rc.d && \
    chmod +x /usr/sbin/policy-rc.d && \
    systemctl enable ssh && \
    printf "\nsystemctl start systemd-logind\n" >> /etc/profile && \
    # Global systemd timeout bypass
    echo "DefaultTimeoutStartSec=0" >> /etc/systemd/system.conf && \
    echo "DefaultTimeoutStopSec=0" >> /etc/systemd/system.conf && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add startup script to ensure /dev/net/tun exists at runtime via systemd service
RUN printf '#!/bin/sh\n[ -c /dev/net/tun ] || (mkdir -p /dev/net && mknod /dev/net/tun c 10 200 && chmod 666 /dev/net/tun)\n' > /usr/local/bin/setup-tun.sh && \
    chmod +x /usr/local/bin/setup-tun.sh && \
    printf '[Unit]\nDescription=Create TUN Device Node\nBefore=network.target\n\n[Service]\nType=oneshot\nExecStart=/usr/local/bin/setup-tun.sh\n\n[Install]\nWantedBy=multi-user.target\n' > /etc/systemd/system/setup-tun.service && \
    systemctl enable setup-tun.service

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
    echo "deb [signed-by=/usr/signed-by=/etc/apt/trusted.gpg.d/playit.gpg] https://playit-cloud.github.io/ppa/data ./" > /etc/apt/sources.list.d/playit-cloud.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends playit && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a native systemd service for sshx so it runs on boot and prints the link to logs
RUN printf '[Unit]\nDescription=SSHX Web Terminal\nAfter=network.target\n\n[Service]\nType=simple\nUser=root\nWorkingDirectory=/root\nExecStart=/bin/sh -c "curl -sSf https://sshx.io/get | sh -s run"\nRestart=always\n\n[Install]\nWantedBy=multi-user.target\n' > /etc/systemd/system/sshx.service && \
    systemctl enable sshx.service

EXPOSE 22

STOPSIGNAL SIGRTMIN+3

CMD ["/sbin/init"]
