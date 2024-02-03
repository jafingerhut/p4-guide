#!/bin/bash
#Copyright (C) 2021-2023 Intel Corporation
#SPDX-License-Identifier: Apache-2.0

# Copied and modified from the script rundemo_TAP_IO.sh

THIS_SCRIPT_FILE_MAYBE_RELATIVE="$0"
THIS_SCRIPT_DIR_MAYBE_RELATIVE="${THIS_SCRIPT_FILE_MAYBE_RELATIVE%/*}"
THIS_SCRIPT_DIR_ABSOLUTE=`readlink -f "${THIS_SCRIPT_DIR_MAYBE_RELATIVE}"`

stty -echoctl # hide ctrl-c

usage() {
    echo ""
    echo "Usage:"
    echo "tdi_pipeline_builder.sh: -v|--verbose -w|--workdir -h|--help -p|--p4dir -s|--srcfile"
    echo ""
    echo "  -h|--help: Displays help"
    echo "  -v|--verbose: Enable verbose/debug output"
    echo "  -w|--workdir: Working directory"
    echo "  -p|--p4dir: Directory containing P4 source file, and in which to write output files"
    echo "  -s|--srcfile: Base file name containing P4 source code, which must be in the P4 directory"
    echo ""
}

# Parse command-line options.
SHORTOPTS=hvw:p:s:
LONGOPTS=help,verbose,workdir:,p4dir:,srcfile:

GETOPTS=$(getopt -o ${SHORTOPTS} --long ${LONGOPTS} -- "$@")
eval set -- "${GETOPTS}"

# Set defaults.
VERBOSE=0
WORKING_DIR=/root
P4_DIR=""
P4_SRC_FNAME=""

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
    -p|--p4dir)
        P4_DIR="${2}"
        shift 2 ;;
    -s|--srcfile)
        P4_SRC_FNAME="${2}"
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

BASE_FNAME=`basename ${P4_SRC_FNAME} .p4`

if [ ! -r "${P4_DIR}/${BASE_FNAME}.conf" ]
then
    echo "Creating .conf file from template"
    sed "s/{P4_PROG_BASE_NAME}/${BASE_FNAME}/" ${THIS_SCRIPT_DIR_ABSOLUTE}/templates/template-conf-file.conf > "${BASE_FNAME}.conf"
fi


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

unset http_proxy
unset https_proxy
unset HTTP_PROXY
unset HTTPS_PROXY

pushd "${WORKING_DIR}" > /dev/null || exit
# shellcheck source=/dev/null
. "${SCRIPTS_DIR}"/initialize_env.sh --sde-install-dir="${SDE_INSTALL_DIR}" \
      --nr-install-dir="${NR_INSTALL_DIR}" --deps-install-dir="${DEPS_INSTALL_DIR}" \
      --p4c-install-dir="${P4C_INSTALL_DIR}" > /dev/null
popd > /dev/null || exit

echo "Running pipeline builder"
pushd "${P4_DIR}" > /dev/null || exit
tdi_pipeline_builder --p4c_conf_file=${BASE_FNAME}.conf \
    --bf_pipeline_config_binary_file=${BASE_FNAME}.pb.bin
popd > /dev/null || exit

if [ ${VERBOSE} -ge 1 ]
then
    echo ""
    echo "Files in ${P4_DIR} just after tdi_pipeline_builder:"
    ls -lrta "${P4_DIR}"
    echo "----------------------------------------"
fi
