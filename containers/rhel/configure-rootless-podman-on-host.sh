#!/bin/bash

# Update the system
sudo apt-get update && sudo apt-get upgrade -y

# Install Podman
sudo apt-get install -y podman

# Install uidmap package for UID/GID mapping
sudo apt-get install -y uidmap

# Set up subuid and subgid with a range for your user
# Replace 'yourusername' with your actual username on the system
USER_NAME=$(whoami)

# Ensure existing entries are not duplicated
if ! grep -q "^$USER_NAME:" /etc/subuid; then
    sudo usermod --add-subuids 100000-165536 $USER_NAME
fi

if ! grep -q "^$USER_NAME:" /etc/subgid; then
    sudo usermod --add-subgids 100000-165536 $USER_NAME
fi

# Optional: Configure the storage for rootless containers
# This step is optional and can be adjusted based on your storage preference
# The default is often sufficient for starting out
mkdir -p ~/.config/containers
echo -e "[storage]\n  driver = \"overlay\"\n  [storage.options]\n    mount_program = \"/usr/bin/fuse-overlayfs\"" > ~/.config/containers/storage.conf

# Print out a message on successful setup
echo "Rootless container setup is complete. Please log out and back in for changes to take effect, or reboot your system."
