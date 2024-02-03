#! /bin/bash

set -x
mkdir -p pipe

p4c-dpdk -DTARGET_DPDK_PNA -DPNA_CONNTRACK \
    --arch pna \
    --p4runtime-files p4Info.txt \
    --bf-rt-schema bf-rt.json \
    --context pipe/context.json \
    -o pipe/dash_pipeline.spec \
    dash_pipeline.p4
