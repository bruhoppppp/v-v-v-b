FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HOSTNAME=cryzoncloud

# Install core packages, ttyd, openssh, cloudflared, and playit
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
    # Install ttyd directly from GitHub releases
    wget -O /usr/local/bin/ttyd https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 && \
    chmod +x /usr/local/bin/ttyd && \
    mkdir -p /run/sshd /etc/cloudflare /dev/net && \
    echo "root:root" | chpasswd && \
    echo "cryzoncloud-v7" > /etc/hostname && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add a runtime setup script to ensure /dev/net/tun exists and start services
RUN printf '#!/bin/sh\n\
[ -c /dev/net/tun ] || (mkdir -p /dev/net && mknod /dev/net/tun c 10 200 && chmod 666 /dev/net/tun)\n\
# Start SSH service\n\
service ssh start\n\
# Start ttyd web terminal on port 3000 binding to all interfaces\n\
exec ttyd -i 0.0.0.0 -p 3000 -W bash\n' > /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

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

EXPOSE 3000 22

CMD ["/usr/local/bin/entrypoint.sh"]
