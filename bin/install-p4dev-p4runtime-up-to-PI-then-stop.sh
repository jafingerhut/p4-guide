#! /bin/bash

# Remember the current directory when the script was started:
INSTALL_DIR="${PWD}"

# Install a few packages:
sudo apt-get --yes install git

# Install Python2.  This is required for p4c, but there are several
# earlier packages that check for python in their configure scripts,
# and on a minimal Ubuntu 18.04 Desktop Linux system they find
# Python3, not Python2, unless we install Python2.  Most Python code
# in open source P4 projects is written for Python2.
sudo apt-get --yes install python

# Install Ubuntu packages needed by protobuf v3.6.1, from its src/README.md
sudo apt-get --yes install autoconf automake libtool curl make g++ unzip
# zlib is not required to install protobuf, nor do I think it is
# required by the open source P4 tools for protobuf to be built with
# support for zlib, but it seems like a reasonable thing to enable.
sudo apt-get --yes install zlib1g-dev

# Install pkg-config here, as it is required for p4lang/PI
# installation to succeed.
sudo apt-get --yes install pkg-config

# It appears that some part of the build process for Thrift 0.12.0
# requires that pip3 has been installed first.  Without this, there is
# an error during building Thrift 0.12.0 where a Python 3 program
# cannot import from the setuptools package.
#
# Also in earlier versions of this script on Ubuntu 16.04 and 18.04,
# the pip package was being installed as a dependency of some other
# package somewhere, but this appears not to be the case on Ubuntu
# 19.10, so install it explicitly here.
sudo apt-get --yes install python3-pip python-pip

cd "${INSTALL_DIR}"
find /usr/lib /usr/local $HOME/.local | sort > usr-local-1-before-protobuf.txt

echo "------------------------------------------------------------"
echo "Installing Google protobuf, needed for p4lang/p4c and for p4lang/behavioral-model simple_switch_grpc"
echo "start install protobuf:"

cd "${INSTALL_DIR}"
git clone https://github.com/google/protobuf
cd protobuf
git checkout v3.6.1
./autogen.sh
./configure
make
sudo make install
sudo ldconfig

echo "end install protobuf:"

cd "${INSTALL_DIR}"
find /usr/lib /usr/local $HOME/.local | sort > usr-local-2-after-protobuf.txt

echo "------------------------------------------------------------"
echo "Installing grpc, needed for installing p4lang/PI"
echo "start install grpc:"

# From BUILDING.md of grpc source repository
sudo apt-get --yes install build-essential autoconf libtool pkg-config

git clone https://github.com/google/grpc.git
cd grpc
# This version works fine with Ubuntu 16.04
git checkout tags/v1.17.2
git submodule update --init --recursive
make
sudo make install
sudo ldconfig

echo "end install grpc:"

cd "${INSTALL_DIR}"
find /usr/lib /usr/local $HOME/.local | sort > usr-local-3-after-grpc.txt

echo "------------------------------------------------------------"
echo "Installing p4lang/PI, needed for installing p4lang/behavioral-model simple_switch_grpc"
echo "start install PI:"

# Deps needed to build PI:
sudo apt-get --yes install libjudy-dev libreadline-dev valgrind libtool-bin libboost-dev libboost-system-dev libboost-thread-dev

git clone https://github.com/p4lang/PI
cd PI
git submodule update --init --recursive
git log -n 1
./autogen.sh
./configure --with-proto --without-internal-rpc --without-cli --without-bmv2
# Output I saw:
#Features recap ......................................
#Use sysrepo gNMI implementation .............. : no
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

echo "end install PI:"

cd "${INSTALL_DIR}"
find /usr/lib /usr/local $HOME/.local | sort > usr-local-4-after-PI.txt
