# Introduction

The notes in this file _do not yet_ lead to a working IPDK network
native installation.  They are raw notes taken from an attempt to find
such a sequence of steps to install it and then use it successfully,
which are incomplete now, and might never be complete.

If you are interested in steps I have successfully followed to install
and use an IPDK network container build, see
[here](README-install-ipdk-networking-container-ubuntu-20.04-and-test.md).



Try following the Network native install instructions for IPDK here:

+ https://github.com/ipdk-io/ipdk/blob/main/build/networking/README_NATIVE.md

Start with an unmodified Ubuntu 20.04 system.


```bash
sudo bash
cd $HOME
git clone https://github.com/ipdk-io/ipdk.git
mkdir work-dir
```

Without a proxy:

```bash
SCRIPT_DIR=$HOME/ipdk/build/networking/scripts $HOME/ipdk/build/networking/scripts/host_install.sh -d $HOME --workdir=$HOME/work-dir |& tee $HOME/log-install.txt
mkdir -p /usr/share/stratum/certs /var/log/stratum /usr/share/stratum/dpdk
WORKING_DIR=$HOME/work-dir
COMMON_NAME=localhost "${WORKING_DIR}"/scripts/generate_tls_certs.sh --workdir="${WORKING_DIR}"
```

Installation is complete after the above steps.




```bash
export LD_LIBRARY_PATH="/root/work-dir/p4-sde/install/lib/x86_64-linux-gnu:/root/work-dir/p4-sde/install/lib:/root/work-dir/networking-recipe/deps_install/lib:/root/work-dir/networking-recipe/install/lib"
export PATH="/root/work-dir/networking-recipe/install/sbin:/root/work-dir/p4c/install/bin:/root/work-dir/networking-recipe/install/bin:/root/work-dir/p4-sde/install/bin:${PATH}"
```


Start infrap4d:

```bash
pushd /root/work-dir/scripts > /dev/null
. /root/work-dir/scripts/initialize_env.sh \
    --sde-install-dir=/root/work-dir/p4-sde/install \
    --nr-install-dir=/root/work-dir/networking-recipe/install \
    --deps-install-dir=/root/work-dir/networking-recipe/deps_install \
    --p4c-install-dir=/root/work-dir/p4c/install
popd > /dev/null
/root/work-dir/scripts/set_hugepages.sh 10
cp /root/work-dir/networking-recipe/install/share/stratum/dpdk/dpdk_skip_p4.conf /usr/share/stratum/dpdk/dpdk_skip_p4.conf
/root/work-dir/scripts/run_infrap4d.sh --nr-install-dir=/root/work-dir/networking-recipe/install
```


```bash
which infrap4d
which p4c
which p4c-dpdk
which gnmi-ctl
which p4rt-ctl

infrap4d --help
p4c --help
p4c-dpdk --help
gnmi-ctl --help
p4rt-ctl --help
```

```bash
libdir1="/root/work-dir/p4-sde/install/lib/x86_64-linux-gnu"
libdir2="/root/work-dir/p4-sde/install/lib"
libdir3="/root/work-dir/networking-recipe/deps_install/lib"
libdir4="/root/work-dir/networking-recipe/install/lib"
```

Check whether `infrap4d` has all of its necessary shared libs:

```bash
export LD_LIBRARY_PATH="${libdir1}:${libdir2}:${libdir3}:${libdir4}"
/usr/bin/ldd -v /root/work-dir/networking-recipe/install/sbin/infrap4d | grep 'not found'
```

Check whether `p4c-dpdk` has all of its necessary shared libs:

```bash
export LD_LIBRARY_PATH="${libdir3}"
/usr/bin/ldd -v /root/work-dir/p4c/install/bin/p4c-dpdk | grep 'not found'
```

Check whether `p4c` has all of its necessary shared libs:

```bash
export LD_LIBRARY_PATH=""
/usr/bin/ldd -v /root/work-dir/p4c/install/bin/p4c | grep 'not found'
```

Check whether `gnmi-ctl` has all of its necessary shared libs:

```bash
export LD_LIBRARY_PATH="${libdir3}:${libdir4}"
/usr/bin/ldd -v /root/work-dir/networking-recipe/install/bin/gnmi-ctl | grep 'not found'
```

Check whether `p4rt-ctl` has all of its necessary shared libs:

```bash
export LD_LIBRARY_PATH=""
/usr/bin/ldd -v /root/work-dir/networking-recipe/install/bin/p4rt-ctl | grep 'not found'
```
