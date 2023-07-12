#!/bin/bash
#Copyright (C) 2021-2023 Intel Corporation
#SPDX-License-Identifier: Apache-2.0

# Copied and modified from the script rundemo_TAP_IO.sh

stty -echoctl # hide ctrl-c

usage() {
    echo ""
    echo "Usage:"
    echo "setup_2tapports.sh: -v|--verbose -w|--workdir -h|--help"
    echo ""
    echo "  -h|--help: Displays help"
    echo "  -v|--verbose: Enable verbose/debug output"
    echo "  -w|--workdir: Working directory"
    echo ""
}

# Parse command-line options.
SHORTOPTS=:hv,w:
LONGOPTS=help,verbose,workdir:

GETOPTS=$(getopt -o ${SHORTOPTS} --long ${LONGOPTS} -- "$@")
eval set -- "${GETOPTS}"

# Set defaults.
VERBOSE=0
WORKING_DIR=/root

# Process command-line options.
while true ; do
    case "${1}" in
    -h|--help)
        usage
        exit 1 ;;
    -v|--verbose)
        VERBOSE=1
        shift 1 ;;
    -w|--workdir)
        WORKING_DIR="${2}"
        shift 2 ;;
    --)
        shift
        break ;;
    *)
        echo "Internal error!"
        exit 1 ;;
    esac
done

SCRIPTS_DIR="${WORKING_DIR}"/scripts
DEPS_INSTALL_DIR="${WORKING_DIR}"/networking-recipe/deps_install
P4C_INSTALL_DIR="${WORKING_DIR}"/p4c/install
SDE_INSTALL_DIR="${WORKING_DIR}"/p4-sde/install
NR_INSTALL_DIR="${WORKING_DIR}"/networking-recipe/install

# Display argument data after parsing commandline arguments
if [ ${VERBOSE} -ge 1 ]
then
    echo ""
    echo "WORKING_DIR: ${WORKING_DIR}"
    echo "SCRIPTS_DIR: ${SCRIPTS_DIR}"
    echo "DEPS_INSTALL_DIR: ${DEPS_INSTALL_DIR}"
    echo "P4C_INSTALL_DIR: ${P4C_INSTALL_DIR}"
    echo "SDE_INSTALL_DIR: ${SDE_INSTALL_DIR}"
    echo "NR_INSTALL_DIR: ${NR_INSTALL_DIR}"
    echo ""
fi

killall infrap4d

echo "Setting hugepages up and starting networking-recipe processes"

unset http_proxy
unset https_proxy
unset HTTP_PROXY
unset HTTPS_PROXY

pushd "${WORKING_DIR}" > /dev/null || exit
# shellcheck source=/dev/null
. "${SCRIPTS_DIR}"/initialize_env.sh --sde-install-dir="${SDE_INSTALL_DIR}" \
      --nr-install-dir="${NR_INSTALL_DIR}" --deps-install-dir="${DEPS_INSTALL_DIR}" \
      --p4c-install-dir="${P4C_INSTALL_DIR}" > /dev/null

# shellcheck source=/dev/null
. "${SCRIPTS_DIR}"/set_hugepages.sh > /dev/null

# shellcheck source=/dev/null
. "${SCRIPTS_DIR}"/setup_nr_cfg_files.sh --nr-install-dir="${NR_INSTALL_DIR}" \
      --sde-install-dir="${SDE_INSTALL_DIR}" > /dev/null

# shellcheck source=/dev/null
. "${SCRIPTS_DIR}"/run_infrap4d.sh --nr-install-dir="${NR_INSTALL_DIR}" > /dev/null
popd > /dev/null || exit

echo "Creating TAP ports"

pushd "${WORKING_DIR}" > /dev/null || exit
# Wait for networking-recipe processes to start gRPC server and open ports for clients to connect.
sleep 1

# It appears that for the gnmi-ctl command, or the gNMI server in
# infrap4d perhaps, TAP interfaces can only have names of the form
# TAP<number>.

# It also appears that for a freshly started infrap4d process with a
# DPDK data plane, port numbers according to the DPDK data plane start
# with 0 for the first port created, and increment from then onwards.
# Thus even if you only want ports with numbers 0, 1, 2, 3, 17, 18,
# 19, 20, you must create all of them from 0 up to 20.  At least, I do
# not know a way to specify the desired DPDK data plane port number in
# the command below.
for i in `seq 0 20`
do
    gnmi-ctl set "device:virtual-device,name:TAP${i},pipeline-name:pipe,\
        mempool-name:MEMPOOL0,mtu:1500,port-type:TAP"
done
popd > /dev/null || exit

echo "Bring up the TAP ports"

for i in `seq 0 20`
do
    ip link set dev TAP${i} up
done
