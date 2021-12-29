#! /bin/bash

# v1model architecture programs for bmv2 target

for j in v1model*.p4
do
    set -x
    p4c --target bmv2 --arch v1model $j
    set +x
done

# PSA architecture programs for bmv2 target

for j in psa*.p4
do
    k=`basename $j .p4`
    set -x
    p4c-bm2-psa $j -o $k.json
    set +x
done
