#! /bin/bash

BASENAME="testprog3"
mkdir -p out
set -x
p4c-dpdk \
    $* \
    --arch pna \
    --p4runtime-files ./out/${BASENAME}.p4Info.txt \
    --context ./out/${BASENAME}.context.json \
    --bf-rt-schema ./out/${BASENAME}.bf-rt.json \
    -o ./out/${BASENAME}.spec \
    ${BASENAME}.p4
