#! /bin/bash

# Adapted from the file:

# https://github.com/ipdk-io/ipdk/blob/main/build/IPDK_Container/Dockerfile

# which is specific to Fedora, or at least any Linux distribution that
# uses 'dnf' for package management.

# Install packages needed to build later packages from source code

sudo dnf -y update
sudo dnf -y groupinstall "Development Tools" "Development Libraries"
sudo dnf -y install meson cmake gdb libtool autoconf autoconf-archive automake iproute net-tools gflags-devel iputils cctz json-devel python grpc-plugins python3-cffi libedit-devel expat-devel pip flex bison libgc-devel vim
# Skip installing scapy for now, since it seems to also install TeXlive,
# which is huge and hopefully unnecessary to install.
#dnf -y install scapy
dnf -y clean all

# Installing all PYTHON packages

# Note: On Fedora 34, pip and pip3 are the same command, so unless its
# behavior depends upon the name with which it is run, it should have
# the same effect.  There are some commands whose behavior does depend
# upon the name that they were started with, though, and I have not
# confirmed whether its behavior is identical or different, so for now
# use the same tht athe Dockerfile used.
python -m pip install --upgrade pip
python -m pip install grpcio ovspy protobuf p4runtime
pip3 install pyelftools
