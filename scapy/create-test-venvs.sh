#! /bin/bash

BASE_DIR=${PWD}
CREATE_VENV="${HOME}/p4-guide/scapy/create-python-venv.sh"

function install_bf_pktpy() {
    cd ${BASE_DIR}/open-p4studio/pkgsrc/ptf-modules/bf-pktpy
    pip install .
    # Install packages required for bf-pktpy to work.
    #sudo apt-get install python3-dev
    pip install six getmac scapy_helper psutil netifaces
}

function install_scapy() {
    pip install scapy==2.5.0
}

function install_ptf() {
    cd ${BASE_DIR}/ptf
    pip install .
}

cd ${BASE_DIR}
if [ -d open-p4studio ]
then
    echo "Found existing directory ${BASE_DIR}/open-p4studio"
else
    git clone https://github.com/p4lang/open-p4studio
fi
cd ${BASE_DIR}/open-p4studio/pkgsrc/ptf-utils/bf_pktpy

cd ${BASE_DIR}
if [ -d ptf ]
then
    echo "Found existing directory ${BASE_DIR}/ptf"
else
    git clone https://github.com/p4lang/ptf
fi

echo "----------------------------------------"
echo "venv-ptf-scapy-no-bf_pktpy"
echo "----------------------------------------"
${CREATE_VENV} ${BASE_DIR}/venv-ptf-scapy-no-bf_pktpy
source ${BASE_DIR}/venv-ptf-scapy-no-bf_pktpy/bin/activate
install_scapy
install_ptf
pip --verbose list

echo "----------------------------------------"
echo "venv-ptf-bf_pktpy-no-scapy"
echo "----------------------------------------"
${CREATE_VENV} ${BASE_DIR}/venv-ptf-bf_pktpy-no-scapy
source ${BASE_DIR}/venv-ptf-bf_pktpy-no-scapy/bin/activate
install_bf_pktpy
install_ptf
pip --verbose list

echo "----------------------------------------"
echo "venv-ptf-bf_pktpy-no-scapy"
echo "----------------------------------------"
${CREATE_VENV} ${BASE_DIR}/venv-ptf-both-scapy-and-bf_pktpy
source ${BASE_DIR}/venv-ptf-both-scapy-and-bf_pktpy/bin/activate
install_scapy
install_bf_pktpy
install_ptf
pip --verbose list
