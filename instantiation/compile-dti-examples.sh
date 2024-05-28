#! /bin/bash

P4C=/home/andy/p4c/build/p4c

DUMP_DIR_NAME="dump_dir"
DUMP_FEW_PASSES_OPTS="--dump ${DUMP_DIR_NAME} --top4 FrontEndLast,FrontEndDump,MidEndLast"
DUMP_MANY_PASSES_OPTS="--dump ${DUMP_DIR_NAME} --top4 Front,Mid"

mkdir -p ${DUMP_DIR_NAME}

for j in stateless-ctrl*.p4 table-ctrl*.p4
do
    k=`basename $j .p4`
    echo "------------------------------------------------------------"
    echo $j
    echo "------------------------------------------------------------"
    set -x
    #$P4C --target bmv2 --arch v1model --p4runtime-files $k.p4info.txtpb $j
    $P4C --target bmv2 --arch v1model $DUMP_MANY_PASSES_OPTS $j
    ../bin/p4c-delete-duplicate-passes.sh $j ${DUMP_DIR_NAME} >& /dev/null
    set +x
done
