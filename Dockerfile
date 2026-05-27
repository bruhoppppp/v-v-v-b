# Use a lightweight base image
FROM ubuntu:22.04

# Install curl and shell utilities
RUN apt-get update && \
    apt-get install -y curl ca-certificates bash && \
    rm -rf /var/lib/apt/lists/*

# Install sshx
RUN curl -sSf https://sshx.io/get | sh

# Default command to start sshx shell session
CMD ["sshx", "run", "bash"]
