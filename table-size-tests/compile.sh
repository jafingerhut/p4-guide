#! /bin/bash

#for BASENAME in table-size-tests-bmv2 keyless-table-with-entries-bmv2

for BASENAME in table-size-tests-bmv2
do
    set -x
    p4c --target bmv2 --arch v1model --p4runtime-files ${BASENAME}.p4info.txtpb ${BASENAME}.p4
    set +x
done
