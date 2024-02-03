#! /bin/bash

# Install several useful software packages inside of IPDK container

# chmod is necessary in cases where the /tmp directory inside the
# container is not world-writable.  If it is not, most or all apt-get
# commands will fail.
chmod 777 /tmp

linux_version_warning() {
    1>&2 echo "Found ID ${ID} and VERSION_ID ${VERSION_ID} in /etc/os-release"
    1>&2 echo "This script only supports these:"
    1>&2 echo "    ID ubuntu fedora"
}

if [ ! -r /etc/os-release ]
then
    1>&2 echo "No file /etc/os-release.  Cannot determine what OS this is."
    linux_version_warning
    exit 1
fi
source /etc/os-release

if [ "${ID}" = "ubuntu" ]
then
    apt-get update
    apt-get install --yes git tcpdump tcpreplay python3-venv
elif [ "${ID}" = "fedora" ]
then
    dnf -y update
    dnf -y install git tcpdump tcpreplay
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
