#! /bin/bash

BASE_DIR=${PWD}

source /etc/os-release

ARCH=$(uname -m)
PYTHON_VERSION=$(python3 -c 'import sys; print("%s.%s" % (sys.version_info.major, sys.version_info.minor))')
OUTPUT_DIR="${ID}-${VERSION_ID}-${ARCH}-python-${PYTHON_VERSION}"
mkdir -p ${OUTPUT_DIR}

echo "ARCH=${ARCH}"
echo "PYTHON_VERSION=${PYTHON_VERSION}"
echo "OUTPUT_DIR=${OUTPUT_DIR}"

for venv in \
    venv-ptf-scapy-no-bf_pktpy \
    venv-ptf-bf_pktpy-no-scapy \
    venv-ptf-both-scapy-and-bf_pktpy
do
    source ${BASE_DIR}/${venv}/bin/activate
    for pmm in bf_pktpy scapy
    do
	echo "venv ${venv} pmm ${pmm}"
	./modules-installed-by-ptf.py ${pmm} > ${OUTPUT_DIR}/${venv}-modules-imported-by-importing-${pmm}.txt
    done
done
