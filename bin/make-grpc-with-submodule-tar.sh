#! /bin/bash

# The submodules of the grpc source repository in general differ in
# their versions from one tag of grpc to another.

# They can take a fair amount of time to download.

# This script is intended to let me create a tar file of grpc at a
# chosen tag, with all of its submodules included, so that I can
# create tar files for as many versions of grpc source code as I wish
# while I work on other things.  Then they can be ready for me to try
# build experiments when I want, speeding up those experiments.

GRPC_VERSION="$1"

set -x
mkdir "grpc-v${GRPC_VERSION}"
cd "grpc-v${GRPC_VERSION}"
tar xkzf ../grpc.tar.gz
cd grpc
git checkout v${GRPC_VERSION}
git submodule update --init --recursive
cd ..
tar czf grpc-with-submodules-v${GRPC_VERSION}.tar.gz grpc/
mv grpc-with-submodules-v${GRPC_VERSION}.tar.gz ..
