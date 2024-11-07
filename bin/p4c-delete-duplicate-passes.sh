#! /bin/bash

if [ $# -ne 2 ]
then
    1>&2 echo "usage: `basename $0` <p4_source_filename> <dump_dir>"
    exit 1
fi

P4_SRC_FNAME="$1"
DUMP_DIR="$2"
BNAME=`basename "${P4_SRC_FNAME}" .p4`

if [ ! -d "${DUMP_DIR}" ]
then
    1>&2 echo "No such directory: ${DUMP_DIR}"
    exit 1
fi
cd "${DUMP_DIR}"

#set -vx

lsatkeptfile=""
for curname in ${BNAME}-*.p4
do
    if [ "${lastkeptfile}" == "" ]
    then
	lastkeptfile="${curname}"
    else
	diff "${lastkeptfile}" "${curname}" > /dev/null
	status=$?
	if [ ${status} == 0 ]
	then
	    # Identical files, so remove the next one
	    echo "# Deleting ${curname} as duplicate of ${lastkeptfile}"
	    /bin/rm -f "${curname}"
	else
	    # Files differ, so remember the current one as the last kept
	    # one.
	    echo "ediff ${DUMP_DIR}/${lastkeptfile} ${DUMP_DIR}/${curname}"
	    lastkeptfile="${curname}"
	fi
    fi
done
