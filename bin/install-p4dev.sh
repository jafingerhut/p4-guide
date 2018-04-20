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


# Install the P4-16 (and also P4-14) compiler, and the behavioral-model
# software packet forwarding program, that can behave as just about
# any legal P4 program.

# You will likely need to enter your password for multiple uses of 'sudo'
# spread throughout this script.

# The files installed by this script consume about 4.0 GB of disk
# space.

# Size of source trees, after being built on an x86_64 machine, without
# documentation:
# p4c - a little under 1G
# behavioral-model - about 1.5G

# This script has been tested on a freshly installed Ubuntu 16.04
# system, from a file with this name: ubuntu-16.04.2-desktop-amd64.iso

# The maximum number of gcc/g++ jobs to run in parallel.  3 can easily
# take 1 to 1.5G of RAM, and the build will fail if you run out of RAM,
# so don't make this number huge on a machine with 4G of RAM, for example.
# 3 will work on a machine with 2 GB of RAM as long as you are not
# running any other processes using significant memory.
MAX_PARALLEL_JOBS=3

# Remember the current directory when the script was started:
INSTALL_DIR="${PWD}"

THIS_SCRIPT_FILE_MAYBE_RELATIVE="$0"
THIS_SCRIPT_DIR_MAYBE_RELATIVE="${THIS_SCRIPT_FILE_MAYBE_RELATIVE%/*}"
THIS_SCRIPT_DIR_ABSOLUTE=`readlink -f "${THIS_SCRIPT_DIR_MAYBE_RELATIVE}"`

echo "------------------------------------------------------------"
echo "Time and disk space used before installation begins:"
date
df -h .

# Install a few packages (vim is not strictly necessary -- installed for
# my own convenience):
sudo apt-get --yes install git vim
# Install Ubuntu packages needed by protobuf, from its src/README.md
sudo apt-get --yes install autoconf automake libtool curl make g++ unzip
# Install Ubuntu dependencies needed by p4c, from its README.md
sudo apt-get --yes install g++ git automake libtool libgc-dev bison flex libfl-dev libgmp-dev libboost-dev libboost-iostreams-dev pkg-config python python-scapy python-ipaddr tcpdump cmake
# Optional Ubuntu dependency required to compile graphs backend for
# p4c.  For more details, see:
# https://github.com/p4lang/p4c/blob/master/backends/graphs/README.md
sudo apt-get --yes install libboost-graph-dev



echo "------------------------------------------------------------"
echo "Installing p4lang/behavioral-model"
echo "start install behavioral-model:"
date

cd "${INSTALL_DIR}"
# Clone Github repo
git clone https://github.com/p4lang/behavioral-model.git

cd behavioral-model
./install_deps.sh

# Compile and install behavioral-model
./autogen.sh
# With debug enabled in binaries:
./configure 'CXXFLAGS=-O0 -g'
# Without debug enabled:
#./configure
make
sudo make install

echo "end install behavioral-model:"
date


echo "------------------------------------------------------------"
echo "Installing Google protobuf, needed for p4lang/p4c"
echo "start install protobuf:"
date

cd "${INSTALL_DIR}"
git clone https://github.com/google/protobuf
cd protobuf
# As of 2017-Dec-06, the p4lang/p4c README recommends v3.0.2 of protobuf.
#
# However, that version might not work with the latest version of
# p4lang/PI.
#
# This email message linked below suggests that v3.2.0 should soon
# become the recommended version for both p4lang/p4c and p4lang/PI.
#
# http://lists.p4.org/pipermail/p4-dev_lists.p4.org/2017-December/001655.html
#git checkout v3.0.2
git checkout v3.2.0
./autogen.sh
./configure
make
sudo make install
sudo ldconfig
# Save about 0.5G of storage by cleaning up protobuf build
make clean

echo "end install protobuf:"
date


echo "------------------------------------------------------------"
echo "Installing p4lang/p4c"
echo "start install p4c:"
date

cd "${INSTALL_DIR}"
# Clone p4c and its submodules:
git clone --recursive https://github.com/p4lang/p4c.git
cd p4c
mkdir build
cd build
# Configure for a debug build
cmake .. -DCMAKE_BUILD_TYPE=DEBUG $*
make -j${MAX_PARALLEL_JOBS}

echo "end install p4c:"
date

echo "------------------------------------------------------------"
echo "Time and disk space used when installation was complete:"
date
df -h .

P4C="${INSTALL_DIR}/p4c"
BMV2="${INSTALL_DIR}/behavioral-model"
P4GUIDE_BIN="${THIS_SCRIPT_DIR_ABSOLUTE}"

echo ""
echo "You may wish to add lines like the ones below to your .bashrc or"
echo ".profile files in your home directory to add commands like p4c-bm2-ss"
echo "and simple_switch to your command path every time you log in or create"
echo "a new shell:"
echo ""
echo "P4C=\"${P4C}\""
echo "BMV2=\"${BMV2}\""
echo "P4GUIDE_BIN=\"${P4GUIDE_BIN}\""
echo "export PATH=\"\$P4GUIDE_BIN:\$P4C/build:\$BMV2/tools:/usr/local/bin:\$PATH\""
echo ""
echo "If you use the tcsh or csh shells instead, the following lines can be"
echo "added to your .tcshrc or .cshrc file in your home directory:"
echo ""
echo "set P4C=\"${P4C}\""
echo "set BMV2=\"${BMV2}\""
echo "set P4GUIDE_BIN=\"${P4GUIDE_BIN}\""
echo "set path ( \$P4GUIDE_BIN \$P4C/build \$BMV2/tools /usr/local/bin \$path )"
