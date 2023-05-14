#! /bin/bash

OUTPUT_DIR="out"
set -x
p4test --version
mkdir -p "${OUTPUT_DIR}"
p4test \
    --target bmv2 --arch v1model \
    --pp ${OUTPUT_DIR}/bit0b-bmv2.p4 \
    --dump ${OUTPUT_DIR} \
    --top4 FrontEndDump,FrontEndLast,MidEndLast \
    --testJson --maxErrorCount 100 \
    --p4runtime-files ${OUTPUT_DIR}/bit0b-bmv2.p4.p4info.txt \
    --p4runtime-entries-files ${OUTPUT_DIR}/bit0b-bmv2.p4.entries.txt \
    bit0b-bmv2.p4
