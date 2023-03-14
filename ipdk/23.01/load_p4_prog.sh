#!/bin/bash
#Copyright (C) 2021-2023 Intel Corporation
#SPDX-License-Identifier: Apache-2.0

# Copied and modified from the script rundemo_TAP_IO.sh

stty -echoctl # hide ctrl-c

usage() {
    echo ""
    echo "Usage:"
    echo "load_p4_prog.sh: -w|--workdir -h|--help -p|--p4bin -i|--p4info"
    echo ""
    echo "  -h|--help: Displays help"
    echo "  -w|--workdir: Working directory"
    echo "  -p|--p4bin: compiled P4 binary output for DPDK"
    echo "  -i|--p4info: P4Info file resulting from compiling P4 source file"
    echo ""
}

# Parse command-line options.
SHORTOPTS=hw:p:i:
LONGOPTS=help,workdir:,p4bin:,p4info:

GETOPTS=$(getopt -o ${SHORTOPTS} --long ${LONGOPTS} -- "$@")
eval set -- "${GETOPTS}"

# Set defaults.
WORKING_DIR=/root
P4_DIR=""
P4_SRC_FNAME=""
DEBUG_LEVEL=1

# Process command-line options.
while true ; do
    case "${1}" in
    -h|--help)
        usage
        exit 1 ;;
    -w|--workdir)
        WORKING_DIR="${2}"
        shift 2 ;;
    -p|--p4bin)
        P4_BINARY_FNAME="${2}"
        shift 2 ;;
    -i|--p4info)
        P4INFO_FNAME="${2}"
        shift 2 ;;
    --)
        shift
        break ;;
    *)
        echo "Internal error!"
        exit 1 ;;
    esac
done

if [ "${P4_BINARY_FNAME}" == "" ]
then
    echo "Must specify the compiled P4 binary output for DPDK"
    usage
    exit 1
fi

if [ "${P4INFO_FNAME}" == "" ]
then
    echo "Must specify the P4Info file resulting from compiling P4 source file"
    usage
    exit 1
fi

if [ ! -r "${P4_BINARY_FNAME}" ]
then
    echo "P4 binary output file not found, or not readable: ${P4_BINARY_FNAME}"
    usage
    exit 1
fi

if [ ! -r "${P4INFO_FNAME}" ]
then
    echo "P4Info file not found, or not readable: ${P4INFO_FNAME}"
    usage
    exit 1
fi


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

unset http_proxy
unset https_proxy
unset HTTP_PROXY
unset HTTPS_PROXY

pushd "${WORKING_DIR}" || exit
# shellcheck source=/dev/null
. "${SCRIPTS_DIR}"/initialize_env.sh --sde-install-dir="${SDE_INSTALL_DIR}" \
      --nr-install-dir="${NR_INSTALL_DIR}" --deps-install-dir="${DEPS_INSTALL_DIR}" \
      --p4c-install-dir="${P4C_INSTALL_DIR}"
popd || exit

echo "Loading compiled P4 program into infrap4d"

p4rt-ctl set-pipe br0 "${P4_BINARY_FNAME}" "${P4INFO_FNAME}"
