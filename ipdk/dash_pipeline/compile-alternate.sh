#! /bin/bash

set -x
BASENAME="dash_pipeline"
mkdir -p out


p4c-dpdk \
    -DTARGET_DPDK_PNA \
    -DPNA_CONNTRACK \
    -DDISABLE_128BIT_ARITHMETIC \
    -DUSE_64BIT_FOR_IPV6_ADDRESSES \
    --arch pna \
    --p4runtime-files out/${BASENAME}.p4Info.txt \
    --context out/${BASENAME}.context.json \
    --bf-rt-schema out/${BASENAME}.bf-rt.json \
    -o out/${BASENAME}.spec \
    ${BASENAME}.p4
