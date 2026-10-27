FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HOSTNAME=cryzoncloud

# Install system utilities, SSH server, and tools (excluding systemd)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
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
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

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

# Install SSHX binary globally
RUN curl -sSf https://sshx.io/get | sh

# Create a clean runtime entrypoint script
COPY <<'EOF' /usr/local/bin/entrypoint.sh
#!/bin/bash

# Ensure root password is set correctly at runtime
echo "root:root" | chpasswd

# Try to create TUN device if permissions allow
[ -c /dev/net/tun ] || (mkdir -p /dev/net && mknod /dev/net/tun c 10 200 2>/dev/null || true)

# Start SSH server in the background
mkdir -p /run/sshd
/usr/sbin/sshd

# Run sshx in the foreground to keep the container alive 
# and stream your interactive web terminal URL directly into selfhost.dev logs
exec sshx run
EOF

RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 22

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
