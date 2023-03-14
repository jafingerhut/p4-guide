#!/bin/bash
#Copyright (C) 2021-2023 Intel Corporation
#SPDX-License-Identifier: Apache-2.0

# Copied and modified from the script rundemo_TAP_IO.sh

stty -echoctl # hide ctrl-c

usage() {
    echo ""
    echo "Usage:"
    echo "setup_2tapports.sh: -w|--workdir -h|--help"
    echo ""
    echo "  -h|--help: Displays help"
    echo "  -w|--workdir: Working directory"
    echo ""
}

# Parse command-line options.
SHORTOPTS=:h,w:
LONGOPTS=help,workdir:

GETOPTS=$(getopt -o ${SHORTOPTS} --long ${LONGOPTS} -- "$@")
eval set -- "${GETOPTS}"

# Set defaults.
WORKING_DIR=/root

# Process command-line options.
while true ; do
    case "${1}" in
    -h|--help)
        usage
        exit 1 ;;
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
echo ""
echo "WORKING_DIR: ${WORKING_DIR}"
echo "SCRIPTS_DIR: ${SCRIPTS_DIR}"
echo "DEPS_INSTALL_DIR: ${DEPS_INSTALL_DIR}"
echo "P4C_INSTALL_DIR: ${P4C_INSTALL_DIR}"
echo "SDE_INSTALL_DIR: ${SDE_INSTALL_DIR}"
echo "NR_INSTALL_DIR: ${NR_INSTALL_DIR}"
echo ""

echo "Deleting namespaces VM0, VM1 (if any) and killing infrap4d processes ..."

ip netns del VM0
ip netns del VM1

killall infrap4d

echo "Setting hugepages up and starting networking-recipe processes"

unset http_proxy
unset https_proxy
unset HTTP_PROXY
unset HTTPS_PROXY

pushd "${WORKING_DIR}" || exit
# shellcheck source=/dev/null
. "${SCRIPTS_DIR}"/initialize_env.sh --sde-install-dir="${SDE_INSTALL_DIR}" \
      --nr-install-dir="${NR_INSTALL_DIR}" --deps-install-dir="${DEPS_INSTALL_DIR}" \
      --p4c-install-dir="${P4C_INSTALL_DIR}"

# shellcheck source=/dev/null
. "${SCRIPTS_DIR}"/set_hugepages.sh

# shellcheck source=/dev/null
. "${SCRIPTS_DIR}"/setup_nr_cfg_files.sh --nr-install-dir="${NR_INSTALL_DIR}" \
      --sde-install-dir="${SDE_INSTALL_DIR}"

# shellcheck source=/dev/null
. "${SCRIPTS_DIR}"/run_infrap4d.sh --nr-install-dir="${NR_INSTALL_DIR}"
popd || exit

echo "Creating TAP ports"

pushd "${WORKING_DIR}" || exit
# Wait for networking-recipe processes to start gRPC server and open ports for clients to connect.
sleep 1

gnmi-ctl set "device:virtual-device,name:TAP0,pipeline-name:pipe,\
    mempool-name:MEMPOOL0,mtu:1500,port-type:TAP"
gnmi-ctl set "device:virtual-device,name:TAP1,pipeline-name:pipe,\
    mempool-name:MEMPOOL0,mtu:1500,port-type:TAP"
popd || exit

echo "Create two namespaces VM0, VM1"

ip netns add VM0
ip netns add VM1

echo "Move TAP ports to respective namespaces and bringup the ports"

ip link set TAP0 netns VM0
ip netns exec VM0 ip link set dev TAP0 up
ip link set TAP1 netns VM1
ip netns exec VM1 ip link set dev TAP1 up
