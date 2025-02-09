#! /bin/bash

# Copyright 2017 Cisco Systems, Inc.

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


if [ -d .git -a -d m4 ]
then
    echo "Found directories .git and m4"
else
    1>&2 echo "At least one of .git and m4 directories is not present."
    1>&2 echo ""
    1>&2 echo "This command must be run from inside top level directory of"
    1>&2 echo "a clone of the Github repository https://github.com/p4lang/p4c"
    exit 1
fi

usage() {
    1>&2 echo "usage: $0 [ update ]"
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

# Erase any old built files
make clean

if [ ${DO_UPDATE_FIRST} -eq 1 ]
then
    # Get updates from master repo
    git pull
fi

# Compile and install simple_switch and simple_switch_grpc, and I
# believe also psa_switch (but the latter is not feature complete and
# working as of 2023-Mar)
./autogen.sh
if [ -z ${VIRTUAL_ENV} ]
then
    # This case is to support P4 installs from install-p4dev-v6.sh script
    # or earlier, where there was no Python venv used.
    configure_python_prefix=""
else
    PYTHON_VENV="${VIRTUAL_ENV}"
    configure_python_prefix="--with-python_prefix=${PYTHON_VENV}"
fi
# With debug enabled in binaries:
./configure --with-pi --with-thrift ${configure_python_prefix} 'CXXFLAGS=-O0 -g'
# With debug and P4_16 stack operation support enabled in binaries:
#./configure --enable-WP4-16-stacks 'CXXFLAGS=-O0 -g'
# Without debug enabled:
#./configure
# With more aggressive C++ compiler optimization enabled, but I believe
# that with all of these options, the resulting simple_switch binary
# cannot be used to achieve passing results on all p4c tests.
#./configure 'CXXFLAGS=-g -O3' 'CFLAGS=-g -O3' --disable-logging-macros --disable-elogger

make
sudo make install
sudo ldconfig
