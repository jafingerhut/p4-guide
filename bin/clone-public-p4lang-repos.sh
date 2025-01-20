#! /bin/bash

# Clone all public p4lang repositories from github.com.  The list of
# public p4lang repositories was last updated on 2024-Dec-23.

# The following are neither archived, nor a fork of some other public
# repository.

mkdir -p other
cd other
for repo in \
    PI \
    behavioral-model \
    education \
    governance \
    gsoc \
    hackathons \
    ntf \
    p4-applications \
    p4-build \
    p4-constraints \
    p4-dpdk-target \
    p4-spec \
    p4analyzer \
    p4app \
    p4app-TCP-INT \
    p4app-switchML \
    p4c \
    p4lang.github.io \
    p4pi \
    p4runtime \
    p4runtime-shell \
    pna \
    project-ideas \
    ptf \
    switch \
    target-syslibs \
    target-utils \
    tdi \
    third-party \
    tutorials
do
    git clone https://github.com/p4lang/${repo}
done
cd ..

# Archived repositories
mkdir -p archived
cd archived
for repo in \
    p4-hlir \
    p4c-behavioral \
    p4c-bm \
    p4factory \
    p4ofagent \
    papers \
    scapy-vxlan
do
    git clone https://github.com/p4lang/${repo}
done
cd ..

# Repositories that are forks of other public repositories
mkdir -p forks
cd forks
for repo in \
    SAI \
    grpc \
    mininet \
    protobuf \
    rules_protobuf \
    thrift
do
    git clone https://github.com/p4lang/${repo}
done
cd ..
