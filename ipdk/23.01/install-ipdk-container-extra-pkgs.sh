#! /bin/bash

# Install several useful software packages inside of IPDK container

# chmod is necessary in cases where the /tmp directory inside the
# container is not world-writable.  If it is not, most or all apt-get
# commands will fail.
chmod 777 /tmp

apt-get update
apt-get install --yes git tcpdump tcpreplay
pip3 install git+https://github.com/p4lang/p4runtime-shell.git
pip3 install scapy

# Try installing PTF inside IPDK container to see if it works there.

cd $HOME
git clone https://github.com/p4lang/ptf
cd ptf
# TODO: Should we also install packages in requirements-dev.txt ?
pip3 install -r requirements.txt
python3 setup.py install
