#! /bin/bash
# Copyright 2025 Andy Fingerhut
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0


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
    open-p4studio \
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
