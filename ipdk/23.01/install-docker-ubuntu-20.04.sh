#! /bin/bash

# These steps came from this page of instructions for installing
# Docker on Ubuntu 20.04:

# https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository

set -x

sudo apt-get update
sudo apt-get install --yes ca-certificates curl gnupg lsb-release
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install --yes docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

# The IPDK install steps require that you follow these "Linux
# post-install steps" that enable a non-root user to run docker commands
# without prefixing them with 'sudo', found here:
# https://docs.docker.com/engine/install/linux-postinstall/

```bash
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker

echo ""
echo ""
echo "This terminal window is now enabled to run docker commands without"
echo "prefixing them with 'sudo'."
echo ""
echo "If you want all terminal windows to be able to run docker commands"
echo "without using 'sudo', reboot the system."
echo ""
echo "To test your docker installation, try the following command:"
echo ""
echo "    docker run hello-world"
