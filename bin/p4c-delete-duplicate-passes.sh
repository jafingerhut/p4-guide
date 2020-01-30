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

frontendpass=0
lastkeptfile="not found"
for n in ${BNAME}-FrontEnd_${frontendpass}_*.p4*
do
    lastkeptfile="${n}"
done
if [ "${lastkeptfile}" == "not found" ]
then
    1>&2 echo "No such file: ${lastkeptfile}"
    exit 1
fi

for frontendpass in `seq 1 100`
do
    for n in ${BNAME}-FrontEnd_${frontendpass}_*.p4*
    do
	curname="${n}"
    done
    if [ "${curname}" == "not found" ]
    then
        1>&2 echo "No such file: ${curname}"
        exit 1
    fi
    if [ ! -e "${curname}" ]
    then
	echo "# No file with name ${curname}.  Probably no such compiler pass."
	break
    fi
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
done

for midendpass in `seq 0 100`
do
    for n in ${BNAME}-*MidEnd_${midendpass}_*.p4*
    do
	curname="${n}"
    done
    if [ "${curname}" == "not found" ]
    then
        1>&2 echo "No such file: ${curname}"
        exit 1
    fi
    if [ ! -e "${curname}" ]
    then
	echo "# No file with name ${curname}.  Probably no such compiler pass."
	break
    fi
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
done
