#! /bin/bash


# Write a script that attempts to automate these instructions:
# https://github.com/ipdk-io/ipdk/blob/main/build/IPDK_Container/ovs-with-p4_howto

# Remember the current directory when the script was started:
INSTALL_DIR="${PWD}"

if [ $# -ne 1 ]
then
    1>&2 echo "usage: `basename $0` <sde_root_dir>"
    exit 1
fi

# Make the results of this script at least somewhat reproducible, by
# picking particular versions of git repos to use.
TARGET_SYSLIBS_COMMIT="a017b08c91de8fb61c2d89795b000cacde50bcc7"  # 2021-Dec-17
TARGET_UTILS_COMMIT="b5a03f0797fb6e8c9740bf025772ef87384f40bb"    # 2021-Dec-17

sudo apt-get install git build-essential cmake

set -x

######################################################################
export SDE="$1"
export SDE_INSTALL=${SDE}/install
mkdir -p "${SDE_INSTALL}"
export LD_LIBRARY_PATH=$SDE_INSTALL/lib
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$SDE_INSTALL/lib/x86_64-linux-gnu
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$SDE_INSTALL/lib64
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib64
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib

######################################################################
# 2. Build P4-DPDK-Target with P4-DPDK
# - Build target-syslibs
cd "${INSTALL_DIR}"
if [ -d target-syslibs/.git ]
then
    echo "Found existing target-syslibs/.git directory.   Using that instead of fresh clone"
    cd target-syslibs
else
    git clone https://github.com/p4lang/target-syslibs.git --recursive target-syslibs
    cd target-syslibs
    git checkout ${TARGET_SYSLIBS_COMMIT}
fi
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$SDE_INSTALL ..
make clean
make $NUM_THREADS
#make $NUM_THREADS install
sudo ldconfig

######################################################################
# - Build target-utils
cd "${INSTALL_DIR}"
if [ -d target-utils/.git ]
then
    echo "Found existing target-utils/.git directory.   Using that instead of fresh clone"
    cd target-utils
else
    git clone https://github.com/p4lang/target-utils.git --recursive target-utils
    cd target-utils
    git checkout ${TARGET_UTILS_COMMIT}
fi
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$SDE_INSTALL -DCPYTHON=1 -DSTANDALONE=ON ..
make clean
make $NUM_THREADS
make $NUM_THREADS install
sudo ldconfig
