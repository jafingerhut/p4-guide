#! /bin/bash

# Install several useful software packages inside of IPDK container

# chmod is necessary in cases where the /tmp directory inside the
# container is not world-writable.  If it is not, most or all apt-get
# commands will fail.
chmod 777 /tmp

if [ "${ID}" = "ubuntu" ]
then
    apt-get update
    apt-get install --yes git tcpdump tcpreplay python3-venv
elif [ "${ID}" = "fedora" ]
then
    sudo dnf -y update
    sudo dnf -y install git tcpdump tcpreplay
fi

# Install all Python packages into a venv virtual environment
PYTHON_VENV="${HOME}/my-venv"
python3 -m venv --system-site-packages "${PYTHON_VENV}"
source "${PYTHON_VENV}/bin/activate"

pip3 install git+https://github.com/p4lang/p4runtime-shell.git
pip3 install scapy

git clone https://github.com/p4lang/ptf
cd ptf
pip3 install .
