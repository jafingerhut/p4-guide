#! /bin/bash

# Copyright 2025 Andy Fingerhut
# SPDX-FileCopyrightText: 2025 Andy Fingerhut
#
# SPDX-License-Identifier: Apache-2.0

# Clone all public p4lang repositories from github.com, at least ones
# that have been active since 2021.  The list of such p4lang
# repositories was last updated on 2026-Jul-22.

# The following are neither archived, nor a fork of some other public
# repository.

mkdir -p other
cd other
for repo in \
    .github \
    PI \
    behavioral-model \
    education \
    governance \
    gsoc \
    hackathons \
    open-p4studio \
    p4-applications \
    p4-constraints \
    p4-dpdk-target \
    p4-spec \
    p4analyzer \
    p4app \
    p4app-TCP-INT \
    p4app-switchML \
    p4c \
    p4lang.github.io \
    p4mlir-incubator \
    p4per \
    p4pi \
    p4runtime \
    p4runtime-shell \
    pna \
    project-ideas \
    ptf \
    target-syslibs \
    target-utils \
    tdi \
    third-party \
    tutorials
do
    git clone https://github.com/p4lang/${repo}
done
cd ..

# As of 2026-Jul-22, these have not been updated since 2018 or earlier.
mkdir -p notupdatedsince2018
cd notupdatedsince2018
for repo in \
    ntf \
    p4-build \
    switch
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
