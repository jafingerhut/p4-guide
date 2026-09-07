#! /bin/bash

SAVEDIR=$PWD

VERSION_PI="fix-dockerfile-masking-of-command-failures1"
# commit 88859f8628487131cf464a398819497739a5d2ac
# Author: Andy Fingerhut <andy_fingerhut@alum.wustl.edu>
# Date:   Sat Sep 5 17:44:07 2026 -0400
# 
#     See if running tests with `uv run` affects the results

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
docker build --progress=plain --build-context p4lang/third-party:latest=docker-image://mytp:latest -f repos/PI/Dockerfile -t mypi repos/PI
