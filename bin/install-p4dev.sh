#! /bin/bash

# Install the P4-16 (and also P4-14) compiler, and the behavioral-model
# software packet forwarding program, that can behave as just about
# any legal P4 program.

# You will likely need to enter your password for multiple uses of 'sudo'
# spread throughout this script.

# The files installed by this script consume about 3.5 Gbytes of disk
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
MAX_PARALLEL_JOBS=3

# Remember the current directory when the script was started:
INSTALL_DIR="${PWD}"


# Install a few packages (vim is not strictly necessary -- installed for
# my own convenience):
sudo apt-get --yes install git vim
# Install Ubuntu packages needed by protobuf, from its src/README.md
sudo apt-get --yes install autoconf automake libtool curl make g++ unzip
# Install Ubuntu dependencies needed by p4c, from its README.md
sudo apt-get --yes install g++ git automake libtool libgc-dev bison flex libfl-dev libgmp-dev libboost-dev libboost-iostreams-dev pkg-config python python-scapy python-ipaddr tcpdump

echo "------------------------------------------------------------"
echo "Installing Google protobuf, needed for p4lang/p4c"
echo "start install protobuf:"
date

cd "${INSTALL_DIR}"
git clone https://github.com/google/protobuf
cd protobuf
git checkout v3.0.2
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
./bootstrap.sh
cd build
make -j${MAX_PARALLEL_JOBS}

echo "end install p4c:"
date



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
