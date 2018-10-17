#! /bin/bash

# Copyright 2018-present Cisco Systems, Inc.

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

# This script differs from install-p4dev.sh as follows:

# install-p4dev.sh has build steps to build the behavioral-model
# simple_switch program, which uses only Thrift as the IPC mechanism
# for other processes to connect to it and make table
# add/modify/delete requests.

# install-p4dev-p4runtime.sh has build steps to build the
# behavioral-model simple_switch_grpc program, which uses the
# P4Runtime API as the IPC mechanism for other processes to connect to
# it and make table add/modify/delete requests.  It is built with the
# necessary options so that the simple_switch_grpc process _also_
# supports Thrift, but this is only intended as a debugging aid,
# e.g. to show table contents using the simple_switch_CLI program.

# You will likely need to enter your password for multiple uses of 'sudo'
# spread throughout this script.

# The files installed by this script consume about 7 GB of disk
# space.

# On a 2015 MacBook Pro with a decent speed Internet connection and an
# SSD drive, it took 48 mins.

# Size of the largest 3 source trees, after being built on an x86_64
# machine, without documentation:
# grpc - 0.7G
# p4c - 1.4G
# behavioral-model - 2.5G

# This script has been tested on a freshly installed Ubuntu 16.04
# system, from a file with this name: ubuntu-16.04.5-desktop-amd64.iso

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

ubuntu_release=`lsb_release -s -r`

echo "------------------------------------------------------------"
echo "Time and disk space used before installation begins:"
date
df -h .

# Install a few packages (vim is not strictly necessary -- installed for
# my own convenience):
sudo apt --yes install git vim


# Install Ubuntu packages needed by protobuf v3.2.0, from its src/README.md
sudo apt --yes install autoconf automake libtool curl make g++ unzip

echo "------------------------------------------------------------"
echo "Installing Google protobuf, needed for p4lang/p4c and for p4lang/behavioral-model simple_switch_grpc"
echo "start install protobuf:"
date

cd "${INSTALL_DIR}"
git clone https://github.com/google/protobuf
cd protobuf
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
echo "Installing grpc, needed for installing p4lang/PI"
echo "start install grpc:"
date

cd "${INSTALL_DIR}"
git clone https://github.com/google/grpc.git
cd grpc
if [[ "${ubuntu_release}" > "18" ]]
then
    # Versions older than this one fail due to warnings with Ubuntu
    # 18.04's newer version of GCC, which the grpc makefile options
    # for GCC turn into errors.
    git checkout tags/v1.11.0
else
    # This version works fine with Ubuntu 16.04
    git checkout tags/v1.3.2
fi
git submodule update --init --recursive
make
sudo make install
sudo ldconfig
# Save about 0.5G of storage by cleaning up grpc v1.7.0 build
make clean

echo "end install grpc:"
date


# Dependencies recommended to install libyang, from proto/README.md in
# p4lang/PI repo:
sudo apt --yes install build-essential cmake libpcre3-dev libavl-dev libev-dev libprotobuf-c-dev protobuf-c-compiler

echo "------------------------------------------------------------"
echo "Installing libyang, needed for installing p4lang/PI"
echo "start install libyang:"
date

cd "${INSTALL_DIR}"
git clone https://github.com/CESNET/libyang.git
cd libyang
git checkout v0.16-r1
mkdir build
cd build
cmake ..
make
sudo make install
# This step might not be necessary, but if not, it should be harmless and quick
sudo ldconfig

echo "end install libyang:"
date


echo "------------------------------------------------------------"
echo "Installing sysrepo, needed for installing p4lang/PI"
echo "start install sysrepo:"
date

cd "${INSTALL_DIR}"
git clone https://github.com/sysrepo/sysrepo.git
cd sysrepo
git checkout v0.7.5
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_EXAMPLES=Off -DCALL_TARGET_BINS_DIRECTLY=Off ..
make
sudo make install
# This step might not be necessary, but if not, it should be harmless and quick
sudo ldconfig

echo "end install sysrepo:"
date


echo "------------------------------------------------------------"
echo "Installing p4lang/PI, needed for installing p4lang/behavioral-model simple_switch_grpc"
echo "start install PI:"
date

# Deps needed to build PI:
sudo apt --yes install libjudy-dev libreadline-dev valgrind libtool-bin libboost-dev libboost-system-dev libboost-thread-dev

cd "${INSTALL_DIR}"
git clone https://github.com/p4lang/PI
cd PI
git submodule update --init --recursive
./autogen.sh
./configure --with-proto --without-internal-rpc --without-cli --without-bmv2 --with-sysrepo
# Output I saw:
#Features recap ......................................
#Use sysrepo gNMI implementation .............. : yes
#Compile demo_grpc ............................ : no
#
#Features recap ......................................
#Compile for bmv2 ............................. : no
#Compile C++ frontend ......................... : yes
#Compile p4runtime.proto and associated fe .... : yes
#Compile internal RPC ......................... : no
#Compile PI C CLI ............................. : no
make
sudo make install

# Save about 0.25G of storage by cleaning up PI build
make clean

echo "end install PI:"
date


echo "------------------------------------------------------------"
echo "Installing p4lang/behavioral-model"
echo "start install behavioral-model:"
date

# Following instructions in the file
# targets/simple_switch_grpc/README.md in the p4lang/behavioral-model
# repository with git commit 66cefc5e901eafcebb0e1a8f681a05795463215a.
# That README.md file was last updated 2018-Apr-03.

# It says to first follow the instructions here:
# https://github.com/p4lang/PI#dependencies to install required
# dependencies for the `--with-proto` configure flag, and optionally
# also the `--with-sysrepo` configure flag, which this script will do.
# That should all have been done by this time, by the script above.

cd "${INSTALL_DIR}"
git clone https://github.com/p4lang/behavioral-model.git
cd behavioral-model
# This command installs Thrift, which I want to include in my build of
# simple_switch_grpc
./install_deps.sh
# simple_switch_grpc README.md says to configure and build the bmv2
# code first, using these commands:
./autogen.sh
# Remove 'CXXFLAGS ...' part to disable debug
./configure --with-pi 'CXXFLAGS=-O0 -g'
make
sudo make install
# Now build simple_switch_grpc
cd targets/simple_switch_grpc
./autogen.sh
# Remove 'CXXFLAGS ...' part to disable debug
./configure --with-sysrepo --with-thrift 'CXXFLAGS=-O0 -g'
# I saw the following near end of output of 'configure' command:
#Features recap ......................
#With Sysrepo .................. : yes
#With Thrift ................... : yes
make
sudo make install

echo "end install behavioral-model:"
date


echo "------------------------------------------------------------"
echo "Installing p4lang/p4c"
echo "start install p4c:"
date

# Install Ubuntu dependencies needed by p4c, from its README.md
# Matches latest p4c README.md instructions as of 2018-Aug-13
sudo apt --yes install g++ git automake libtool libgc-dev bison flex libfl-dev libgmp-dev libboost-dev libboost-iostreams-dev libboost-graph-dev pkg-config python python-scapy python-ipaddr python-ply tcpdump cmake

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
echo "Installing a few Python packages"
echo "start install python packages:"
date

# On 2018-Oct-15 on an Ubuntu 16.04 machine, this installed grpcio
# 1.15.0
pip install grpcio
# On 2018-Oct-15 on an Ubuntu 16.04 machine, this installed protobuf
# 3.6.1
pip install protobuf

echo "end install python packages:"
date

echo "------------------------------------------------------------"
echo "Time and disk space used when installation was complete:"
date
df -h .

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
