#! /bin/bash

# Adapted from the file:

# https://github.com/ipdk-io/ipdk/blob/main/build/IPDK_Container/Dockerfile

# which is specific to Fedora, or at least any Linux distribution that
# uses 'dnf' for package management.

# Install packages needed to build later packages from source code

THIS_SCRIPT_FILE_MAYBE_RELATIVE="$0"
THIS_SCRIPT_DIR_MAYBE_RELATIVE="${THIS_SCRIPT_FILE_MAYBE_RELATIVE%/*}"
THIS_SCRIPT_DIR_ABSOLUTE=`readlink -f "${THIS_SCRIPT_DIR_MAYBE_RELATIVE}"`

source "${THIS_SCRIPT_DIR_ABSOLUTE}/script_utils.bash"

PATCH_DIR1="${THIS_SCRIPT_DIR_ABSOLUTE}/patches"

check_patch_dirs_exist "${PATCH_DIR1}"

set -ex

sudo dnf -y update

# Run a child process in the background that will keep sudo
# credentials fresh.  The hope is that after a user enters their
# password once, they will not need to do so again for the entire
# duration of running this install script.

# However, since it runs in the background, do _not_ start it until
# after the first command in this script that uses 'sudo', so the
# foreground 'sudo' command will cause the password prompt to be
# waited for, if it is needed.
"${THIS_SCRIPT_DIR_ABSOLUTE}/keep-sudo-credentials-fresh.sh" &
CHILD_PROCESS_PID=$!

# Kill the child process on early exit
trap "clean_up ${CHILD_PROCESS_PID}" SIGHUP SIGINT SIGTERM

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

clean_up ${CHILD_PROCESS_PID}
