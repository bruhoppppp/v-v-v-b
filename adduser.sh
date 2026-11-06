#!/bin/bash

# Ensure the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or with sudo."
  exit 1
fi

USERNAME="randi"
PASSWORD="randi"

# Check if user already exists
if id "$USERNAME" &>/dev/null; then
    echo "User '$USERNAME' already exists on this system!"
    exit 1
fi

# Create user with home directory, bash shell, and add to sudo group
useradd -m -s /bin/bash -G sudo "$USERNAME"

# Set password
echo "$USERNAME:$PASSWORD" | chpasswd

echo "User '$USERNAME' created successfully with sudo privileges on your VPS!"
