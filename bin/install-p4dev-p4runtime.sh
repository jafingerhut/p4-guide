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


# This script differs from install-p4dev.sh as follows:

# install-p4dev.sh executes steps to build the behavioral-model
# simple_switch program, using only Thrift as the IPC mechanism for
# other processes to connect to it and make table add/modify/delete
# requests.

# install-p4dev-p4runtime.sh executes steps to build the
# behavioral-model simple_switch_grpc program, which uses the
# P4Runtime API as the IPC mechanism for other processes to connect to
# it and make table add/modify/delete requests.  It is built with the
# necessary options so that the simple_switch_grpc process _also_
# supports Thrift, but this is only intended as a debugging aid,
# e.g. to show table contents using the simple_switch_CLI program.

# Size of the largest 3 source trees, after being built on an x86_64
# machine, without documentation:
# grpc - 0.7G
# p4c - 1.4G
# behavioral-model - 2.5G

# The maximum number of gcc/g++ jobs to run in parallel.  1 is the
# safest number that enables compiling p4c even on machines with only
# 2 GB of RAM, and even on machines with significantly more RAM, it
# does not speed things up a lot to run multiple jobs in parallel.
MAX_PARALLEL_JOBS=1

# Remember the current directory when the script was started:
INSTALL_DIR="${PWD}"

# I believe that if this script is run as "sudo <scriptname>", then
# the environment variable SUDO_USER will always have a value, and it
# will be the string that is the name of the normal user that used
# that sudo command.  If this script is run as "<scriptname>", then
# the environment variable SUDO_USER will not be in the environment at
# all.

# If this script is run as "sudo <scriptname>", I want most commands
# to be executed as the user SUDO_USER, to avoid running most of these
# commands as the superuser, with privileges those commands do not
# need, and only run the few that require superuser privileges as
# root.

# After defining functions priv and unpriv below, I will use one of
# functions to execute all later commands in this script, with the
# following exceptions:

# cd commands, which modify the environment of the shell running the
# command, and have no useful effect when run inside of 'sudo'.

# setting environment variables and if/then/else/fi, for the same
# reason as cd.

# echo, just because that seems pretty safe to run that as root.  If
# we want to change that, I'd rather create a function with a name
# like 'ech' that runs unprivileged, rather than prefixing all of the
# many many uses of 'echo' with 'unpriv'.

if [ `id --user` == 0 ]
then
    STARTED_AS_ROOT=1
    if [ -z "$SUDO_USER" ]
    then
	echo "This script $0 was started as the superuser, but the"
	echo "environment variable SUDO_USER is empty or unset.  It is"
	echo "intended that you run this script as shown below, as a"
	echo "normal user.  This enables the majority of the commands"
	echo "in this script to run as a normal user, since most do"
	echo "not need superuser privileges."
	echo ""
	echo "    # As a normal user:"
	echo "    sudo $0"
	echo ""
        echo "If for some reason you truly wish to run every command"
	echo "in this script as a superuser, then you are free to edit"
	echo "this install script to do it."
	exit 1
    else
	UNPRIVILEGED_USER=$SUDO_USER
	echo "Most commands will be run as user '$UNPRIVILEGED_USER'"
    fi
else
    STARTED_AS_ROOT=0
    echo "All commands will be run as user '$USER', with sudo for commands"
    echo "needing superuser privileges, which may require you to entre your"
    echo "password."
fi
echo "----------------------------------------------------------------------"

unpriv() {
    if [ $STARTED_AS_ROOT == 1 ]
    then
	# Run the command as a normal user, not root.
	# TBD: Init code at beginning of this script sets up value for
	# UNPRIVILEGED_USER
	sudo -u $UNPRIVILEGED_USER $*
    else
	# We are not root now, so just run the command normally.
	$*
    fi
}

priv() {
    if [ $STARTED_AS_ROOT == 1 ]
    then
	# We are root now, so just run the command normally.
	$*
    else
	# Invoke the command using sudo to root.  This might require
	# prompting the user for their password.  So be it -- they
	# chose to start this script as a normal user, and thus we
	# won't make it any more convenient for them.
	sudo $*
    fi
}

THIS_SCRIPT_FILE_MAYBE_RELATIVE="$0"
THIS_SCRIPT_DIR_MAYBE_RELATIVE="${THIS_SCRIPT_FILE_MAYBE_RELATIVE%/*}"
THIS_SCRIPT_DIR_ABSOLUTE=`readlink -f "${THIS_SCRIPT_DIR_MAYBE_RELATIVE}"`

ubuntu_release=`unpriv lsb_release -s -r`

echo "This script builds and installs the P4_16 (and also P4_14)"
echo "compiler, and the behavioral-model software packet forwarding"
echo "program, that can behave as just about any legal P4 program."
echo ""
echo "It regularly tested on freshly installed Ubuntu 16.04 and Ubuntu"
echo "18.04 systems, with all Ubuntu software updates as of the date"
echo "of testing.  See this directory for log files recording the last"
echo "date this script was tested on its supported operating systems:"
echo ""
echo "    https://github.com/jafingerhut/p4-guide/tree/master/bin/output"
echo ""
echo "The files installed by this script consume about 8 GB of disk space."
echo ""
echo "On a 2015 MacBook Pro with a decent speed Internet connection"
echo "and an SSD drive, running Ubuntu Linux in a VirtualBox VM, it"
echo "took about 60 minutes."
echo ""
echo "You will likely need to enter your password for multiple uses of"
echo "'sudo' spread throughout this script."
echo ""
echo "Versions of software that will be installed by this script:"
echo ""
echo "+ protobuf: github.com/google/protobuf v3.2.0"
echo "+ gRPC: github.com/google/grpc.git v1.3.2, with patches for Ubuntu 18.04"
echo "+ PI: github.com/p4lang/PI latest version"
echo "+ behavioral-model: github.com/p4lang/behavioral-model latest version"
echo "  which, as of 2019-Jun-10, also installs these things:"
echo "  + thrift version 0.9.2"
echo "  + nanomsg version 1.0.0"
echo "  + nnpy git checkout c7e718a5173447c85182dc45f99e2abcf9cd4065 (latest as of 2015-Apr-22"
echo "+ p4c: github.com/p4lang/p4c latest version"
echo "+ Mininet: github.com/mininet/mininet latest version"
echo "+ Python packages: grpcio, protobuf, crcmod, latest versions"
echo ""
echo "Note that anything installed as 'the latest version' can change"
echo "its precise contents from one run of this script to another."
echo "That is an intentional property of this script -- to get the"
echo "latest version of that software.  If you want particular"
echo "versions that are not the latest, you can modify this script by"
echo "adding 'git checkout <tag>' and/or 'git checkout <commit-sha>'"
echo "command at the appropriate places."
echo ""

# TBD: Consider adding a check for how much free disk space there is
# and giving a message about it and aborting if it is too low.  On
# Ubuntu 16.04, at least, the command `df --output=avail .` shows how
# many Kbytes are free on the file system containing the directory ``,
# which could be interpreted in a bash script without having to parse
# so much output from a different command like `df -h .`


REPO_CACHE_DIR="${INSTALL_DIR}/repository-cache"
get_from_nearest() {
    local git_url="$1"
    local repo_cache_name="$2"

    if [ -e "${REPO_CACHE_DIR}/${repo_cache_name}" ]
    then
	echo "Creating contents of ${git_url} from local cached copy ${REPO_CACHE_DIR}/${repo_cache_name}"
	unpriv tar xkzf "${REPO_CACHE_DIR}/${repo_cache_name}"
    else
	echo "git clone ${git_url}"
	unpriv git clone "${git_url}"
    fi
}


echo "------------------------------------------------------------"
echo "Time and disk space used before installation begins:"
unpriv date
unpriv df -h .
unpriv df -BM .

# Install a few packages (vim is not strictly necessary -- installed for
# my own convenience):
priv apt-get --yes install git vim

# Install Python2.  This is required for p4c, but there are several
# earlier packages that check for python in their configure scripts,
# and on a minimal Ubuntu 18.04 Desktop Linux system they find
# Python3, not Python2, unless we install Python2.  Most Python code
# in open source P4 projects is written for Python2.
priv apt-get --yes install python

# Install Ubuntu packages needed by protobuf v3.2.0, from its src/README.md
priv apt-get --yes install autoconf automake libtool curl make g++ unzip
# zlib is not required to install protobuf, nor do I think it is
# required by the open source P4 tools for protobuf to be built with
# support for zlib, but it seems like a reasonable thing to enable.
priv apt-get --yes install zlib1g-dev

# Install pkg-config here, as it is required for p4lang/PI
# installation to succeed.
priv apt-get --yes install pkg-config

cd "${INSTALL_DIR}"
unpriv find /usr/lib /usr/local $HOME/.local | sort > usr-local-1-before-protobuf.txt

echo "------------------------------------------------------------"
echo "Installing Google protobuf, needed for p4lang/p4c and for p4lang/behavioral-model simple_switch_grpc"
echo "start install protobuf:"
unpriv date

cd "${INSTALL_DIR}"
get_from_nearest https://github.com/google/protobuf protobuf.tar.gz
cd protobuf
unpriv git checkout v3.2.0
unpriv ./autogen.sh
unpriv ./configure
unpriv make
priv make install
priv ldconfig
# Save about 0.5G of storage by cleaning up protobuf build
unpriv make clean

echo "end install protobuf:"
unpriv date

cd "${INSTALL_DIR}"
unpriv find /usr/lib /usr/local $HOME/.local | sort > usr-local-2-after-protobuf.txt

echo "------------------------------------------------------------"
echo "Installing grpc, needed for installing p4lang/PI"
echo "start install grpc:"
unpriv date

# From BUILDING.md of grpc source repository
priv apt-get --yes install build-essential autoconf libtool pkg-config

get_from_nearest https://github.com/google/grpc.git grpc.tar.gz
cd grpc
# This version works fine with Ubuntu 16.04
unpriv git checkout tags/v1.3.2
if [[ "${ubuntu_release}" > "18" ]]
then
    # Apply patches that seem to be necessary in order for grpc v1.3.2
    # to compile and install successfully on an Ubuntu 18.04 system
    PATCH_DIR="${THIS_SCRIPT_DIR_ABSOLUTE}/grpc-v1.3.2-patches-for-ubuntu18.04"

    # I have tried with the openssl-1.1.0.diff patch applied, in addition
    # to the others, but it leads to errors when building grpc on an Ubuntu
    # 18.04.1 system, because of not being able to find the definition of
    # a function RSA_set0_key.  Leave that patch out for now, since things
    # seem to build better without it.
    #for PATCH_FILE in openssl-1.1.0.diff no-werror.diff unvendor-zlib.diff fix-libgrpc++-soname.diff make-pkg-config-files-nonexecutable.diff add-wrap-memcpy-flags.diff

    for PATCH_FILE in no-werror.diff unvendor-zlib.diff fix-libgrpc++-soname.diff make-pkg-config-files-nonexecutable.diff add-wrap-memcpy-flags.diff
    do
        unpriv patch -p1 < "${PATCH_DIR}/${PATCH_FILE}"
    done
fi
unpriv git submodule update --init --recursive
unpriv make
priv make install
priv ldconfig
# Save about 0.1G of storage by cleaning up grpc v1.3.2 build
unpriv make clean

echo "end install grpc:"
unpriv date

cd "${INSTALL_DIR}"
unpriv find /usr/lib /usr/local $HOME/.local | sort > usr-local-3-after-grpc.txt

echo "------------------------------------------------------------"
echo "Installing p4lang/PI, needed for installing p4lang/behavioral-model simple_switch_grpc"
echo "start install PI:"
unpriv date

# Deps needed to build PI:
priv apt-get --yes install libjudy-dev libreadline-dev valgrind libtool-bin libboost-dev libboost-system-dev libboost-thread-dev

unpriv git clone https://github.com/p4lang/PI
cd PI
unpriv git submodule update --init --recursive
unpriv git log -n 1
unpriv ./autogen.sh
unpriv ./configure --with-proto --without-internal-rpc --without-cli --without-bmv2
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
unpriv make
priv make install

# Save about 0.25G of storage by cleaning up PI build
unpriv make clean

echo "end install PI:"
unpriv date

cd "${INSTALL_DIR}"
unpriv find /usr/lib /usr/local $HOME/.local | sort > usr-local-4-after-PI.txt

echo "------------------------------------------------------------"
echo "Installing p4lang/behavioral-model"
echo "start install behavioral-model:"
unpriv date

# Following instructions in the file
# targets/simple_switch_grpc/README.md in the p4lang/behavioral-model
# repository with git commit 66cefc5e901eafcebb0e1a8f681a05795463215a.
# That README.md file was last updated 2018-Apr-03.

# It says to first follow the instructions here:
# https://github.com/p4lang/PI#dependencies to install required
# dependencies for the `--with-proto` configure flag.  This script
# does _not_ use the option `--with-sysrepo` configure flag, which is
# needed for experimental gNMI support.  That should all have been
# done by this time, by the script above.

get_from_nearest https://github.com/p4lang/behavioral-model.git behavioral-model.tar.gz
cd behavioral-model
# Get latest updates that are not in the repo cache version
unpriv git pull
unpriv git log -n 1
# This command installs Thrift, which I want to include in my build of
# simple_switch_grpc
unpriv ./install_deps.sh
# simple_switch_grpc README.md says to configure and build the bmv2
# code first, using these commands:
unpriv ./autogen.sh
# Remove 'CXXFLAGS ...' part to disable debug
unpriv ./configure --with-pi 'CXXFLAGS=-O0 -g'
unpriv make
priv make install
# Now build simple_switch_grpc
cd targets/simple_switch_grpc
unpriv ./autogen.sh
# Remove 'CXXFLAGS ...' part to disable debug
unpriv ./configure --with-thrift 'CXXFLAGS=-O0 -g'
# I saw the following near end of output of 'configure' command:
#Features recap ......................
#With Sysrepo .................. : no
#With Thrift ................... : yes
unpriv make
priv make install
priv ldconfig

echo "end install behavioral-model:"
unpriv date

cd "${INSTALL_DIR}"
unpriv find /usr/lib /usr/local $HOME/.local | sort > usr-local-5-after-behavioral-model.txt

echo "------------------------------------------------------------"
echo "Installing p4lang/p4c"
echo "start install p4c:"
unpriv date

# Install Ubuntu dependencies needed by p4c, from its README.md
# Matches latest p4c README.md instructions as of 2019-Oct-09
priv apt-get --yes install cmake g++ git automake libtool libgc-dev bison flex libfl-dev libgmp-dev libboost-dev libboost-iostreams-dev libboost-graph-dev llvm pkg-config python python-scapy python-ipaddr python-ply tcpdump

# Clone p4c and its submodules:
unpriv git clone --recursive https://github.com/p4lang/p4c.git
cd p4c
unpriv git log -n 1
unpriv mkdir build
cd build
# Configure for a debug build
unpriv cmake .. -DCMAKE_BUILD_TYPE=DEBUG $*
unpriv make -j${MAX_PARALLEL_JOBS}
priv make install
priv ldconfig

echo "end install p4c:"
unpriv date

cd "${INSTALL_DIR}"
unpriv find /usr/lib /usr/local $HOME/.local | sort > usr-local-6-after-p4c.txt

echo "------------------------------------------------------------"

echo "Installing Mininet - not necessary to run P4 programs, but useful if"
echo "you want to run tutorials from https://github.com/p4lang/tutorials"
echo "repository."
echo "start install mininet:"
unpriv date

unpriv git clone git://github.com/mininet/mininet mininet
priv ./mininet/util/install.sh -nwv

echo "end install mininet:"
unpriv date

cd "${INSTALL_DIR}"
unpriv find /usr/lib /usr/local $HOME/.local | sort > usr-local-7-after-mininet-install.txt

echo "------------------------------------------------------------"
echo "Installing a few miscellaneous packages"
echo "start install miscellaneous packages:"
unpriv date

# On 2019-Oct-09 on an Ubuntu 16.04 or 18.04 machine, this installed
# grpcio 1.24.1
priv pip install grpcio
# On 2019-Oct-09 on an Ubuntu 16.04 or 18.04 machine, this installed
# protobuf 3.10.0
priv pip install protobuf
# Things needed for `cd tutorials/exercises/basic ; make run` to work:
priv apt-get --yes install python-psutil libgflags-dev net-tools
priv pip install crcmod

echo "end install miscellaneous packages:"
unpriv date

cd "${INSTALL_DIR}"
unpriv find /usr/lib /usr/local $HOME/.local | sort > usr-local-8-after-miscellaneous-install.txt

echo "------------------------------------------------------------"
echo "Time and disk space used when installation was complete:"
unpriv date
unpriv df -h .
unpriv df -BM .

cd "${INSTALL_DIR}"
DETS="install-details"
unpriv mkdir -p "${DETS}"
unpriv mv usr-local-*.txt "${DETS}"
cd "${DETS}"
unpriv diff usr-local-1-before-protobuf.txt usr-local-2-after-protobuf.txt > usr-local-file-changes-protobuf.txt
unpriv diff usr-local-2-after-protobuf.txt usr-local-3-after-grpc.txt > usr-local-file-changes-grpc.txt
unpriv diff usr-local-3-after-grpc.txt usr-local-4-after-PI.txt > usr-local-file-changes-PI.txt
unpriv diff usr-local-4-after-PI.txt usr-local-5-after-behavioral-model.txt > usr-local-file-changes-behavioral-model.txt
unpriv diff usr-local-5-after-behavioral-model.txt usr-local-6-after-p4c.txt > usr-local-file-changes-p4c.txt
unpriv diff usr-local-6-after-p4c.txt usr-local-7-after-mininet-install.txt > usr-local-file-changes-mininet-install.txt
unpriv diff usr-local-7-after-mininet-install.txt usr-local-8-after-miscellaneous-install.txt > usr-local-file-changes-miscellaneous-install.txt

P4GUIDE_BIN="${THIS_SCRIPT_DIR_ABSOLUTE}"

echo "----------------------------------------------------------------------"
echo "CONSIDER READING WHAT IS BELOW"
echo "----------------------------------------------------------------------"
echo ""

cd "${INSTALL_DIR}"
echo "P4_INSTALL=\"${INSTALL_DIR}\"" > p4setup.bash
echo "BMV2=\"\$P4_INSTALL/behavioral-model\"" >> p4setup.bash
echo "P4GUIDE_BIN=\"${P4GUIDE_BIN}\"" >> p4setup.bash
echo "export PATH=\"\$P4GUIDE_BIN:\$BMV2/tools:/usr/local/bin:\$PATH\"" >> p4setup.bash

echo "set P4_INSTALL=\"${INSTALL_DIR}\"" > p4setup.csh
echo "set BMV2=\"\$P4_INSTALL/behavioral-model\"" >> p4setup.csh
echo "set P4GUIDE_BIN=\"${P4GUIDE_BIN}\"" >> p4setup.csh
echo "set path = ( \$P4GUIDE_BIN \$BMV2/tools /usr/local/bin \$path )" >> p4setup.csh

echo ""
echo "Created files: p4setup.bash p4setup.csh"
echo ""
echo "If you use a Bash-like command shell, you may wish to copy the lines"
echo "of the file p4setup.bash to your .bashrc or .profile files in your"
echo "home directory to add some useful commands to your"
echo "command path every time you log in or create a new shell."
echo ""
echo "If you use the tcsh or csh shells, instead copy the contents of the"
echo "file p4setup.csh to your .tcshrc or .cshrc file in your home"
echo "directory."

echo "----------------------------------------------------------------------"
echo "CONSIDER READING WHAT IS ABOVE"
echo "----------------------------------------------------------------------"
