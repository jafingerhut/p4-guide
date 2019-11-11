#! /bin/bash

# Use the test environment install script provided with Docker to install it.
# We can use a different method to install Docker later if we decide we
# want more control of the options.

# I found these steps described here:
# https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-using-the-convenience-script

echo "Disk space before installing docker"
date
df -BM .

curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

echo "Disk space after installing docker"
date
df -BM .

echo "You must log off and back on for the last 'usermod' command to take"
echo "effect, or reboot your system."
