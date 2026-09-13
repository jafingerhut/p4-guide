#! /bin/bash

SAVEDIR=$PWD

VERSION_PI="ece73758c20b0c5a539a73e903ee242f89cf4dac"
# commit ece73758c20b0c5a539a73e903ee242f89cf4dac (HEAD -> master, tag: v0.1.4, up/main, origin/master, origin/HEAD)
# Author: github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com>
# Date:   Sat Sep 12 13:06:51 2026 -0400
# 
#     Automated Release v0.1.4 (#671)

if [ ! -d repos/PI ]
then
    mkdir -p repos
    cd repos
    git clone https://github.com/jafingerhut/PI
    cd PI
    git checkout ${VERSION_PI}
    git submodule update --init --recursive
    cd ${SAVEDIR}
fi

set -x
docker build --progress=plain --build-context p4lang/behavioral-model:no-pi=docker-image://mybmv2-nopi:latest -f repos/PI/Dockerfile.bmv2 -t mypi2 --build-arg IMAGE_TYPE=test --build-arg CC=gcc --build-arg CXX=g++ repos/PI
