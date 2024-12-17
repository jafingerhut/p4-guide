# On x86_64 Ubuntu 20.04.6 system, with no build-essential package installed.
# Note that having at least 4 GBytes of RAM per CPU core,
# i.e. the output of the `nproc` command, is probably close
# to the minimum amount of RAM you should have for parts of the build to succeed.

# This is required for the steps below, but not installed by any later commands.
sudo apt-get install ccache

git clone git@github.com:p4lang/open-p4studio
cd open-p4studio
git checkout fruffy/runners

git log -n 1 | head -n 3
#commit 41eb35b9a50add74abec5fea763a739844da89b0
#Author: fruffy <fruffy@nyu.edu>
#Date:   Mon Dec 16 16:06:06 2024 +0100

git submodule update --init --recursive

sudo -E ./p4studio/p4studio profile apply ./p4studio/profiles/all-tofino.yaml |& tee log.txt

# Success!

# Run some tests
export SDE=`pwd`
export SDE_INSTALL="`pwd`/install"
export LD_LIBRARY_PATH=$SDE_INSTALL/lib
export PATH=$SDE_INSTALL/bin:$PATH

#sudo -E ENABLE_BF_ASM=TRUE make -C build tna_counter install |& tee out1.txt
sudo -E ENABLE_BF_ASM=TRUE PATH=$PATH LD_LBIRARY_PATH=$LD_LIBRARY_PATH make -C build tna_counter install |& tee out1.txt

sudo ${SDE_INSTALL}/bin/veth_setup.sh 128 |& tee out2.txt
sudo -E ./run_tofino_model.sh -p tna_counter --arch tofino -q |& sed 's/^/model: /' |& tee out3.txt
sudo -E ./run_switchd.sh -p tna_counter --arch tofino |& sed 's/^/switchd: /' |& tee out4.txt
sudo -E timeout 10800 ./run_p4_tests.sh -p tna_counter --arch tofino |& sed 's/^/tests: /' |& tee out5.txt
