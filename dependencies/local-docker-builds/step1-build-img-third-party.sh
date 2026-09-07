#! /bin/bash

SAVEDIR=$PWD

VERSION_THIRD_PARTY="4a75ef2bc8b16060677ed7fffa62bd0fe7f03362"
# commit 4a75ef2bc8b16060677ed7fffa62bd0fe7f03362 (HEAD -> main, origin/main, origin/HEAD)
# Author: Andy Fingerhut <andy.fingerhut@gmail.com>
# Date:   Tue Sep 1 22:30:22 2026 -0400
# 
#     Add missing Dockerfile file name parameter to Github action (#48)

if [ ! -d repos/third-party ]
then
    mkdir -p repos
    cd repos
    git clone https://github.com/p4lang/third-party
    cd third-party
    git checkout ${VERSION_THIRD_PARTY}
    git submodule update --init --recursive
    cd ${SAVEDIR}
fi

docker build --progress=plain -f repos/third-party/Dockerfile.24 -t mytp repos/third-party
