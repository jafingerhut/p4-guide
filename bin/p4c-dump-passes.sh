#! /bin/bash
# SPDX-FileCopyrightText: 2019 Andy Fingerhut
# Copyright 2019 Andy Fingerhut
#
# SPDX-License-Identifier: Apache-2.0

print_usage() {
    1>&2 echo "usage: `basename $0` <p4_source_filename> [ help | noarch | bmv2 | nopassdump | fewpasses | allpasses | allpassesdeletedups | genp4rt ]*"
    1>&2 echo ""
    1>&2 echo "Note: You should set up your command path so that an appropriate"
    1>&2 echo "version of the 'p4c' command is first in your path."
    1>&2 echo ""
    1>&2 echo "Note: Some of the command line options to the 'p4c' command"
    1>&2 echo "used by this script give an error if you are running a 'p4c'"
    1>&2 echo "executable installed in a system-wide location like"
    1>&2 echo "/usr/local/bin.  They should work if you are using an"
    1>&2 echo "a 'p4c' executable that you compiled from source code and is"
    1>&2 echo "in a directory like $HOME/p4c/build/p4c"
}

if [ $# -lt 1 ]
then
    print_usage
    exit 1
fi

P4_SRC_FNAME="$1"
if [ "${P4_SRC_FNAME}" == "help" ]
then
    print_usage
    exit 0
fi

if [ ! -r "${P4_SRC_FNAME}" ]
then
    1>&2 echo "No such file name: ${P4_SRC_FNAME}"
    exit 1
fi
shift

DUMP_DIR_NAME="tmp"
CMD="p4test"
PASSES_OPTS="--dump ${DUMP_DIR_NAME} --top4 FrontEndLast,FrontEndDump,MidEndLast"
P4RT_OPTS=""
DELETE_DUPLICATE_PASSES=0

while [ $# -ge 1 ]
do
    case "$1" in
	help)
	    print_usage
	    exit 0
            ;;
	noarch)
	    CMD="p4test"
            ;;
        bmv2)
	    CMD="p4c-bm2-ss --target bmv2 --arch v1model"
            ;;    
        nopassdump)
	    PASSES_OPTS=""
	    ;;
        fewpasses)
	    PASSES_OPTS="--dump ${DUMP_DIR_NAME} --top4 FrontEndLast,FrontEndDump,MidEndLast"
            ;;    
        allpasses)
	    PASSES_OPTS="--dump ${DUMP_DIR_NAME} --top4 Front,Mid"
            ;;    
        allpassesdeletedups)
	    PASSES_OPTS="--dump ${DUMP_DIR_NAME} --top4 Front,Mid"
	    DELETE_DUPLICATE_PASSES=1
            ;;    
        genp4rt)
	    P4RT_FILE1="${P4_SRC_FNAME}.p4info.txtpb"
	    P4RT_FILE2="${P4_SRC_FNAME}.p4info.json"
	    P4RT_OPTS="--p4runtime-files ${P4RT_FILE1},${P4RT_FILE2}"
            ;;    
        *)    
            1>&2 echo "Unknown command line option: $1"
            1>&2 echo ""
            print_usage
            exit 1
            ;;
    esac
    shift
done

if [ "${PASSES_OPTS}" != "" ]
then
    mkdir -p ${DUMP_DIR_NAME}
fi
set -x
${CMD} ${PASSES_OPTS} ${P4RT_OPTS} "${P4_SRC_FNAME}"

set +x

if [ ${DELETE_DUPLICATE_PASSES} -eq 1 ]
then
    cd "${DUMP_DIR_NAME}"
    echo "# Deleting duplicate pass dump files ..."
    #set -x
    lastkeptfile=""
    BNAME=`basename "${P4_SRC_FNAME}" .p4`
    for curname in ${BNAME}-*.p4
    do
        if [ "${lastkeptfile}" == "" ]
        then
	    lastkeptfile="${curname}"
        else
	    diff "${lastkeptfile}" "${curname}" > /dev/null
	    status=$?
	    if [ ${status} -eq 0 ]
	    then
	        # Identical files, so remove the next one
	        echo "# Deleting ${curname} as duplicate of ${lastkeptfile}"
	        /bin/rm -f "${curname}"
	    else
	        # Files differ, so remember the current one as the last kept
	        # one.
	        echo "ediff ${DUMP_DIR_NAME}/${lastkeptfile} ${DUMP_DIR_NAME}/${curname}"
	        lastkeptfile="${curname}"
	    fi
        fi
    done
else
    echo "val=${DELETE_DUPLICATE_PASSES}"
fi
