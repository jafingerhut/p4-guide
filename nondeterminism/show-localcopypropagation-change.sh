#! /bin/bash

if [ $# -ne 1 ]
then
    1>&2 echo "usage: `basename $0` <program.p4>"
    exit 1
fi

PROG_NAME="$1"

if [ ! -e "${PROG_NAME}" ]
then
    1>&2 echo "File not found: ${PROG_NAME}"
    exit 1
fi

k=`basename $PROG_NAME .p4`

set -x
/bin/rm -fr tmp
mkdir -p tmp
p4c-bm2-ss --version
p4c-bm2-ss --dump tmp --top4 Front,Mid $k.p4
diff -c tmp/$k-BMV2::SimpleSwitchMidEnd_27_ConstantFolding.p4 tmp/$k-BMV2::SimpleSwitchMidEnd_28_LocalCopyPropagation.p4
