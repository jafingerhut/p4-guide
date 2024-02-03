#! /bin/bash

# Remember the current directory when the script was started:
RUN_DIR="${PWD}"

THIS_SCRIPT_FILE_MAYBE_RELATIVE="$0"
THIS_SCRIPT_DIR_MAYBE_RELATIVE="${THIS_SCRIPT_FILE_MAYBE_RELATIVE%/*}"
THIS_SCRIPT_DIR_ABSOLUTE=`readlink -f "${THIS_SCRIPT_DIR_MAYBE_RELATIVE}"`


usage() {
    echo ""
    echo "Usage:"
    echo "$0: -v|--verbose -h|--help -p|--p4dir -s|--srcfile -a|--arch"
    echo ""
    echo "  -h|--help: Displays help"
    echo "  -v|--verbose: Enable verbose/debug output"
    echo "  -p|--p4dir: Directory containing P4 source file, and in which to write output files"
    echo "  -s|--srcfile: Base file name containing P4 source code, which must be in the P4 directory"
    echo "  -a|--arch: P4 architecture to use.  Supported values: psa, pna (default: pna)"
    echo ""
}

# Parse command-line options.
SHORTOPTS=hvp:s:a:
LONGOPTS=help,verbose,p4dir:,srcfile:,arch:

GETOPTS=$(getopt -o ${SHORTOPTS} --long ${LONGOPTS} -- "$@")
eval set -- "${GETOPTS}"

# Set defaults.
VERBOSE=0
P4_DIR=""
P4_SRC_FNAME=""
P4_ARCH="pna"

# Process command-line options.
while true ; do
    case "${1}" in
    -h|--help)
        usage
        exit 1 ;;
    -v|--verbose)
        VERBOSE=1
        shift 1 ;;
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
    P4_DIR="."
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

set -ex
cd "${P4_DIR}"
mkdir -p "./out"
p4c-dpdk \
    --arch "${P4_ARCH}" \
    --p4runtime-files "./out/${BASE_FNAME}.p4Info.txt" \
    --context "./out/${BASE_FNAME}.context.json" \
    --bf-rt-schema "./out/${BASE_FNAME}.bf-rt.json" \
    -o "./out/${BASE_FNAME}.spec" \
    "${BASE_FNAME}.p4"

set +ex
if [ ${VERBOSE} -ge 1 ]
then
    echo ""
    echo "Files in ${P4_DIR}/out just after p4c:"
    ls -lrta "./out"
    echo "----------------------------------------"
fi
