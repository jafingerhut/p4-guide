#! /bin/bash

# Copyright 2020-present Intel Corporation

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


# This script differs from install-p4dev-v3.sh as follows:

# This script attepts to complete successfully on an Ubuntu 20.04
# system that does not have Python2 installed on it when it starts,
# and tries never to install Python2, pip2, nor any Python2 packages
# or libraries.

# As of 2020-Dec, the open source P4 tools seem to be ready for this.

# In fact, this script does end up installing Python2, but only
# because installing Mininet as this script currently does, causes
# Python2 to be installed.  Before that point (near the end), Python2
# is never installed.

# Remember the current directory when the script was started:
INSTALL_DIR="${PWD}"

THIS_SCRIPT_FILE_MAYBE_RELATIVE="$0"
THIS_SCRIPT_DIR_MAYBE_RELATIVE="${THIS_SCRIPT_FILE_MAYBE_RELATIVE%/*}"
THIS_SCRIPT_DIR_ABSOLUTE=`readlink -f "${THIS_SCRIPT_DIR_MAYBE_RELATIVE}"`

ubuntu_version_warning() {
    1>&2 echo "This software has only been tested on Ubuntu 18.04 and"
    1>&2 echo "20.04, and is known to fail in a few tests on Ubuntu"
    1>&2 echo "16.04."
    1>&2 echo ""
    1>&2 echo "Proceed installing manually at your own risk of"
    1>&2 echo "significant time spent figuring out how to make it all"
    1>&2 echo "work, or consider getting VirtualBox and creating an"
    1>&2 echo "Ubuntu virtual machine with one of the tested versions."
}

abort_script=0

lsb_release >& /dev/null
if [ $? != 0 ]
then
    1>&2 echo "No 'lsb_release' found in your command path."
    ubuntu_version_warning
    exit 1
fi

distributor_id=`lsb_release -si`
ubuntu_release=`lsb_release -s -r`
if [ "${distributor_id}" = "Ubuntu" -a \( "${ubuntu_release}" = "18.04" -o "${ubuntu_release}" = "20.04" \) ]
then
    echo "Found distributor '${distributor_id}' release '${ubuntu_release}'.  Continuing with installation."
else
    ubuntu_version_warning
    1>&2 echo ""
    1>&2 echo "Here is what command 'lsb_release -a' shows this OS to be:"
    lsb_release -a
    exit 1
fi

# Minimum required system memory is 2 GBytes, minus a few MBytes
# because from experiments I have run on several different Ubuntu
# Linux VMs, when you configure them with 2 Gbytes of RAM, the first
# line of /proc/meminfo shows a little less than that available, I
# believe because some memory occupied by the kernel is not shown.

min_mem_MBytes=`expr 2 \* \( 1024 - 64 \)`
memtotal_KBytes=`head -n 1 /proc/meminfo | awk '{print $2;}'`
memtotal_MBytes=`expr ${memtotal_KBytes} / 1024`

if [ "${memtotal_MBytes}" -lt "${min_mem_MBytes}" ]
then
    memtotal_comment="too low"
    abort_script=1
else
    memtotal_comment="enough"
fi

echo "Minimum recommended memory to run this script: ${min_mem_MBytes} MBytes"
echo "Memory on this system from /proc/meminfo:      ${memtotal_MBytes} MBytes -> $memtotal_comment"

min_free_disk_MBytes=`expr 12 \* 1024`
free_disk_MBytes=`df --output=avail --block-size=1M . | tail -n 1`

if [ "${free_disk_MBytes}" -lt "${min_free_disk_MBytes}" ]
then
    free_disk_comment="too low"
    abort_script=1
else
    free_disk_comment="enough"
fi

echo "Minimum free disk space to run this script:    ${min_free_disk_MBytes} MBytes"
echo "Free disk space on this system from df output: ${free_disk_MBytes} MBytes -> $free_disk_comment"

if [ "${abort_script}" == 1 ]
then
    echo ""
    echo "Aborting script because system has too little RAM or free disk space"
    exit 1
fi

PATCH_DIR1="${THIS_SCRIPT_DIR_ABSOLUTE}/grpc-v1.17.2-patches-for-ubuntu19.10"
PATCH_DIR2="${THIS_SCRIPT_DIR_ABSOLUTE}/patches"

for dir in "${PATCH_DIR1}" "${PATCH_DIR2}"
do
    if [ -d "${dir}" ]
    then
	echo "Found directory containing patches: ${dir}"
    else
	echo "NO directory containing patches: ${dir}"
	abort_script=1
    fi
done

if [ "${abort_script}" == 1 ]
then
    echo ""
    echo "Aborting script because an expected directory does not exist (see above)."
    echo ""
    echo "This script is not designed to work if you only copy the"
    echo "script file to a system.  You should run it in the context"
    echo "of a cloned copy of the repository: https://github/jafingerhut/p4-guide"
    exit 1
fi

echo "Passed all sanity checks"

set -e
set -x

# The maximum number of gcc/g++ jobs to run in parallel.  1 is the
# safest number that enables compiling p4c even on machines with only
# 2 GB of RAM, and even on machines with significantly more RAM, it
# does not speed things up a lot to run multiple jobs in parallel.
MAX_PARALLEL_JOBS=1

set +x
echo "This script builds and installs the P4_16 (and also P4_14)"
echo "compiler, and the behavioral-model software packet forwarding"
echo "program, that can behave as just about any legal P4 program."
echo ""
echo "It is regularly tested on freshly installed Ubuntu 18.04 and"
echo "20.04 system, with all Ubuntu software updates as of the date of"
echo "testing.  See this directory for log files recording the last"
echo "date this script was tested on its supported operating systems:"
echo ""
echo "    https://github.com/jafingerhut/p4-guide/tree/master/bin/output"
echo ""
echo "The files installed by this script consume about 12 GB of disk space."
echo ""
echo "On a 2015 MacBook Pro with a decent speed Internet connection"
echo "and an SSD drive, running Ubuntu Linux in a VirtualBox VM, it"
echo "took about 90 to 110 minutes."
echo ""
echo "Versions of software that will be installed by this script:"
echo ""
echo "+ protobuf: github.com/google/protobuf v3.6.1"
echo "+ gRPC: github.com/google/grpc.git v1.17.2, with patches for Ubuntu 20.04"
echo "+ PI: github.com/p4lang/PI latest version"
echo "+ behavioral-model: github.com/p4lang/behavioral-model latest version"
echo "  which, as of 2021-Jun-28, also installs these things:"
echo "  + thrift version 0.11.0"
echo "  + nanomsg version 1.0.0"
echo "  + nnpy git checkout c7e718a5173447c85182dc45f99e2abcf9cd4065 (latest as of 2015-Apr-22"
echo "+ p4c: github.com/p4lang/p4c latest version"
echo "+ ptf: github.com/p4lang/ptf latest version"
echo "+ Mininet: github.com/mininet/mininet latest version"
echo "+ Python packages: grpcio 1.17.1, protobuf 3.6.1"
echo "+ Python packages: scapy, ipaddr, psutil, crcmod, pypcap"
echo ""
echo "Note that anything installed as 'the latest version' can change"
echo "its precise contents from one run of this script to another."
echo "That is an intentional property of this script -- to get the"
echo "latest version of that software.  If you want particular"
echo "versions that are not the latest, you can modify this script by"
echo "adding 'git checkout <tag>' and/or 'git checkout <commit-sha>'"
echo "command at the appropriate places."
echo ""
set -x

# TBD: Consider adding a check for how much free disk space there is
# and giving a message about it and aborting if it is too low.  On
# Ubuntu 16.04, at least, the command `df --output=avail .` shows how
# many Kbytes are free on the file system containing the directory
# `.`, which could be interpreted in a bash script without having to
# parse so much output from a different command like `df -h .`


set +x
REPO_CACHE_DIR="${INSTALL_DIR}/repository-cache"
get_from_nearest() {
    local git_url="$1"
    local repo_cache_name="$2"

    if [ -e "${REPO_CACHE_DIR}/${repo_cache_name}" ]
    then
	echo "Creating contents of ${git_url} from local cached copy ${REPO_CACHE_DIR}/${repo_cache_name}"
	tar xkzf "${REPO_CACHE_DIR}/${repo_cache_name}"
    else
	echo "git clone ${git_url}"
	git clone "${git_url}"
    fi
}


# The install steps for p4lang/PI and p4lang/behavioral-model end
# up installing Python module code in the site-packages directory
# mentioned below in this function.  That is were GNU autoconf's
# 'configure' script seems to find as the place to put them.

# On Ubuntu systems when you run the versions of Python that are
# installed via Debian/Ubuntu packages, they only look in a
# sibling dist-packages directory, never the site-packages one.

# If I could find a way to change the part of the install script
# so that p4lang/PI and p4lang/behavioral-model install their
# Python modules in the dist-packages directory, that sounds
# useful, but I have not found a way.

# As a workaround, after finishing the part of the install script
# for those packages, I will invoke this function to move them all
# into the dist-packages directory.

# Some articles with questions and answers related to this.
# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=765022
# https://bugs.launchpad.net/ubuntu/+source/automake/+bug/1250877
# https://unix.stackexchange.com/questions/351394/makefile-installing-python-module-out-of-of-pythonpath

PY3LOCALPATH=`${THIS_SCRIPT_DIR_ABSOLUTE}/py3localpath.py`

move_usr_local_lib_python3_from_site_packages_to_dist_packages() {
    local SRC_DIR
    local DST_DIR
    local j
    local k

    SRC_DIR="${PY3LOCALPATH}/site-packages"
    DST_DIR="${PY3LOCALPATH}/dist-packages"

    # When I tested this script on Ubunt 16.04, there was no
    # site-packages directory.  Return without doing anything else if
    # this is the case.
    if [ ! -d ${SRC_DIR} ]
    then
	return 0
    fi

    # Do not move any __pycache__ directory that might be present.
    sudo rm -fr ${SRC_DIR}/__pycache__

    echo "Source dir contents before moving: ${SRC_DIR}"
    ls -lrt ${SRC_DIR}
    echo "Dest dir contents before moving: ${DST_DIR}"
    ls -lrt ${DST_DIR}
    for j in ${SRC_DIR}/*
    do
	echo $j
	k=`basename $j`
	# At least sometimes (perhaps always?) there is a directory
	# 'p4' or 'google' in both the surce and dest directory.  I
	# think I want to merge their contents.  List them both so I
	# can see in the log what was in both at the time:
        if [ -d ${SRC_DIR}/$k -a -d ${DST_DIR}/$k ]
   	then
	    echo "Both source and dest dir contain a directory: $k"
	    echo "Source dir $k directory contents:"
	    ls -l ${SRC_DIR}/$k
	    echo "Dest dir $k directory contents:"
	    ls -l ${DST_DIR}/$k
            sudo mv ${SRC_DIR}/$k/* ${DST_DIR}/$k/
	    sudo rmdir ${SRC_DIR}/$k
	else
	    echo "Not a conflicting directory: $k"
            sudo mv ${SRC_DIR}/$k ${DST_DIR}/$k
	fi
    done

    echo "Source dir contents after moving: ${SRC_DIR}"
    ls -lrt ${SRC_DIR}
    echo "Dest dir contents after moving: ${DST_DIR}"
    ls -lrt ${DST_DIR}
}


echo "------------------------------------------------------------"
echo "Time and disk space used before installation begins:"
set -x
date
df -h .
df -BM .

# Check to see which versions of Python-related programs this system
# already has installed, before the script starts installing things.
lsb_release -a
python -V  || echo "No such command in PATH: python"
python2 -V || echo "No such command in PATH: python2"
python3 -V || echo "No such command in PATH: python3"
pip -V  || echo "No such command in PATH: pip"
pip2 -V || echo "No such command in PATH: pip2"
pip3 -V || echo "No such command in PATH: pip3"

# Install a few packages (vim is not strictly necessary -- installed for
# my own convenience):
sudo apt-get --yes install git vim

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

set +x
clean_up() {
    echo "Killing child process"
    kill ${CHILD_PROCESS_PID}
    # Invalidate the user's cached credentials
    sudo --reset-timestamp
    exit
}
set -x

# Kill the child process
trap clean_up SIGHUP SIGINT SIGTERM

# The step below was not needed in order to get a successful
# installation on Ubuntu 16.04 before some time around Nov or Dec
# 2020.  For some reason I am not sure of, it seems that the Python3
# cffi package installed on Ubuntu 16.04 by default causes the command
# `sudo pip3 install cffi` in behavioral-model/travis/install-nnpy.sh
# to fail.

# Removing the Ubuntu package shown below causes 3 other packages that
# depend upon it to be removed, too, as of 2020-Dec, but it seems
# these are not essential Ubuntu functionality, and it continues to do
# most things well without it, so unless I find a better way to avoid
# this conflict, removing this Ubuntu package seems to be a reasonable
# workaround.  I will do it only for Ubuntu 16.04 systems, since it
# seems not to cause a problem for 18.04.

if [ "${ubuntu_release}" = "16.04" ]
then
    sudo apt-get --yes purge python3-cffi-backend
fi

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
sudo apt-get --yes install python3-pip

pip -V  || echo "No such command in PATH: pip"
pip2 -V || echo "No such command in PATH: pip2"
pip3 -V || echo "No such command in PATH: pip3"
# At multiple points I do a 'pip list' command.  This is not required
# for a successful installation -- I do it mainly because I am curious
# to see in the log output files from running this script what
# packages and versions were installed at those times during script
# execution.
pip list  || echo "Some error occurred attempting to run command: pip"
pip3 list || echo "Some error occurred attempting to run command: pip3"

cd "${INSTALL_DIR}"
find /usr/lib /usr/local $HOME/.local | sort > usr-local-1-before-protobuf.txt

set +x
echo "------------------------------------------------------------"
echo "Installing Google protobuf, needed for p4lang/p4c and for p4lang/behavioral-model simple_switch_grpc"
echo "start install protobuf:"
set -x
date

# On a freshly installed Ubuntu 20.04.1 or 18.04.5 system, desktop
# amd64 minimal installation, the Debian package python3-protobuf is
# installed.  This is depended upon by another package called
# python3-macaroonbakery, which in turn is is depended upon by a
# package called gnome-online accounts.  I suspect this might have
# something to do with Ubuntu's desire to make it easy to connect with
# on-line accounts like Google accounts.

# This python3-protobuf package enables one to have a session like
# this with no error, on a freshly installed system:

# $ python3
# >>> import google.protobuf

# However, something about this script doing its work causes a
# conflict between the Python3 protobuf module installed by this
# script, and the one installed by the package python3-protobuf, such
# that the import statement above gives an error.  The package
# google.protobuf.internal is used by the p4lang/tutorials Python
# code, and the only way I know to make this work right now is to
# remove the Debian python3-protobuf package, and then install Python3
# protobuf support using pip3 as done below.

# Experiment starting from a freshly installed Ubuntu 20.04.1 Linux
# desktop amd64 system, minimal install:
# Initially, python3-protobuf package was installed.
# Doing python3 followed 'import' of any of these gave no error:
# + google
# + google.protobuf
# + google.protobuf.internal
# Then did 'sudo apt-get purge python3-protobuf'
# At that point, attempting to import any of the 3 modules above gave an error.
# Then did 'sudo apt-get install python3-pip'
# At that point, attempting to import any of the 3 modules above gave an error.
# Then did 'sudo pip3 install protobuf==3.6.1'
# At that point, attempting to import any of the 3 modules above gave NO error.

echo "Uninstalling Ubuntu python3-protobuf if present"
sudo apt-get purge -y python3-protobuf || echo "Failed to remove python3-protobuf, probably because there was no such package installed"
sudo pip3 install protobuf==3.6.1

cd "${INSTALL_DIR}"
get_from_nearest https://github.com/google/protobuf protobuf.tar.gz
cd protobuf
git checkout v3.6.1
./autogen.sh
./configure
make
sudo make install
sudo ldconfig
# Save about 0.5G of storage by cleaning up protobuf build
make clean

set +x
echo "end install protobuf:"
set -x
date

cd "${INSTALL_DIR}"
find /usr/lib /usr/local $HOME/.local | sort > usr-local-2-after-protobuf.txt

set +x
echo "------------------------------------------------------------"
echo "Installing grpc, needed for installing p4lang/PI"
echo "start install grpc:"
set -x
date

# From BUILDING.md of grpc source repository
sudo apt-get --yes install build-essential autoconf libtool pkg-config

get_from_nearest https://github.com/google/grpc.git grpc.tar.gz
cd grpc
# This version works fine with Ubuntu 16.04
git checkout tags/v1.17.2
git submodule update --init --recursive
if [[ "${ubuntu_release}" > "19" ]]
then
    # Apply patches that seem to be necessary in order for grpc v1.17.2
    # to compile and install successfully on an Ubuntu 19.10 system
    PATCH_DIR="${THIS_SCRIPT_DIR_ABSOLUTE}/grpc-v1.17.2-patches-for-ubuntu19.10"
    for PATCH_FILE in ${PATCH_DIR}/*.diff
    do
        patch -p1 < "${PATCH_FILE}"
    done
fi
make
sudo make install
# I believe the following 2 commands, adapted from similar commands in
# src/python/grpcio/README.rst, should install the Python3 module
# grpc.
find /usr/lib /usr/local $HOME/.local | sort > $HOME/usr-local-2b-before-grpc-pip3.txt
pip3 list | tee $HOME/pip3-list-2b-before-grpc-pip3.txt
sudo pip3 install -rrequirements.txt
GRPC_PYTHON_BUILD_WITH_CYTHON=1 sudo pip3 install .
sudo ldconfig
# Save about 0.3G of storage by cleaning up grpc v1.17.2 build
make clean

set +x
echo "end install grpc:"
set -x
date

cd "${INSTALL_DIR}"
find /usr/lib /usr/local $HOME/.local | sort > usr-local-3-after-grpc.txt

set +x
echo "------------------------------------------------------------"
echo "Installing p4lang/PI, needed for installing p4lang/behavioral-model simple_switch_grpc"
echo "start install PI:"
set -x
date

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

# Save about 0.25G of storage by cleaning up PI build
make clean
move_usr_local_lib_python3_from_site_packages_to_dist_packages

set +x
echo "end install PI:"
set -x
date

cd "${INSTALL_DIR}"
find /usr/lib /usr/local $HOME/.local | sort > usr-local-4-after-PI.txt

set +x
echo "------------------------------------------------------------"
echo "Installing p4lang/behavioral-model"
echo "start install behavioral-model:"
set -x
date

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
git pull
git log -n 1
PATCH_DIR="${THIS_SCRIPT_DIR_ABSOLUTE}/patches"
patch -p1 < "${PATCH_DIR}/behavioral-model-use-correct-libssl-pkg.patch" || echo "Errors while attempting to patch behavioral-model, but continuing anyway ..."
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
./configure --with-thrift 'CXXFLAGS=-O0 -g'
# I saw the following near end of output of 'configure' command:
#Features recap ......................
#With Sysrepo .................. : no
#With Thrift ................... : yes
make
sudo make install
sudo ldconfig
move_usr_local_lib_python3_from_site_packages_to_dist_packages

set +x
echo "end install behavioral-model:"
set -x
date

cd "${INSTALL_DIR}"
find /usr/lib /usr/local $HOME/.local | sort > usr-local-5-after-behavioral-model.txt

set +x
echo "------------------------------------------------------------"
echo "Installing p4lang/p4c"
echo "start install p4c:"
set -x
date

# Install Ubuntu dependencies needed by p4c, from its README.md
# Matches latest p4c README.md instructions as of 2019-Oct-09
sudo apt-get --yes install cmake g++ git automake libtool libgc-dev bison flex libfl-dev libgmp-dev libboost-dev libboost-iostreams-dev libboost-graph-dev llvm pkg-config python3-pip tcpdump
# Starting in 2019-Nov, Python3 version of Scapy is needed for `cd
# p4c/build ; make check` to succeed.
sudo pip3 install scapy
# Earlier versions of this script installed the Ubuntu package
# python-ipaddr.  However, that no longer exists in Ubuntu 20.04.  PIP
# for Python3 can install the ipaddr module, which is good enough to
# enable two of p4c's many tests to pass, tests that failed if the
# ipaddr Python3 module is not installed, in my testing on
# 2020-Oct-17.  From the Python stack trace that appears when running
# those failing tests, the code that requires this module is in
# behavioral-model's runtime_CLI.py source file, in a function named
# ipv6Addr_to_bytes.
sudo pip3 install ipaddr
pip3 list

# Clone p4c and its submodules:
git clone --recursive https://github.com/p4lang/p4c.git
cd p4c
git log -n 1
mkdir build
cd build
# Configure for a debug build
cmake .. -DCMAKE_BUILD_TYPE=DEBUG $*
make -j${MAX_PARALLEL_JOBS}
sudo make install
sudo ldconfig

set +x
echo "end install p4c:"
set -x
date

cd "${INSTALL_DIR}"
find /usr/lib /usr/local $HOME/.local | sort > usr-local-6-after-p4c.txt

set +x
echo "------------------------------------------------------------"

echo "Installing Mininet - not necessary to run P4 programs, but useful if"
echo "you want to run tutorials from https://github.com/p4lang/tutorials"
echo "repository."
echo "start install mininet:"
set -x
date

git clone git://github.com/mininet/mininet mininet
cd mininet
PATCH_DIR="${THIS_SCRIPT_DIR_ABSOLUTE}/patches"
patch -p1 < "${PATCH_DIR}/mininet-dont-install-python2.patch" || echo "Errors while attempting to patch mininet, but continuing anyway ..."
cd ..
sudo ./mininet/util/install.sh -nw

set +x
echo "end install mininet:"
set -x
date

cd "${INSTALL_DIR}"
find /usr/lib /usr/local $HOME/.local | sort > usr-local-7-after-mininet-install.txt

set +x
echo "------------------------------------------------------------"

echo "Installing PTF"
echo "start install ptf:"
set -x
date

sudo pip3 install pypcap

git clone git://github.com/p4lang/ptf
cd ptf
sudo python3 setup.py install

set +x
echo "end install ptf:"
set -x
date

cd "${INSTALL_DIR}"
find /usr/lib /usr/local $HOME/.local | sort > usr-local-8-after-ptf-install.txt

set +x
echo "------------------------------------------------------------"
echo "Installing a few miscellaneous packages"
echo "start install miscellaneous packages:"
set -x
date

# Things needed for `cd tutorials/exercises/basic ; make run` to work:
sudo apt-get --yes install libgflags-dev net-tools
sudo pip3 install psutil crcmod
pip3 list

set +x
echo "end install miscellaneous packages:"
set -x
date

cd "${INSTALL_DIR}"
find /usr/lib /usr/local $HOME/.local | sort > usr-local-9-after-miscellaneous-install.txt

pip list  || echo "Some error occurred attempting to run command: pip"
pip3 list

set +e

set +x
echo "------------------------------------------------------------"
echo "Time and disk space used when installation was complete:"
set -x
date
df -h .
df -BM .

cd "${INSTALL_DIR}"
DETS="install-details"
mkdir -p "${DETS}"
mv usr-local-*.txt "${DETS}"
cd "${DETS}"
diff usr-local-1-before-protobuf.txt usr-local-2-after-protobuf.txt > usr-local-file-changes-protobuf.txt
diff usr-local-2-after-protobuf.txt usr-local-3-after-grpc.txt > usr-local-file-changes-grpc.txt
diff usr-local-3-after-grpc.txt usr-local-4-after-PI.txt > usr-local-file-changes-PI.txt
diff usr-local-4-after-PI.txt usr-local-5-after-behavioral-model.txt > usr-local-file-changes-behavioral-model.txt
diff usr-local-5-after-behavioral-model.txt usr-local-6-after-p4c.txt > usr-local-file-changes-p4c.txt
diff usr-local-6-after-p4c.txt usr-local-7-after-mininet-install.txt > usr-local-file-changes-mininet-install.txt
diff usr-local-7-after-mininet-install.txt usr-local-8-after-ptf-install.txt > usr-local-file-changes-ptf-install.txt
diff usr-local-8-after-ptf-install.txt usr-local-9-after-miscellaneous-install.txt > usr-local-file-changes-miscellaneous-install.txt

P4GUIDE_BIN="${THIS_SCRIPT_DIR_ABSOLUTE}"

set +x
echo "----------------------------------------------------------------------"
echo "Output of script p4-environment-info.sh"
echo "----------------------------------------------------------------------"
"${THIS_SCRIPT_DIR_ABSOLUTE}/p4-environment-info.sh"
echo "----------------------------------------------------------------------"

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
set -x

clean_up
