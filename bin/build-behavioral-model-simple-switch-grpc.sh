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


if [ -d .git -a -d m4 ]
then
    echo "Found directories .git and m4"
else
    2>&1 echo "At least one of .git and m4 directories is not present."
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
fi

# Compile and install simple_switch_grpc
cd targets/simple_switch_grpc
# Erase any old built files
make clean
./autogen.sh
# With debug enabled in binaries:
./configure --with-thrift 'CXXFLAGS=-O0 -g'
make
sudo make install
sudo ldconfig
