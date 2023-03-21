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

######################################################################
# I have not gotten PTF working after installing it 'globally' inside
# the IPDK container.  I get some Python exception when trying to run
# a PTF test when it is installed that way.  I have successfully run
# PTF tests from inside of a Python virtual environment before, so
# install PTF inside of one.

apt-get install --yes python3-virtualenv

cd $HOME
virtualenv my-venv --python=python3
source my-venv/bin/activate
pip3 install git+https://github.com/p4lang/p4runtime-shell.git
pip3 install scapy

git clone https://github.com/p4lang/ptf
cd ptf
pip3 install -r requirements.txt
python3 setup.py install
