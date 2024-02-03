#! /bin/bash

mkdir -p pipe
p4c-dpdk --arch psa \
    --p4runtime-files p4Info.txt \
    --bf-rt-schema bf-rt.json \
    --context pipe/context.json \
    -o pipe/testprog1.spec \
    testprog1.p4
