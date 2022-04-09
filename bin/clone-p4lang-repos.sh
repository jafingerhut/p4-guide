#! /bin/bash

# Create a clone of all public repositories in the organization
# https://github.com/p4lang

# There were 41 repositories in the https://github.com/p4lang
# organization as of 2022-Apr-02.  They are listed below, sorted from
# most recently updated first, to least recently updated last:

OUTF="clone-p4lang-repos-log.txt"

# These repos are private, not public.
# p4-stdlib
# p4book

for j in \
    behavioral-model \
    tdi \
    p4c \
    p4-spec \
    p4runtime \
    tutorials \
    p4-dpdk-target \
    PI \
    target-utils \
    p4pi \
    p4app-switchML \
    p4-constraints \
    pna \
    ptf \
    third-party \
    p4runtime-shell \
    p4ofagent \
    target-syslibs \
    scapy-vxlan \
    p4-applications \
    p4lang.github.io \
    p4app \
    switch \
    governance \
    p4c-bm \
    ntf \
    hackathons \
    education \
    SAI \
    p4-hlir \
    grpc \
    protobuf \
    rules_protobuf \
    p4factory \
    p4-build \
    p4c-behavioral \
    papers \
    thrift \
    mininet
do
    git clone https://github.com/p4lang/$j
    cd $j
    echo "----------------------------------------" >> "${OUTF}"
    echo "https://github.com/p4lang/$j" >> "${OUTF}"
    git log -n 1 | head -n 3 >> "${OUTF}"
    echo "https://github.com/p4lang/$j" >> "${OUTF}"
    find . -name '*.p4' >> "${OUTF}"
    find . -name '*.p4' | wc >> "${OUTF}"
    cd ..
done
