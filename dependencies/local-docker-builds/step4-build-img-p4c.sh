#! /bin/bash

SAVEDIR=$PWD

VERSION_P4C="a19f1c3d85a867a6288fd983f7bad505ac47d728"

if [ ! -d repos/p4c ]
then
    mkdir -p repos
    cd repos
    git clone https://github.com/jafingerhut/p4c
    cd p4c
    git checkout ${VERSION_P4C}
    git submodule update --init --recursive
    cd ${SAVEDIR}
fi

set -x
docker build --progress=plain --build-context p4lang/behavioral-model:latest=docker-image://mybmv2:latest --network host -f repos/p4c/Dockerfile -t myp4c-test --build-arg IMAGE_TYPE=test repos/p4c
