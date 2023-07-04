#! /bin/bash

# Copyright 2022-present Intel Corporation

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


# This script differs from install-p4dev-v4.sh as follows:

# It installs later versions of protobuf and grpc libraries.
# Attempt to follow what p4lang repos use for CI testing, as changed
# by this commit in 2022-Feb:
# https://github.com/p4lang/third-party/commit/f9d1bd9b63f7bdfe497f69b0ee1335b7b939e095
#
# * Update Protobuf to 3.18.1
# * Update gRPC to 1.43.2
# * Install more recent Thrift (0.13)
# * Use python-is-python3 to set up python symlink

# Remember the current directory when the script was started:
INSTALL_DIR="${PWD}"

THIS_SCRIPT_FILE_MAYBE_RELATIVE="$0"
THIS_SCRIPT_DIR_MAYBE_RELATIVE="${THIS_SCRIPT_FILE_MAYBE_RELATIVE%/*}"
THIS_SCRIPT_DIR_ABSOLUTE=`readlink -f "${THIS_SCRIPT_DIR_MAYBE_RELATIVE}"`

linux_version_warning() {
    1>&2 echo "Found ID ${ID} and VERSION_ID ${VERSION_ID} in /etc/os-release"
    1>&2 echo "This script only supports these:"
    1>&2 echo "    ID ubuntu, VERSION_ID in 18.04 20.04 22.04"
    1>&2 echo "    ID fedora, VERSION_ID in 35"
    1>&2 echo ""
    1>&2 echo "Proceed installing manually at your own risk of"
    1>&2 echo "significant time spent figuring out how to make it all"
    1>&2 echo "work, or consider getting VirtualBox and creating an"
    1>&2 echo "Ubuntu virtual machine with one of the tested versions."
}

check_for_python2_installed() {
    for p in python python2
    do
	which $p > /dev/null
	e1=$?
        if [ $e1 -eq 0 ]
	then
	    tmp_out=`$p -c 'import sys; print(sys.version_info)' | grep 'major=2'`
	    e2=$?
	    if [ $e2 -eq 0 ]
	    then
		#echo "Found Python2 installed with cmd name: $p"
		python2_cmd_name=$p
		return
	    fi
	fi
    done
    python2_cmd_name=""
}

python_version_warning() {
    1>&2 echo "The following version of Python2 was found installed on"
    1>&2 echo "this system:"
    1>&2 echo ""
    1>&2 echo "Python2 command name: $python2_cmd_name"
    1>&2 echo "sys.version_info value from that command:"
    1>&2 echo ""
    "$python2_cmd_name" -c 'import sys; print(sys.version_info)'
    1>&2 echo ""
    1>&2 echo "This script has been tested on systems where Python2"
    1>&2 echo "was installed, and while it produces no errors while"
    1>&2 echo "the script is running, the resulting system ends up"
    1>&2 echo "with a mix of some Python2 packages installed, and some"
    1>&2 echo "Python3 packages installed, that cause failures when"
    1>&2 echo "attempting to run many P4 open source development tools"
    1>&2 echo "in common use cases."
    1>&2 echo ""
    1>&2 echo "It is recommended that you only use this install script"
    1>&2 echo "on systems with no Python2 installed at all, since"
    1>&2 echo "Python2 is no longer supported as of 2020-Jan-01, and"
    1>&2 echo "the P4 open source development tools do work well with"
    1>&2 echo "Python3, and I doubt any changes will be made in P4"
    1>&2 echo "development tools to improve their working with Python2"
    1>&2 echo "any longer."
    1>&2 echo ""
    1>&2 echo "    https://python.org/doc/sunset-python-2"
    1>&2 echo ""
    1>&2 echo "You are welcome to disable this check in your copy of"
    1>&2 echo "this install script, and force installation anyway, but"
    1>&2 echo "expect the resulting installation not to work, unless"
    1>&2 echo "you figure out yourself how to make it work."
}

abort_script=0

if [ ! -r /etc/os-release ]
then
    1>&2 echo "No file /etc/os-release.  Cannot determine what OS this is."
    linux_version_warning
    exit 1
fi
source /etc/os-release

supported_distribution=0
tried_but_got_build_errors=0
if [ "${ID}" = "ubuntu" ]
then
    case "${VERSION_ID}" in
	18.04)
	    supported_distribution=1
	    ;;
	20.04)
	    supported_distribution=1
	    ;;
	22.04)
	    supported_distribution=1
	    ;;
    esac
elif [ "${ID}" = "fedora" ]
then
    case "${VERSION_ID}" in
	35)
	    supported_distribution=1
	    ;;
	36)
	    supported_distribution=0
	    tried_but_got_build_errors=1
	    ;;
	37)
	    supported_distribution=0
	    tried_but_got_build_errors=1
	    ;;
    esac
fi

if [ ${supported_distribution} -eq 1 ]
then
    echo "Found supported ID ${ID} and VERSION_ID ${VERSION_ID} in /etc/os-release"
else
    linux_version_warning
    if [ ${tried_but_got_build_errors} -eq 1 ]
    then
	1>&2 echo ""
	1>&2 echo "This OS has been tried at least onc before, but"
	1>&2 echo "there were errors during a compilation or build"
	1>&2 echo "step that have not yet been fixed.  If you have"
	1>&2 echo "experience in fixing such matters, your help is"
	1>&2 echo "appreciated."
    fi
    #exit 1
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

min_free_disk_MBytes=`expr 25 \* 1024`
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

PATCH_DIR1="${THIS_SCRIPT_DIR_ABSOLUTE}/patches"

for dir in "${PATCH_DIR1}"
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

check_for_python2_installed
if [ ! -z "$python2_cmd_name" ]
then
    python_version_warning
    exit 1
else
    1>&2 echo "Found no Python2 installed.  Continuing with installation."
fi

echo "Passed all sanity checks"

set -e
set -x

# The maximum number of gcc/g++ jobs to run in parallel.  1 is the
# safest number that enables compiling p4c even on machines with only
# 2 GB of RAM.
MAX_PARALLEL_JOBS=1

set +x
echo "This script builds and installs the P4_16 (and also P4_14)"
echo "compiler, and the behavioral-model software packet forwarding"
echo "program, that can behave as just about any legal P4 program."
echo ""
echo "It is regularly tested on freshly installed versions of these systems:"
echo "    Ubuntu 18.04"
echo "    Ubuntu 20.04"
echo "    Ubuntu 22.04"
echo "with all Ubuntu software updates as of the date of testing.  See"
echo "this directory for log files recording the last date this script"
echo "was tested on its supported operating systems:"
echo ""
echo "    https://github.com/jafingerhut/p4-guide/tree/master/bin/output"
echo ""
echo "The files installed by this script consume about 25 GB of disk space."
echo ""
echo "On a 2019 MacBook Pro with a decent speed Internet connection"
echo "and an SSD drive, running Ubuntu Linux in a VirtualBox VM, it"
echo "took about 4 hours."
echo ""
echo "Versions of software that will be installed by this script:"
echo ""
echo "+ protobuf: github.com/google/protobuf v3.18.1"
echo "+ gRPC: github.com/google/grpc.git v1.43.2"
echo "+ PI: github.com/p4lang/PI latest version"
echo "+ behavioral-model: github.com/p4lang/behavioral-model latest version"
echo "  which, as of 2022-Feb-10, also installs these things:"
echo "  + thrift version 0.13.0"
echo "  + nanomsg version 1.0.0"
echo "  + nnpy git checkout c7e718a5173447c85182dc45f99e2abcf9cd4065 (latest as of 2015-Apr-22"
echo "+ p4c: github.com/p4lang/p4c latest version"
echo "+ ptf: github.com/p4lang/ptf latest version"
echo "+ Mininet: github.com/mininet/mininet latest version as of 2023-May-28"
echo "+ Python packages: protobuf 3.18.1, grpcio 1.43.2"
echo "+ Python packages: scapy, psutil, crcmod"
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

if [ "${ID}" = "ubuntu" ]
then
    PY3LOCALPATH=`${THIS_SCRIPT_DIR_ABSOLUTE}/py3localpath.py`
fi

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
python -V  || echo "No such command in PATH: python"
python2 -V || echo "No such command in PATH: python2"
python3 -V || echo "No such command in PATH: python3"
pip -V  || echo "No such command in PATH: pip"
pip2 -V || echo "No such command in PATH: pip2"
pip3 -V || echo "No such command in PATH: pip3"

# On new systems if you have never checked repos you should do that first

# Install a few packages (vim is not strictly necessary -- installed for
# my own convenience):
if [ "${ID}" = "ubuntu" ]
then
    sudo apt-get --yes update
    sudo apt-get --yes install git vim
elif [ "${ID}" = "fedora" ]
then
    sudo dnf -y update
    sudo dnf -y install git vim
fi

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

# Install Ubuntu packages needed by protobuf v3.18.1, from its src/README.md

# Install pkg-config here, as it is required for p4lang/PI
# installation to succeed.

# It appears that some part of the build process for Thrift 0.12.0
# requires that pip3 has been installed first.  Without this, there is
# an error during building Thrift 0.12.0 where a Python 3 program
# cannot import from the setuptools package.
if [ "${ID}" = "ubuntu" ]
then
    sudo apt-get --yes install \
	 autoconf automake libtool curl make g++ unzip \
	 pkg-config python3-pip python3-venv
elif [ "${ID}" = "fedora" ]
then
    sudo dnf -y install \
	 autoconf automake libtool curl make g++ unzip \
	 pkg-config python3-pip
fi

# Create a new Python virtual environment using venv.  Later we will
# attempt to ensure that all new Python packages installed are
# installed into this virtual environment, not into system-wide
# directories like /usr/local/bin
PYTHON_VENV="${INSTALL_DIR}/p4dev-python-venv"
python3 -m venv "${PYTHON_VENV}"
if [ ! -r "${PYTHON_VENV}/bin/activate" ]
then
	1>&2 echo "No file ${PYTHON_VENV}/bin/activate.  Why not?"
	exit 1
fi
source "${PYTHON_VENV}/bin/activate"
ls -R "${PYTHON_VENV}"
PIP_SUDO=""

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
find /usr/lib /usr/local $HOME/.local "${PYTHON_VENV}" | sort > usr-local-1-before-protobuf.txt

set +x
echo "------------------------------------------------------------"
echo "Installing Google protobuf, needed for p4lang/p4c and for p4lang/behavioral-model simple_switch_grpc"
echo "start install protobuf:"
set -x
date

# On a freshly installed Ubuntu 18.04, 20.04, or 22.04 system, desktop
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

if [ "${ID}" = "ubuntu" ]
then
    echo "Uninstalling Ubuntu python3-protobuf if present"
    sudo apt-get purge -y python3-protobuf || echo "Failed to remove python3-protobuf, probably because there was no such package installed"
    ${PIP_SUDO} pip3 install protobuf==3.18.1
elif [ "${ID}" = "fedora" ]
then
    ${PIP_SUDO} pip3 install protobuf==3.18.1
fi

cd "${INSTALL_DIR}"
get_from_nearest https://github.com/protocolbuffers/protobuf protobuf.tar.gz
cd protobuf
git checkout v3.18.1
git submodule update --init --recursive
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
find /usr/lib /usr/local $HOME/.local "${PYTHON_VENV}" | sort > usr-local-2-after-protobuf.txt

# Install cmake v3.16.3 or later.  On Ubuntu 20.04 and later systems,
# this is easily done via apt-get on the cmake Ubuntu package.  On
# Ubuntu 18.04, that package is v3.10.2, one that fails to install
# grpc fully, so download and build cmake v3.16.3 from source code.
if [ "${ID}" = "ubuntu" ]
then
    if [ "${VERSION_ID}" = "18.04" ]
    then
	sudo apt install --yes make g++ libssl-dev
	git clone https://gitlab.kitware.com/cmake/cmake.git
	cd cmake
	git checkout v3.16.3
	./bootstrap
	make
	sudo make install
    else
	sudo apt-get --yes install cmake
    fi
elif [ "${ID}" = "fedora" ]
then
    sudo dnf -y install cmake
fi


cd "${INSTALL_DIR}"

set +x
echo "------------------------------------------------------------"
echo "Installing grpc, needed for installing p4lang/PI"
echo "start install grpc:"
set -x
date

# From BUILDING.md of grpc source repository
if [ "${ID}" = "ubuntu" ]
then
    sudo apt-get --yes install build-essential autoconf libtool pkg-config
    # TODO: This package is not mentioned in grpc BUILDING.md
    # instructions, but when I tried on Ubuntu 20.04 without it, the
    # building of grpc failed with not being able to find an OpenSSL
    # library.
    sudo apt-get --yes install libssl-dev
elif [ "${ID}" = "fedora" ]
then
    # I am not sure that the 'Development Tools' group on Fedora is
    # identical to installing the build-essential package on Ubuntu,
    # but there is at least significant overlap between what they
    # install.
    sudo dnf group install -y 'Development Tools'
    # python3-devel is needed on Fedora systems for the `pip3 install
    # .` step below
    sudo dnf -y install autoconf libtool pkg-config python3-devel
    # TODO: Should I install openssl-devel here on Fedora?  There is
    # no package named libssl-dev or libssl-devel.  It seems like it
    # might be unnecessary, as without doing so the build of grpc
    # below went through with no errors.
fi

get_from_nearest https://github.com/grpc/grpc.git grpc.tar.gz
cd grpc
git checkout tags/v1.43.2
# These commands are recommended in grpc's BUILDING.md file for Unix:
git submodule update --init --recursive

mkdir -p cmake/build
cd cmake/build
cmake ../..
make
sudo make install
# I believe the following 2 commands, adapted from similar commands in
# src/python/grpcio/README.rst, should install the Python3 module
# grpc.
find /usr/lib /usr/local $HOME/.local "${PYTHON_VENV}" | sort > $HOME/usr-local-2b-before-grpc-pip3.txt
pip3 list | tee $HOME/pip3-list-2b-before-grpc-pip3.txt
cd ../..
${PIP_SUDO} pip3 install -rrequirements.txt
GRPC_PYTHON_BUILD_WITH_CYTHON=1 ${PIP_SUDO} pip3 install .
sudo ldconfig
# Save some storage by cleaning up grpc build
# TODO: Is this command useful with latest cmake build infra?
#make clean

set +x
echo "end install grpc:"
set -x
date

cd "${INSTALL_DIR}"
find /usr/lib /usr/local $HOME/.local "${PYTHON_VENV}" | sort > usr-local-3-after-grpc.txt

set +x
echo "------------------------------------------------------------"
echo "Installing p4lang/PI, needed for installing p4lang/behavioral-model simple_switch_grpc"
echo "start install PI:"
set -x
date

# Deps needed to build PI:
if [ "${ID}" = "ubuntu" ]
then
    sudo apt-get --yes install libreadline-dev valgrind libtool-bin libboost-dev libboost-system-dev libboost-thread-dev
elif [ "${ID}" = "fedora" ]
then
    # Any other libraries output from 'dnf search libtool' that need
    # to be installed?
    sudo dnf -y install readline-devel valgrind libtool boost-devel boost-system boost-thread
fi

git clone https://github.com/p4lang/PI
cd PI
git submodule update --init --recursive
git log -n 1
./autogen.sh
if [ "${ID}" = "ubuntu" ]
then
    ./configure --with-proto --without-internal-rpc --without-cli --without-bmv2
elif [ "${ID}" = "fedora" ]
then
    PKG_CONFIG_PATH=/usr/local/lib/pkgconfig ./configure --with-proto --without-internal-rpc --without-cli --without-bmv2
fi
make
sudo make install

# Save about 0.25G of storage by cleaning up PI build
make clean
if [ "${ID}" = "ubuntu" ]
then
    move_usr_local_lib_python3_from_site_packages_to_dist_packages
fi

set +x
echo "end install PI:"
set -x
date

cd "${INSTALL_DIR}"
find /usr/lib /usr/local $HOME/.local "${PYTHON_VENV}" | sort > usr-local-4-after-PI.txt

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
patch -p1 < "${PATCH_DIR}/behavioral-model-support-fedora.patch"
patch -p1 < "${PATCH_DIR}/behavioral-model-support-venv.patch"

# Stop here for now, so I can debug some failing early steps in
# behavioral-model installation on Ubuntu 23.04
exit 0

# This command installs Thrift, which I want to include in my build of
# simple_switch_grpc
./install_deps.sh
# simple_switch_grpc README.md says to configure and build the bmv2
# code first, using these commands:
./autogen.sh
# Remove 'CXXFLAGS ...' part to disable debug
if [ "${ID}" = "ubuntu" ]
then
    ./configure --with-pi --with-thrift 'CXXFLAGS=-O0 -g'
elif [ "${ID}" = "fedora" ]
then
    PKG_CONFIG_PATH=/usr/local/lib/pkgconfig ./configure --with-pi --with-thrift 'CXXFLAGS=-O0 -g'
fi
make
sudo make install-strip
sudo ldconfig
if [ "${ID}" = "ubuntu" ]
then
    move_usr_local_lib_python3_from_site_packages_to_dist_packages
fi

set +x
echo "end install behavioral-model:"
set -x
date

cd "${INSTALL_DIR}"
find /usr/lib /usr/local $HOME/.local "${PYTHON_VENV}" | sort > usr-local-5-after-behavioral-model.txt

set +x
echo "------------------------------------------------------------"
echo "Installing p4lang/p4c"
echo "start install p4c:"
set -x
date

if [ "${ID}" = "ubuntu" ]
then
    # Install Ubuntu dependencies needed by p4c, from its README.md
    # Matches latest p4c README.md instructions as of 2019-Oct-09
    sudo apt-get --yes install g++ git automake libtool libgc-dev \
         bison flex libfl-dev libgmp-dev \
         libboost-dev libboost-iostreams-dev libboost-graph-dev \
         llvm pkg-config python3-pip tcpdump
elif [ "${ID}" = "fedora" ]
then
    sudo dnf -y install g++ git automake libtool gc-devel \
         bison flex libfl-devel gmp-devel \
         boost-devel boost-iostreams boost-graph \
         llvm pkgconf python3-pip tcpdump
fi
# Starting in 2019-Nov, Python3 version of Scapy is needed for `cd
# p4c/build ; make check` to succeed.
# ply package is needed for ebpf and ubpf backend tests to pass
${PIP_SUDO} pip3 install scapy ply
pip3 list

# Clone p4c and its submodules:
git clone --recursive https://github.com/p4lang/p4c.git
cd p4c
git log -n 1
mkdir build
cd build

if [ "${ID}" = "ubuntu" ]
then
    # Configure for a debug build and build p4testgen
    cmake .. -DCMAKE_BUILD_TYPE=DEBUG -DENABLE_TEST_TOOLS=ON
elif [ "${ID}" = "fedora" ]
then
    # Do not enable build of p4testgen on Fedora until compilation
    # issues are fixed.
    cmake .. -DCMAKE_BUILD_TYPE=DEBUG
fi
make -j${MAX_PARALLEL_JOBS}
sudo make install
sudo ldconfig

set +x
echo "end install p4c:"
set -x
date

cd "${INSTALL_DIR}"
find /usr/lib /usr/local $HOME/.local "${PYTHON_VENV}" | sort > usr-local-6-after-p4c.txt

set +x
echo "------------------------------------------------------------"

echo "Installing Mininet - not necessary to run P4 programs, but useful if"
echo "you want to run tutorials from https://github.com/p4lang/tutorials"
echo "repository."
echo "start install mininet:"
set -x
date

# Pin to a particular version, so that I know the patch below will
# continue to apply.  Will likely want to update this to newer
# versions once or twice a year.
MININET_COMMIT="5b1b376336e1c6330308e64ba41baac6976b6874"  # 2023-May-28
git clone https://github.com/mininet/mininet mininet
cd mininet
git checkout ${MININET_COMMIT}
PATCH_DIR="${THIS_SCRIPT_DIR_ABSOLUTE}/patches"
patch -p1 < "${PATCH_DIR}/mininet-patch-for-2023-jun.patch"
cd ..
sudo ./mininet/util/install.sh -nw

set +x
echo "end install mininet:"
set -x
date

cd "${INSTALL_DIR}"
find /usr/lib /usr/local $HOME/.local "${PYTHON_VENV}" | sort > usr-local-7-after-mininet-install.txt

set +x
echo "------------------------------------------------------------"

echo "Installing PTF"
echo "start install ptf:"
set -x
date

# Attempting this command was causing errors on Ubuntu 22.04 systems.
# The ptf README says it is optional, so leave it out for now,
# until/unless someone discovers a way to install it correctly on
# Ubuntu 22.04.
#sudo pip3 install pypcap

git clone https://github.com/p4lang/ptf
cd ptf
#sudo python3 setup.py install
${PIP_SUDO} pip install .

set +x
echo "end install ptf:"
set -x
date

cd "${INSTALL_DIR}"
find /usr/lib /usr/local $HOME/.local "${PYTHON_VENV}" | sort > usr-local-8-after-ptf-install.txt

set +x
echo "------------------------------------------------------------"
echo "Installing a few miscellaneous packages"
echo "start install miscellaneous packages:"
set -x
date

# Things needed for `cd tutorials/exercises/basic ; make run` to work:
if [ "${ID}" = "ubuntu" ]
then
    sudo apt-get --yes install libgflags-dev net-tools
elif [ "${ID}" = "fedora" ]
then
    sudo dnf -y install gflags-devel net-tools
fi
${PIP_SUDO} pip3 install psutil crcmod
# p4runtime-shell package, installed from latest source version
${PIP_SUDO} pip3 install git+https://github.com/p4lang/p4runtime-shell.git
pip3 list

set +x
echo "end install miscellaneous packages:"
set -x
date

cd "${INSTALL_DIR}"
find /usr/lib /usr/local $HOME/.local "${PYTHON_VENV}" | sort > usr-local-9-after-miscellaneous-install.txt

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
mv usr-local-*.txt pip3-list-2b-before-grpc-pip3.txt "${DETS}"
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
