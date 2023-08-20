#! /bin/bash

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

# + Checkout DPDK-target
cd "${INSTALL_DIR}"
git clone https://github.com/p4lang/p4-dpdk-target p4sde
cd p4sde
git log -n 1
git submodule update --init --recursive

# + Checkout ipdk-recipe
cd "${INSTALL_DIR}"
git clone https://github.com/ipdk-io/networking-recipe ipdk.recipe
cd ipdk.recipe
git log -n 1
git submodule update --init --recursive

# + checkout P4C
cd "${INSTALL_DIR}"
git clone https://github.com/p4lang/p4c
cd p4c
git log -n 1
git submodule update --init --recursive

# TODO: Review these env variable settings to see if they work properly
export SDE="${INSTALL_DIR}"
export SDE_INSTALL="${INSTALL_DIR}/sde_install"
export P4C_DIR="${INSTALL_DIR}/p4c"
export IPDK_RECIPE="${INSTALL_DIR}/ipdk.recipe"
export DEPEND_INSTALL="/usr/local"

# + Install DPDK dependencies
cd "${INSTALL_DIR}"
cd p4sde/tools/setup
sudo apt update -y
# TODO: Does this need sudo?  Does it install Python packages in system-wide directories or a venv?
python3 install_dep.py

# + Compile p4sde dpdk target
cd "${INSTALL_DIR}"
# TODO: What should value of GITHUB_WORKSPACE be?
mkdir ${GITHUB_WORKSPACE}/install
./autogen.sh
./configure "--prefix=${SDE_INSTALL}"
make 
make install

# + Build infrap4d dependencies
cd "${INSTALL_DIR}"
cd ipdk.recipe
echo "Install infrap4d dependencies"
sudo apt-get install -y libatomic1 libnl-route-3-dev openssl
pip3 install -r requirements.txt
cd "${IPDK_RECIPE}/setup"
echo "Build infrap4d dependencies"
cmake -B build -DCMAKE_INSTALL_PREFIX="$DEPEND_INSTALL" -DUSE_SUDO=ON
cmake --build build 

# + Build infrap4d
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
pip3 install --upgrade pip
pip3 install -r ${P4C_DIR}/requirements.txt
pip3 install git+https://github.com/p4lang/p4runtime-shell.git

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

# + Run DPDK PTF tests
# These steps are needed to run the tests, but not for installing the software.
#sudo "${IPDK_RECIPE}/install/sbin/copy_config_files.sh" "${IPDK_RECIPE}/install" "${SDE_INSTALL}"
#sudo "${IPDK_RECIPE}/install/sbin/set_hugepages.sh"
#sudo -E ctest --output-on-failure --schedule-random -R dpdk-ptf*
