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


# Size of source trees, after being built on an x86_64 machine, without
# documentation:
# p4c - 1.3G
# behavioral-model - 2.0G


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

echo "This script builds and installs the P4-16 (and also P4-14)"
echo "compiler, and the behavioral-model software packet forwarding"
echo "program, that can behave as just about any legal P4 program."
echo ""
echo "It has been tested on a freshly installed Ubuntu 16.04 system,"
echo "with all Ubuntu software updates as of 2018-Oct-17, and a"
echo "similarly updated Ubuntu 18.04 system."
echo ""
echo "The files installed by this script consume about 5 GB of disk space."
echo ""
echo "On a 2015 MacBook Pro with a decent speed Internet connection and an"
echo "SSD drive, it took about 40 minutes."
echo ""
echo "You will likely need to enter your password for multiple uses of"
echo "'sudo' spread throughout this script."


echo "------------------------------------------------------------"
echo "Time and disk space used before installation begins:"
date
df -h .
df -BM .

# Install a few packages (vim is not strictly necessary -- installed for
# my own convenience):
sudo apt-get --yes install git vim


# Install Ubuntu packages needed by protobuf v3.2.0, from its src/README.md
sudo apt-get --yes install autoconf automake libtool curl make g++ unzip
# Install Ubuntu dependencies needed by p4c, from its README.md
# Matches latest p4c README.md instructions as of 2018-Aug-13
sudo apt-get --yes install g++ git automake libtool libgc-dev bison flex libfl-dev libgmp-dev libboost-dev libboost-iostreams-dev libboost-graph-dev pkg-config python python-scapy python-ipaddr python-ply tcpdump cmake



echo "------------------------------------------------------------"
echo "Installing p4lang/behavioral-model"
echo "start install behavioral-model:"
date

cd "${INSTALL_DIR}"
# Clone Github repo
git clone https://github.com/p4lang/behavioral-model.git

cd behavioral-model

# Replace all occurrences of version 0.9.2 with 0.11.0 in Thrift
# install script.
sed s/0.9.2/0.11.0/g travis/install-thrift.sh > travis/install-thrift-0.11.0.sh
/bin/cp travis/install-thrift-0.11.0.sh travis/install-thrift.sh

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
df -BM .

P4GUIDE_BIN="${THIS_SCRIPT_DIR_ABSOLUTE}"

cd "${INSTALL_DIR}"
echo "P4_INSTALL=\"${INSTALL_DIR}\"" > p4setup.bash
echo "P4C=\"\$P4_INSTALL/p4c\"" >> p4setup.bash
echo "BMV2=\"\$P4_INSTALL/behavioral-model\"" >> p4setup.bash
echo "P4GUIDE_BIN=\"${P4GUIDE_BIN}\"" >> p4setup.bash
echo "export PATH=\"\$P4GUIDE_BIN:\$P4C/build:\$BMV2/tools:/usr/local/bin:\$PATH\"" >> p4setup.bash

echo "set P4_INSTALL=\"${INSTALL_DIR}\"" > p4setup.csh
echo "set P4C=\"\$P4_INSTALL/p4c\"" >> p4setup.csh
echo "set BMV2=\"\$P4_INSTALL/behavioral-model\"" >> p4setup.csh
echo "set P4GUIDE_BIN=\"${P4GUIDE_BIN}\"" >> p4setup.csh
echo "set path = ( \$P4GUIDE_BIN \$P4C/build \$BMV2/tools /usr/local/bin \$path )" >> p4setup.csh

echo ""
echo "Created files: p4setup.bash p4setup.csh"
echo ""
echo "If you use a Bash-like command shell, you may wish to copy the lines"
echo "of the file p4setup.bash to your .bashrc or .profile files in your"
echo "home directory to add commands like p4c and simple_switch_grpc to your"
echo "command path every time you log in or create a new shell."
echo ""
echo "If you use the tcsh or csh shells, instead copy the contents of the"
echo "file p4setup.csh to your .tcshrc or .cshrc file in your home"
echo "directory."
