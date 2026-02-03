#!/usr/bin/env bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

print_step() {
    echo -e "\n${BOLD}${BLUE}==>${NC} ${BOLD}$1${NC}"
}

echo -e "${BOLD}${BLUE}=== P4 DPDK Target Installation Script ===${NC}"

# ------------------------------------------------------------
# 1. Base directories
# ------------------------------------------------------------
export SDE=$(pwd)/sde
export SDE_INSTALL=$SDE/install

mkdir -p "$SDE"

# ------------------------------------------------------------
# 1. Cloning p4-dpdk-target
# ------------------------------------------------------------
print_step "1/5 Cloning p4-dpdk-target..."
cd $SDE
git clone https://github.com/p4lang/p4-dpdk-target.git

# ------------------------------------------------------------
# 2. System dependencies
# ------------------------------------------------------------
print_step "2/5 Installing system dependencies..."

cd p4-dpdk-target/tools/setup
source p4sde_env_setup.sh $SDE
pip3 install distro
python3 install_dep.py

# ------------------------------------------------------------
# 3. Build p4-dpdk-target
# ------------------------------------------------------------
print_step "3/5 Building p4-dpdk-target..."

cd $SDE/p4-dpdk-target
git submodule update --init --recursive --force
./autogen.sh
read -p "Build for TDI only? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ./configure --prefix=$SDE_INSTALL --with-generic-flags=yes #For TDI build
else
    ./configure --prefix=$SDE_INSTALL #For both bfrt and TDI build
fi
make -j
make install

# ------------------------------------------------------------
# 4. Hugepages (required for DPDK)
# ------------------------------------------------------------
print_step "4/5 Configuring hugepages..."
read -p "Configure hugepages? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo sysctl -w vm.nr_hugepages=1024 || true
    sudo mkdir -p /mnt/huge || true
    mount | grep hugetlbfs || sudo mount -t hugetlbfs nodev /mnt/huge || true
else
    echo "Skipping hugepages configuration."
fi

# ------------------------------------------------------------
# 5. Hugepages permissions
# ------------------------------------------------------------
print_step "5/5 Configuring hugepages permissions..."
read -p "Configure hugepages permissions? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo chown $(id -u):$(id -g) /dev/hugepages
    sudo chmod 700 /dev/hugepages
else
    echo "Skipping hugepages permissions configuration."
fi

echo -e "${BOLD}${GREEN}DONE ✔${NC}"
