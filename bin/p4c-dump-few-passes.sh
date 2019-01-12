#! /bin/bash

if [ $# -ne 1 ]
then
    1>&2 echo "usage: `basename $0` <p4_source_filename>"
    exit 1
fi


P4_SRC_FNAME="$1"

GEN_P4RT=1
#GEN_P4RT=0
GEN_PASSES=1
#GEN_PASSES=0

PASSES_OPTS=""
if [ ${GEN_PASSES} == 1 ]
then
    DIR_NAME="tmp"
    mkdir -p ${DIR_NAME}
    PASSES_OPTS="--dump ${DIR_NAME} --top4 FrontEndLast,FrontEndDump,MidEndLast"
fi

set -x
if [ ${GEN_P4RT} == 1 ]
then
    for FORMAT in text json
    do
	P4RT_OPTS="--p4runtime-format $FORMAT --p4runtime-file ${P4_SRC_FNAME}.p4info.$FORMAT"
	p4c --target bmv2 --arch v1model ${PASSES_OPTS} ${P4RT_OPTS} "${P4_SRC_FNAME}"
    done
else
    p4c --target bmv2 --arch v1model ${PASSES_OPTS} "${P4_SRC_FNAME}"
fi

