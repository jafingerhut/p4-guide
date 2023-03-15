#!/bin/bash
#Copyright (C) 2021-2023 Intel Corporation
#SPDX-License-Identifier: Apache-2.0

# Copied and modified from the script rundemo_TAP_IO.sh

stty -echoctl # hide ctrl-c

usage() {
    echo ""
    echo "Usage:"
    echo "compile_p4_prog.sh: -w|--workdir -h|--help -p|--p4dir -s|--srcfile"
    echo ""
    echo "  -h|--help: Displays help"
    echo "  -w|--workdir: Working directory"
    echo "  -p|--p4dir: Directory containing P4 source file, and in which to write output files"
    echo "  -s|--srcfile: Base file name containing P4 source code, which must be in the P4 directory"
    echo "  -a|--arch: P4 architecture to use.  Supported values: psa, pna (default: pna)"
    echo ""
}

# Parse command-line options.
SHORTOPTS=hw:p:s:a:
LONGOPTS=help,workdir:,p4dir:,srcfile:,arch:

GETOPTS=$(getopt -o ${SHORTOPTS} --long ${LONGOPTS} -- "$@")
eval set -- "${GETOPTS}"

# Set defaults.
WORKING_DIR=/root
P4_DIR=""
P4_SRC_FNAME=""
P4_ARCH="pna"
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
    -p|--p4dir)
        P4_DIR="${2}"
        shift 2 ;;
    -s|--srcfile)
        P4_SRC_FNAME="${2}"
        shift 2 ;;
    -a|--arch)
        P4_ARCH="${2}"
        shift 2 ;;
    --)
        shift
        break ;;
    *)
        echo "Internal error!"
        exit 1 ;;
    esac
done

if [ "${P4_DIR}" == "" ]
then
    echo "Must specify the directory where the p4c output files will be placed"
    usage
    exit 1
fi

if [ "${P4_SRC_FNAME}" == "" ]
then
    echo "Must specify the P4 source file name"
    usage
    exit 1
fi

if [ ! -r "${P4_DIR}/${P4_SRC_FNAME}" ]
then
    echo "P4 source file not found, or not readable: ${P4_DIR}/${P4_SRC_FNAME}"
    usage
    exit 1
fi

BASE_FNAME=`basename ${P4_SRC_FNAME} .p4`


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

echo "Compiling P4 program ${P4_SRC_FNAME}"

# TODO: I do not think the next line is needed
#export OUTPUT_DIR="${P4_DIR}"

if [ ${DEBUG_LEVEL} -ge 2 ]
then
    echo ""
    echo "Files in ${P4_DIR} just before p4c:"
    ls -lrta "${P4_DIR}"
    echo "----------------------------------------"
fi

p4c --arch "${P4_ARCH}" --target dpdk \
    --output "${P4_DIR}"/pipe \
    --p4runtime-files "${P4_DIR}"/p4Info.txt \
    --bf-rt-schema "${P4_DIR}"/bf-rt.json \
    --context "${P4_DIR}"/pipe/context.json \
    "${P4_DIR}/${P4_SRC_FNAME}"

if [ ${DEBUG_LEVEL} -ge 2 ]
then
    echo ""
    echo "Files in ${P4_DIR} just after p4c:"
    ls -lrta "${P4_DIR}"
    echo "----------------------------------------"
fi

echo "Running pipeline builder"
pushd "${P4_DIR}" || exit
tdi_pipeline_builder --p4c_conf_file=${BASE_FNAME}.conf \
    --bf_pipeline_config_binary_file=${BASE_FNAME}.pb.bin
popd || exit

if [ ${DEBUG_LEVEL} -ge 1 ]
then
    echo ""
    echo "Files in ${P4_DIR} just after tdi_pipeline_builder:"
    ls -lrta "${P4_DIR}"
    echo "----------------------------------------"
fi
