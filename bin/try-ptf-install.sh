#! /bin/bash

# Try installing PTF on a system, and report detailed results about
# relevant vrsions of software installed.

if [ ! -r /etc/os-release ]
then
    1>&2 echo "No file /etc/os-release.  Cannot determine what OS this is."
    linux_version_warning
    exit 1
fi
source /etc/os-release
echo "Found ID ${ID} and VERSION_ID ${VERSION_ID} in /etc/os-release"

set -x
set -e
if [ "${ID}" = "ubuntu" ]
then
    sudo apt-get --yes install git python3-pip
elif [ "${ID}" = "fedora" ]
then
    sudo dnf -y install git python3-pip
fi
python3 --version
pip3 --version

PTF_COMMIT="771a45249de2f287377b4690cd13adc18f989638"   # 2023-Jun-19
git clone https://github.com/p4lang/ptf
cd ptf
git checkout "${PTF_COMMIT}"
sudo pip install .
