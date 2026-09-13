#! /bin/bash

SAVEDIR=$PWD

VERSION_BMV2="14e39e2217b576910a4edf8f68a82278adcc4194"
# commit 14e39e2217b576910a4edf8f68a82278adcc4194 (HEAD -> main, up/main, origin/main, origin/HEAD)
# Author: Andy Fingerhut <andy_fingerhut@alum.wustl.edu>
# Date:   Wed Sep 9 15:03:51 2026 -0400
# 
#     Cause cmake install to put Python code in venv if one has been configured (#1450)

if [ ! -d repos/behavioral-model ]
then
    mkdir -p repos
    cd repos
    git clone https://github.com/jafingerhut/behavioral-model
    cd behavioral-model
    git checkout ${VERSION_BMV2}
    git submodule update --init --recursive
    cd ${SAVEDIR}
fi

set -x
docker build --progress=plain --build-context p4lang/third-party:latest=docker-image://mytp:latest -f repos/behavioral-model/Dockerfile.noPI -t mybmv2-nopi --build-arg IMAGE_TYPE=test repos/behavioral-model
