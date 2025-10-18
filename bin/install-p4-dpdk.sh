#! /bin/bash
# Copyright 2023 Andy Fingerhut
#
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
#
# SPDX-License-Identifier: Apache-2.0


######################################################################
# Steps run by https://github.com/p4lang/p4c CI task named
# build_p4dpdk_ubuntu as of 2023-Aug-19 are listed below.  Each of
# these strings prefixed with '+' can be found by searching in the
# file .github/workflows/ci-dpdk-ptf-tests.yml in the p4c repo.  The
# ones prefixed with '-' are not necessary to perform in this install
# script.
#
# - Set up job
# - ccache
# + Checkout DPDK-target
# + Checkout ipdk-recipe
# + checkout P4C
# + Install DPDK dependencies
# + Compile p4sde dpdk target
# + Build infrap4d dependencies
# + Build infrap4d
# + Build p4c with only the DPDK backend
# + Run DPDK PTF tests
# - Post checkout P4C
# - Post Checkout ipdk-recipe
# - Post Checkout DPDK-target
# - Post ccache
# - Complete job
######################################################################

# Remember the current directory when the script was started:
INSTALL_DIR="${PWD}"

THIS_SCRIPT_FILE_MAYBE_RELATIVE="$0"
THIS_SCRIPT_DIR_MAYBE_RELATIVE="${THIS_SCRIPT_FILE_MAYBE_RELATIVE%/*}"
THIS_SCRIPT_DIR_ABSOLUTE=`readlink -f "${THIS_SCRIPT_DIR_MAYBE_RELATIVE}"`

set -x
set -e

PYTHON_USE_VENV=0

if [ ${PYTHON_USE_VENV} -eq 1 ]
then
    # Try installing Python packages globally on the system, not in a
    # venv, to see if later parts of this script operate without
    # error.
    PYTHON_VENV="${INSTALL_DIR}/p4dev-python-venv"
    python3 -m venv "${PYTHON_VENV}"
    source "${PYTHON_VENV}/bin/activate"
    PIP_SUDO=""
else
    PIP_SUDO="sudo"
fi

# + Checkout DPDK-target
cd "${INSTALL_DIR}"
git clone https://github.com/p4lang/p4-dpdk-target p4sde
cd p4sde
if [ ${PYTHON_USE_VENV} -eq 0 ]
then
    patch -p1 < "${THIS_SCRIPT_DIR_ABSOLUTE}/patches/p4-dpdk-target-use-sudo-for-pip.patch"
fi
git log -n 1 | cat
git submodule update --init --recursive

# + Checkout ipdk-recipe
cd "${INSTALL_DIR}"
git clone https://github.com/ipdk-io/networking-recipe ipdk.recipe
cd ipdk.recipe
git log -n 1 | cat
git submodule update --init --recursive

# + checkout P4C
cd "${INSTALL_DIR}"
git clone https://github.com/p4lang/p4c
cd p4c
git log -n 1 | cat
git submodule update --init --recursive

# TODO: Review these env variable settings to see if they work properly
export SDE="${INSTALL_DIR}"
export SDE_INSTALL="${INSTALL_DIR}/sde_install"
export P4C_DIR="${INSTALL_DIR}/p4c"
export IPDK_RECIPE="${INSTALL_DIR}/ipdk.recipe"
export DEPEND_INSTALL="/usr/local"

# + checkout stratum to IPDK_RECIPE/setup
cd "${IPDK_RECIPE}"
if [ ! -d "setup" ]; then
git clone https://github.com/ipdk-io/stratum-deps.git setup
fi
cd setup
git log -n 1 | cat
git submodule update --init --recursive

# + Install DPDK dependencies
cd "${INSTALL_DIR}"
cd p4sde/tools/setup
sudo apt-get update -y

sudo apt-get install -y python3-pip python3-venv

# Python packages needed for install_dep.py to work
${PIP_SUDO} pip3 install distro wheel

# Install wireshark and tshark in a way that avoids an interactive
# response being required.
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -q install wireshark tshark

# TODO: The way install_dep.py is currently written, it tries to
# install tshark using apt-get with command line options that cause it
# to prompt for a yes or no answer and wait for it, without showing
# that prompt on the console.  Figure out a way to get it to
# auto-answer "no", that I do not want to allow non-root users to
# capture packets using tshark.
python3 install_dep.py
pip3 list > "${INSTALL_DIR}/pip-list-1-after-install_dep.py.txt"

# + Compile p4sde dpdk target
cd "${INSTALL_DIR}"
cd p4sde
#mkdir ${GITHUB_WORKSPACE}/install
mkdir "${SDE_INSTALL}"
./autogen.sh
./configure "--prefix=${SDE_INSTALL}"
make
make install

# + Build infrap4d dependencies
cd "${IPDK_RECIPE}"
echo "Install infrap4d dependencies"
sudo apt-get install -y libatomic1 libnl-route-3-dev openssl libssl-dev
${PIP_SUDO} pip3 install -r requirements.txt
pip3 list > "${INSTALL_DIR}/pip-list-2-after-ipdk-recipe-requirements.txt"
cd "${IPDK_RECIPE}/setup"
echo "Build infrap4d dependencies"
cmake -B build -DCMAKE_INSTALL_PREFIX="$DEPEND_INSTALL" -DUSE_SUDO=ON
cmake --build build

# + Build infrap4d
cd "${IPDK_RECIPE}"
sudo ./make-all.sh --target=dpdk --no-krnlmon --no-ovs -S "${SDE_INSTALL}" -D "${DEPEND_INSTALL}"

# + Build p4c with only the DPDK backend
cd "${INSTALL_DIR}"
cd p4c

# The commands below are copied and then sometimes modified from the
# file p4c/tools/dpdk-ci-build.sh
#sudo -E tools/dpdk-ci-build.sh "${P4C_DIR}" "${IPDK_RECIPE}" "${SDE_INSTALL}" "${DEPEND_INSTALL}"
#
# The modifications are intended to enable Python packages to be
# installed in a venv, not system-wide directories, and to use `sudo`
# for commands that do need them when this script is run as a user
# with normal non-superuser privileges.

# Update SDE libraries for infrap4d; commands are copied from  ipdk.recipe/scripts/dpdk/dpdk-ci-build.sh
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${SDE_INSTALL}/lib
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${SDE_INSTALL}/lib64

export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${SDE_INSTALL}/lib/x86_64-linux-gnu

# Update IPDK RECIPE libraries
export LD_LIBRARY_PATH=${IPDK_RECIPE}/install/lib:${IPDK_RECIPE}/install/lib64:${LD_LIBRARY_PATH}
export PATH=${IPDK_RECIPE}/install/bin:${IPDK_RECIPE}/install/sbin:${PATH}

export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/lib
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/lib64

# Update Dependent libraries
export LD_LIBRARY_PATH=${DEPEND_INSTALL}/lib:${DEPEND_INSTALL}/lib64:${LD_LIBRARY_PATH}
export PATH=${DEPEND_INSTALL}/bin:${DEPEND_INSTALL}/sbin:${PATH}
export LIBRARY_PATH=${DEPEND_INSTALL}/lib:${DEPEND_INSTALL}/lib64:${LIBRARY_PATH}

P4C_DEPS="bison \
          build-essential \
          ccache \
          cmake \
          flex \
          g++ \
          git \
          lld \
          libboost-dev \
          libboost-graph-dev \
          libboost-iostreams-dev \
          libfl-dev \
          libgc-dev \
          pkg-config \
          python3 \
          python3-pip \
          python3-setuptools \
          tcpdump \
          tcpreplay \
          python3-netaddr"

echo ""
echo ""
echo "Updated Environment Variables ..."
echo "SDE_INSTALL: $SDE_INSTALL"
echo "LIBRARY_PATH: $LIBRARY_PATH"
echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
echo "PATH: $PATH"
echo ""

sudo apt-get update
sudo apt-get install -y --no-install-recommends  ${P4C_DEPS}
${PIP_SUDO} pip3 install --upgrade pip
${PIP_SUDO} pip3 install -r ${P4C_DIR}/requirements.txt
${PIP_SUDO} pip3 install git+https://github.com/p4lang/p4runtime-shell.git
pip3 list > "${INSTALL_DIR}/pip-list-3-after-p4c-requirements.txt"

# Build P4C
CMAKE_FLAGS="-DCMAKE_UNITY_BUILD=ON"
CMAKE_FLAGS+="
  -DENABLE_BMV2=OFF \
  -DENABLE_EBPF=OFF \
  -DENABLE_UBPF=OFF \
  -DENABLE_GTESTS=OFF \
  -DENABLE_P4TEST=OFF \
  -DENABLE_P4TC=OFF \
  -DENABLE_P4C_GRAPHS=OFF \
  -DENABLE_PROTOBUF_STATIC=OFF \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
  -DENABLE_TEST_TOOLS=ON \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo
"

mkdir build
cd build
cmake .. ${CMAKE_FLAGS}
make -j${MAX_PARALLEL_JOBS}

# net-tools includes ifconfig command, required for ctest command below to pass
sudo apt-get install -y net-tools

# + Run DPDK PTF tests
# These steps are needed to run the tests, but not for installing the software.
#sudo "${IPDK_RECIPE}/install/sbin/copy_config_files.sh" "${IPDK_RECIPE}/install" "${SDE_INSTALL}"
#sudo "${IPDK_RECIPE}/install/sbin/set_hugepages.sh"

# I do not know why, but `sudo -E` seems sometimes NOT to pass on the values
# of environment variables like LD_LIBRARY_PATH
#sudo -E ctest --output-on-failure --schedule-random -R dpdk-ptf*
#sudo LD_LIBRARY_PATH=${LD_LIBRARY_PATH} ctest --output-on-failure --schedule-random -R dpdk-ptf*
