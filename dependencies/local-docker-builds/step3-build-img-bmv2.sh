#! /bin/bash

SAVEDIR=$PWD

VERSION_BMV2="add-extra-cmake-debug1"
# commit a2117a9a22735741a9ec3b2a8f5e97524434d173 (HEAD -> add-extra-cmake-debug1, origin/add-extra-cmake-debug1)
# Author: Andy Fingerhut <andy_fingerhut@alum.wustl.edu>
# Date:   Mon Sep 7 13:55:53 2026 -0400
# 
#     Cause cmake install to put Python code in venv if one has been configured

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
docker build --progress=plain --build-context p4lang/pi:latest=docker-image://mypi:latest -f repos/behavioral-model/Dockerfile -t mybmv2 repos/behavioral-model
