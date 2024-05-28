#! /bin/bash

P4C="p4c"

for j in weird-case*.p4
do
    k=`basename $j .p4`
    echo "------------------------------------------------------------"
    set -x
    ${P4C} --target bmv2 --arch v1model --p4runtime-files ${k}.p4info.txtpb $j
    set +x
done
