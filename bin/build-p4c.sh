#! /bin/bash

# Copyright 2017-present Cisco Systems, Inc.

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


# The maximum number of gcc/g++ jobs to run in parallel.  3 can easily
# take 1 to 1.5G of RAM, and the build will fail if you run out of RAM,
# so don't make this number huge on a machine with 4G of RAM, for example.
MAX_PARALLEL_JOBS=2

if [ -d .git -a -d midend ]
then
    echo "Found directories .git and midend"
else
    2>&1 echo "At least one of .git and midend directories is not present."
    2>&1 echo ""
    2>&1 echo "This command must be run from inside top level directory of"
    2>&1 echo "a clone of the Github repository https://github.com/p4lang/p4c"
    exit 1
fi

usage() {
    2>&1 echo "usage: $0 [ update ]"
}

DO_UPDATE_FIRST=0
if [ $# -eq 1 ]
then
    if [ "$1" == "update" ]
    then
	DO_UPDATE_FIRST=1
    else
	usage
	exit 1
    fi
elif [ $# -ne 0 ]
then
    usage
    exit 1
fi

#echo "DO_UPDATE_FIRST=${DO_UPDATE_FIRST}"
if [ ${DO_UPDATE_FIRST} -eq 1 ]
then
    echo "Will update files before clean and build."
else
    echo "Will clean and build without updating any files."
fi

set -x

if [ ${DO_UPDATE_FIRST} -eq 1 ]
then
    # Get updates from master repo
    git pull

    # Recommended in p4c's README.md
    git submodule update --init --recursive
fi

if [ -d build ]
then
    echo "Deleting build directory"
    /bin/rm -fr build
fi

echo "Building p4c from scratch"
mkdir build
cd build
# Configure for a debug build
cmake .. -DCMAKE_BUILD_TYPE=DEBUG
# Copied from p4c/Dockerfile
#cmake .. '-DCMAKE_CXX_FLAGS:STRING=-O3'

# Make all back ends, including:
# gtestp4c
# p4c-bm2-psa
# p4c-bm2-ss
# p4c-dpdk
# p4c-ebpf
# p4c-graphs
# p4c-ubpf
# p4test
#make -j${MAX_PARALLEL_JOBS}

# Make only the explicitly listed back ends:
make -j${MAX_PARALLEL_JOBS} p4c-dpdk p4test p4c-bm2-ss

set +x
echo ""
echo "If you want to run p4c automated tests, run these commands:"
echo ""
echo "    cd build"
echo "    make check"
echo ""
echo "If you want to install these versions of p4c in system-wide"
echo "directories, e.g. /usr/local/bin, run the commands:"
echo ""
echo "    cd build"
echo "    sudo make install"
